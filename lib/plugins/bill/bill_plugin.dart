import 'dart:convert';
import 'package:get/get.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/widgets/custom_bottom_bar.dart';
import 'package:flutter/gestures.dart';
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
  const BillMainView({super.key});
  @override
  State<BillMainView> createState() => _BillMainViewState();
}

class _BillMainViewState extends State<BillMainView>
    with SingleTickerProviderStateMixin {
  final BillPlugin billPlugin = PluginManager().getPlugin('bill') as BillPlugin;
  late TabController _tabController;
  late int _currentPage;
  final List<Color> _colors = [
    Colors.green,
    Colors.blue,
  ];
  final GlobalKey _bottomBarKey = GlobalKey(debugLabel: 'bill_bottom_bar');

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    _tabController = TabController(length: 2, vsync: this);
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
            startDate: DateTime.now().subtract(
              const Duration(days: 30),
            ), // 默认显示最近30天
            endDate: DateTime.now(),
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
