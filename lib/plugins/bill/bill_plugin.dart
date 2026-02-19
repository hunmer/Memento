import 'dart:convert';
import 'package:get/get.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/widgets/custom_bottom_bar.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:Memento/core/plugin_base.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';

// UseCase 架构相关导入
import 'package:shared_models/usecases/bill/bill_usecase.dart';
import 'repositories/client_bill_repository.dart';

// 控制器与界面
import 'controls/bill_controller.dart';
import 'screens/bill_list_screen_supercupertino.dart';
import 'screens/bill_stats_screen_supercupertino.dart';
import 'screens/account_list_screen.dart';
import 'screens/bill_edit_screen.dart';
import 'models/account.dart';
import 'models/bill.dart';
import 'models/bill_statistics.dart';
import 'models/statistic_range.dart';

part 'bill_js_api.dart';
part 'bill_data_selectors.dart';

class BillPlugin extends PluginBase with ChangeNotifier, JSBridgePlugin {
  static BillPlugin? _instance;
  static BillPlugin get instance {
    if (_instance == null) {
      _instance = PluginManager.instance.getPlugin('bill') as BillPlugin?;
      if (_instance == null) {
        throw StateError('BillPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  late final BillController _billController;
  late final BillUseCase _billUseCase;

  BillPlugin() {
    _billController = BillController();
  }

  @override
  String get id => 'bill';

  @override
  IconData get icon => Icons.account_balance_wallet;

  @override
  Color get color => Colors.green;

  Account? get selectedAccount => _billController.selectedAccount;
  set selectedAccount(Account? account) =>
      _billController.selectedAccount = account;
  String? get selectedAccountId => _billController.selectedAccountId;
  List<Account> get accounts => _billController.accounts;

  // 暴露账单控制器
  BillController get controller => _billController;

  @override
  Future<void> initialize() async {
    _billController.setPlugin(this);
    await _billController.initialize();

    // 初始化 UseCase
    final repository = ClientBillRepository(
      billController: _billController,
      pluginColor: color,
    );
    _billUseCase = BillUseCase(repository);

    // 监听 BillController 的变化并传播给 BillPlugin 的监听器
    _billController.addListener(() {
      notifyListeners();
    });

    // 注册 JS API（最后一步）
    await registerJSAPI();

    // 注册数据选择器
    _registerDataSelectors();
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 插件已在 initialize() 中完成初始化
    // 这里可以添加额外的应用级注册逻辑
  }

  @override
  String? getPluginName(context) {
    return 'bill_name'.tr;
  }

  @override
  Widget buildMainView(BuildContext context) {
    return BillMainView();
  }

  @override
  Widget? buildCardView(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部图标和标题
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                'bill_name'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 统计信息卡片
          Column(
            children: [
              // 第一行 - 今日财务和本月财务
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 今日财务
                  Column(
                    children: [
                      Text(
                        'bill_todayFinance'.tr,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '¥${_billController.getTodayFinance().toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              _billController.getTodayFinance() >= 0
                                  ? Colors.green
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),

                  // 本月财务
                  Column(
                    children: [
                      Text(
                        'bill_monthFinance'.tr,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '¥${_billController.getMonthFinance().toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              _billController.getMonthFinance() >= 0
                                  ? Colors.green
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 第二行 - 本月记账
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        'bill_monthBills'.tr,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        _billController.getMonthBillCount().toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _settings = {};

  @override
  Map<String, dynamic> get settings => _settings;

  @override
  Future<void> loadSettings(Map<String, dynamic> defaultSettings) async {
    try {
      final storedSettings = await storage.read(
        ConfigManager.getPluginConfigPath(id),
      );
      if (storedSettings.isNotEmpty) {
        _settings = Map<String, dynamic>.from(storedSettings);
      } else {
        _settings = Map<String, dynamic>.from(defaultSettings);
        await saveSettings();
      }
    } catch (e) {
      _settings = Map<String, dynamic>.from(defaultSettings);
      try {
        await saveSettings();
      } catch (e) {
        debugPrint('Warning: Failed to save plugin settings: $e');
      }
    }
  }

  @override
  Future<void> saveSettings() async {
    try {
      await storage.write(ConfigManager.getPluginConfigPath(id), _settings);
    } catch (e) {
      debugPrint('Warning: Failed to save plugin settings: $e');
    }
  }

  @override
  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    _settings.addAll(newSettings);
    await saveSettings();
  }

  // ==================== JS API 定义 ====================

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 账户相关
      'getAccounts': _jsGetAccounts,
      'createAccount': _jsCreateAccount,
      'updateAccount': _jsUpdateAccount,
      'deleteAccount': _jsDeleteAccount,

      // 账单相关
      'getBills': _jsGetBills,
      'createBill': _jsCreateBill,
      'updateBill': _jsUpdateBill,
      'deleteBill': _jsDeleteBill,

      // 统计相关
      'getStats': _jsGetStats,
      'getCategoryStats': _jsGetCategoryStats,

      // 账户查找方法
      'findAccountBy': _jsFindAccountBy,
      'findAccountById': _jsFindAccountById,
      'findAccountByName': _jsFindAccountByName,

      // 账单查找方法
      'findBillBy': _jsFindBillBy,
      'findBillById': _jsFindBillById,
      'findBillByTitle': _jsFindBillByTitle,
      'findBillsByCategory': _jsFindBillsByCategory,
    };
  }

  // ==================== 数据选择器注册 ====================
  /// 注册数据选择器（实现在 bill_data_selectors.dart 中）
  // 这个方法的实现在 bill_data_selectors.dart part 文件中
}

/// 账单插件主视图
class BillMainView extends StatefulWidget {
  const BillMainView({
    super.key,
    this.showBillListTab = false,
    this.showStatsTab = false,
    this.selectedMonth,
    this.statsType,
    this.statsStartDate,
    this.statsEndDate,
  });

  /// 是否显示账单列表标签页
  final bool showBillListTab;

  /// 是否显示统计标签页
  final bool showStatsTab;

  /// 选中的月份（yyyy-MM）
  final String? selectedMonth;

  /// 统计类型（income/expense/balance）
  final String? statsType;

  /// 统计开始日期
  final String? statsStartDate;

  /// 统计结束日期
  final String? statsEndDate;

  @override
  State<BillMainView> createState() => _BillMainViewState();
}

class _BillMainViewState extends State<BillMainView>
    with SingleTickerProviderStateMixin {
  final BillPlugin billPlugin = PluginManager().getPlugin('bill') as BillPlugin;
  late TabController _tabController;
  late int _currentPage;

  DateTime? _statsStartDate;
  DateTime? _statsEndDate;
  final List<Color> _colors = [
    Colors.green,
    Colors.blue,
  ];
  final GlobalKey _bottomBarKey = GlobalKey(debugLabel: 'bill_bottom_bar');

  @override
  void initState() {
    super.initState();
    // 根据参数设置初始标签页
    _currentPage = 0;
    if (widget.showStatsTab) {
      _currentPage = 1;
    } else if (widget.showBillListTab) {
      _currentPage = 0;
    }
    _tabController = TabController(length: 2, vsync: this);

    // 延迟跳转到指定标签页
    if (_currentPage != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tabController.animateTo(_currentPage);
        }
      });
    }

    // 解析统计日期范围
    if (widget.statsStartDate != null) {
      try {
        _statsStartDate = DateTime.parse(widget.statsStartDate!);
      } catch (e) {
        debugPrint('[BillMainView] 解析 statsStartDate 失败: $e');
      }
    }
    if (widget.statsEndDate != null) {
      try {
        _statsEndDate = DateTime.parse(widget.statsEndDate!);
      } catch (e) {
        debugPrint('[BillMainView] 解析 statsEndDate 失败: $e');
      }
    }
    _tabController.animation?.addListener(() {
      final value = _tabController.animation!.value.round();
      if (value != _currentPage && mounted) {
        setState(() {
          _currentPage = value;
        });
      }
    });

    // 延迟检查账户状态，确保在初始化完成后再进行导航
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAccountStatus();
    });
  }

  void _checkAccountStatus() {
    if (billPlugin.accounts.isEmpty) {
      NavigationHelper.pushReplacement(
        context,
        AccountListScreen(billPlugin: billPlugin),
      );
    } else if (billPlugin.selectedAccountId == null) {
      setState(() {
        billPlugin.selectedAccount = billPlugin.accounts.first;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 构建 FAB
  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: () {
        NavigationHelper.openContainerWithHero(
          context,
          (context) => BillEditScreen(
            billPlugin: billPlugin,
            accountId: billPlugin.selectedAccount?.id ?? '',
          ),
        );
      },
      backgroundColor: const Color(0xFF3498DB),
      elevation: 4,
      shape: const CircleBorder(),
      child: Icon(
        Icons.add,
        color: const Color(0xFF3498DB).computeLuminance() > 0.5
            ? Colors.black
            : Colors.white,
        size: 32,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 如果没有账户，显示加载指示器
    if (billPlugin.accounts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomBottomBar(
      colors: _colors,
      currentIndex: _currentPage,
      tabController: _tabController,
      bottomBarKey: _bottomBarKey,
      body: (context, controller) => TabBarView(
        controller: _tabController,
        dragStartBehavior: DragStartBehavior.down,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          BillListScreenSupercupertino(
            billPlugin: billPlugin,
            accountId: billPlugin.selectedAccount?.id ?? '',
          ),
          BillStatsScreenSupercupertino(
            billPlugin: billPlugin,
            accountId: billPlugin.selectedAccount?.id ?? '',
            // 使用路由参数中的日期范围，如果不存在则使用默认值
            startDate: _statsStartDate ?? DateTime.now().subtract(
              const Duration(days: 30),
            ),
            endDate: _statsEndDate ?? DateTime.now(),
          ),
        ],
      ),
      fab: _buildFab(),
      children: const [
        Tab(icon: Icon(Icons.receipt_long), text: '账单列表'),
        Tab(icon: Icon(Icons.bar_chart), text: '统计分析'),
      ],
    );
  }

  // 委托方法到BillController
  Future<void> createAccount(Account account) async {
    await billPlugin.controller.createAccount(account);
    setState(() {}); // 更新UI
  }

  // 修改saveAccount方法，在保存账户后通知监听器
  Future<void> saveAccount(Account account) async {
    await billPlugin.controller.saveAccount(account);
    setState(() {}); // 更新UI
  }

  Future<void> deleteAccount(String accountId) =>
      billPlugin.controller.deleteAccount(accountId);
  Future<void> deleteBill(String accountId, String billId) =>
      billPlugin.controller.deleteBill(accountId, billId);
  BillStatistics getStatistics({
    required List<Bill> bills,
    required StatisticRange range,
    DateTime? startDate,
    DateTime? endDate,
  }) => billPlugin.controller.getStatistics(
    bills: bills,
    range: range,
    startDate: startDate,
    endDate: endDate,
  );
}

// ==================== 小组件配置表单 ====================

/// 支出统计配置表单
class _BillStatsConfigForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onComplete;

  const _BillStatsConfigForm({required this.onComplete});

  @override
  State<_BillStatsConfigForm> createState() => _BillStatsConfigFormState();
}

class _BillStatsConfigFormState extends State<_BillStatsConfigForm> {
  // 统计类型
  String _selectedType = 'expense';

  // 日期范围
  String _selectedPeriod = '本月';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  // 目标金额
  double _targetAmount = 5000.0;

  final List<String> _periods = ['本周', '本月', '本年', '自定义'];

  @override
  void initState() {
    super.initState();
    _updateDateRange(_selectedPeriod);
  }

  void _updateDateRange(String period) {
    final now = DateTime.now();
    switch (period) {
      case '本周':
        final weekday = now.weekday;
        _startDate = now.subtract(Duration(days: weekday - 1));
        _endDate = _startDate.add(const Duration(days: 6));
        break;
      case '本月':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case '本年':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31);
        break;
      case '自定义':
        break;
    }
    _endDate = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = '自定义';
      });
    }
  }

  void _confirm() {
    widget.onComplete({
      'type': _selectedType,
      'startDate': _startDate.toIso8601String(),
      'endDate': _endDate.toIso8601String(),
      'targetAmount': _targetAmount,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.pie_chart, color: BillPlugin.instance.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '支出统计配置',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    '统计类型',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'income',
                        label: Text('收入'.tr),
                        icon: const Icon(Icons.arrow_downward),
                      ),
                      ButtonSegment(
                        value: 'expense',
                        label: Text('支出'.tr),
                        icon: const Icon(Icons.arrow_upward),
                      ),
                      ButtonSegment(
                        value: 'balance',
                        label: Text('结余'.tr),
                        icon: const Icon(Icons.account_balance),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (value) {
                      setState(() => _selectedType = value.first);
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '时间范围',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _periods.map((period) {
                      final isSelected = _selectedPeriod == period;
                      return ChoiceChip(
                        label: Text(period),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedPeriod = period;
                            _updateDateRange(period);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectDateRange,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.date_range, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            '${DateFormat('yyyy-MM-dd').format(_startDate)} ~ ${DateFormat('yyyy-MM-dd').format(_endDate)}',
                          ),
                          const Spacer(),
                          if (_selectedPeriod == '自定义')
                            Icon(Icons.edit, size: 16, color: theme.colorScheme.outline),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '目标金额',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _targetAmount,
                          min: 1000,
                          max: 50000,
                          divisions: 49,
                          label: '¥${_targetAmount.toStringAsFixed(0)}',
                          onChanged: (value) {
                            setState(() => _targetAmount = value);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          '¥${_targetAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('cancel'.tr),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirm,
                      child: Text('confirm'.tr),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 月份账单配置表单
class _MonthlyBillConfigForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onComplete;

  const _MonthlyBillConfigForm({required this.onComplete});

  @override
  State<_MonthlyBillConfigForm> createState() => _MonthlyBillConfigFormState();
}

class _MonthlyBillConfigFormState extends State<_MonthlyBillConfigForm> {
  DateTime _selectedMonth = DateTime.now();

  List<DateTime> get _monthOptions {
    final now = DateTime.now();
    return List.generate(
      12,
      (index) => DateTime(now.year, now.month - index, 1),
    );
  }

  String _formatMonth(DateTime month) {
    return DateFormat('yyyy年MM月').format(month);
  }

  void _confirm() {
    widget.onComplete({
      'month': DateFormat('yyyy-MM').format(_selectedMonth),
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.calendar_month, color: BillPlugin.instance.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '月份账单配置',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    '选择月份',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: _monthOptions.map((month) {
                        final isSelected =
                            month.year == _selectedMonth.year &&
                            month.month == _selectedMonth.month;
                        return ListTile(
                          title: Text(_formatMonth(month)),
                          trailing: isSelected
                              ? Icon(Icons.check, color: BillPlugin.instance.color)
                              : null,
                          selected: isSelected,
                          selectedTileColor: BillPlugin.instance.color.withOpacity(0.1),
                          onTap: () {
                            setState(() => _selectedMonth = month);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('本月'),
                        onPressed: () {
                          setState(() => _selectedMonth = DateTime.now());
                        },
                      ),
                      ActionChip(
                        label: const Text('上月'),
                        onPressed: () {
                          final now = DateTime.now();
                          setState(() {
                            _selectedMonth = DateTime(now.year, now.month - 1, 1);
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('cancel'.tr),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirm,
                      child: Text('confirm'.tr),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
