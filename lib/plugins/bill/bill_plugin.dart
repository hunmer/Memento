import 'dart:convert';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/plugins/bill/l10n/bill_localizations.dart';
import 'package:flutter/material.dart';
import '../../core/plugin_base.dart';
import '../../core/plugin_manager.dart';
import 'controls/bill_controller.dart';
import 'controls/prompt_controller.dart';
import 'screens/bill_list_screen.dart';
import 'screens/bill_stats_screen.dart';
import 'screens/account_list_screen.dart';
import 'models/account.dart';
import 'models/bill.dart';
import 'models/bill_statistics.dart';
import 'models/statistic_range.dart';

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
  late final PromptController _promptController;

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
    _billController.initialize();

    // 初始化 Prompt 控制器
    _promptController = PromptController(this);
    _promptController.initialize();

    // 注册 JS API（最后一步）
    await registerJSAPI();
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 初始化插件
    await initialize();
  }

  @override
  String? getPluginName(context) {
    return BillLocalizations.of(context).name;
  }

  Future<void> uninstall() async {
    _promptController.unregisterPromptMethods();
    _promptController.dispose();
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
                BillLocalizations.of(context).name,
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
                        BillLocalizations.of(context).todayFinance,
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
                        BillLocalizations.of(context).monthFinance,
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
                        BillLocalizations.of(context).monthBills,
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
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取所有账户(不包含账单数据)
  Future<String> _jsGetAccounts(Map<String, dynamic> params) async {
    final accounts = _billController.accounts;
    // 只返回账户基本信息,移除 bills 字段
    final accountsJson = accounts.map((a) {
      final json = a.toJson();
      json.remove('bills');
      return json;
    }).toList();
    return jsonEncode(accountsJson);
  }

  /// 创建账户
  /// @param params.title 账户名称 (必需)
  /// @param params.id 账户ID (可选，不传则自动生成 UUID)
  /// @param params.iconCodePoint 图标代码点 (可选，默认 Icons.account_balance_wallet)
  /// @param params.backgroundColor 背景颜色值 (可选，默认绿色)
  Future<String> _jsCreateAccount(Map<String, dynamic> params) async {
    final String? title = params['title'];
    if (title == null || title.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: title'});
    }

    final String? id = params['id'];
    final int? iconCodePoint = params['iconCodePoint'];
    final int? backgroundColor = params['backgroundColor'];

    final account = Account(
      id: id,
      title: title,
      icon: iconCodePoint != null
          ? IconData(iconCodePoint, fontFamily: 'MaterialIcons')
          : Icons.account_balance_wallet,
      backgroundColor:
          backgroundColor != null ? Color(backgroundColor) : Colors.green,
    );

    await _billController.createAccount(account);
    return jsonEncode(account.toJson());
  }

  /// 更新账户
  /// @param params.accountId 账户ID (必需)
  /// @param params.title 新账户名称 (可选)
  /// @param params.iconCodePoint 新图标代码点 (可选)
  /// @param params.backgroundColor 新背景颜色值 (可选)
  Future<String> _jsUpdateAccount(Map<String, dynamic> params) async {
    final String? accountId = params['accountId'];
    if (accountId == null || accountId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: accountId'});
    }

    final account = _billController.accounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () => throw '账户不存在',
    );

    final String? title = params['title'];
    final int? iconCodePoint = params['iconCodePoint'];
    final int? backgroundColor = params['backgroundColor'];

    final updatedAccount = account.copyWith(
      title: title,
      icon:
          iconCodePoint != null
              ? IconData(iconCodePoint, fontFamily: 'MaterialIcons')
              : null,
      backgroundColor: backgroundColor != null ? Color(backgroundColor) : null,
    );

    await _billController.saveAccount(updatedAccount);
    return jsonEncode(updatedAccount.toJson());
  }

  /// 删除账户
  /// @param params.accountId 账户ID (必需)
  Future<String> _jsDeleteAccount(Map<String, dynamic> params) async {
    try {
      final String? accountId = params['accountId'];
      if (accountId == null || accountId.isEmpty) {
        return jsonEncode({'success': false, 'error': '缺少必需参数: accountId'});
      }

      await _billController.deleteAccount(accountId);
      return jsonEncode({'success': true, 'accountId': accountId});
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// 获取账单列表
  /// @param params.accountId 账户ID (可选，不传则返回所有账户的账单)
  /// @param params.startDate 开始日期 (可选，格式: YYYY-MM-DD)
  /// @param params.endDate 结束日期 (可选，格式: YYYY-MM-DD)
  Future<String> _jsGetBills(Map<String, dynamic> params) async {
    final String? accountId = params['accountId'];
    final String? startDate = params['startDate'];
    final String? endDate = params['endDate'];

    // 解析日期参数
    DateTime? start;
    DateTime? end;

    if (startDate != null && startDate.isNotEmpty) {
      try {
        start = DateTime.parse(startDate);
      } catch (e) {
        throw '日期格式错误: $startDate，应为 YYYY-MM-DD 格式';
      }
    }

    if (endDate != null && endDate.isNotEmpty) {
      try {
        end = DateTime.parse(endDate);
      } catch (e) {
        throw '日期格式错误: $endDate，应为 YYYY-MM-DD 格式';
      }
    }

    // 获取账单列表
    final bills = await _billController.getBills(
      startDate: start,
      endDate: end,
    );

    // 如果指定了 accountId，只返回该账户的账单
    final filteredBills =
        accountId != null && accountId.isNotEmpty
            ? bills.where((b) => b.accountId == accountId).toList()
            : bills;

    return jsonEncode(filteredBills.map((b) => b.toJson()).toList());
  }

  /// 创建账单
  /// @param params.accountId 账户ID (必需)
  /// @param params.amount 金额 (必需，正数=收入，负数=支出)
  /// @param params.category 分类 (必需)
  /// @param params.title 标题 (必需)
  /// @param params.date 日期 (可选，格式: YYYY-MM-DD，默认今天)
  /// @param params.note 备注 (可选，默认空字符串)
  /// @param params.tag 标签 (可选)
  Future<String> _jsCreateBill(Map<String, dynamic> params) async {
    final String? accountId = params['accountId'];
    if (accountId == null || accountId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: accountId'});
    }

    final double? amount = (params['amount'] as num?)?.toDouble();
    if (amount == null) {
      return jsonEncode({'error': '缺少必需参数: amount'});
    }

    final String? category = params['category'];
    if (category == null || category.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: category'});
    }

    final String? title = params['title'];
    if (title == null || title.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: title'});
    }

    final String? date = params['date'];
    final String? note = params['note'];
    final String? tag = params['tag'];

    // 解析日期
    DateTime billDate;
    if (date != null && date.isNotEmpty) {
      try {
        billDate = DateTime.parse(date);
      } catch (e) {
        throw '日期格式错误: $date，应为 YYYY-MM-DD 格式';
      }
    } else {
      billDate = DateTime.now();
    }

    // 创建账单
    final bill = Bill(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      category: category,
      date: billDate,
      accountId: accountId,
      note: note ?? '',
      tag: tag,
      icon: amount >= 0 ? Icons.arrow_downward : Icons.arrow_upward,
      iconColor: amount >= 0 ? Colors.green : Colors.red,
    );

    await _billController.saveBill(bill);
    return jsonEncode(bill.toJson());
  }

  /// 更新账单
  /// @param params.billId 账单ID (必需)
  /// @param params.accountId 账户ID (必需)
  /// @param params.amount 新金额 (可选)
  /// @param params.category 新分类 (可选)
  /// @param params.title 新标题 (可选)
  /// @param params.date 新日期 (可选，格式: YYYY-MM-DD)
  /// @param params.note 新备注 (可选)
  /// @param params.tag 新标签 (可选)
  Future<String> _jsUpdateBill(Map<String, dynamic> params) async {
    final String? billId = params['billId'];
    if (billId == null || billId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: billId'});
    }

    final String? accountId = params['accountId'];
    if (accountId == null || accountId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: accountId'});
    }

    // 查找账户
    final account = _billController.accounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () => throw '账户不存在',
    );

    // 查找账单
    final bill = account.bills.firstWhere(
      (b) => b.id == billId,
      orElse: () => throw '账单不存在',
    );

    final double? amount = (params['amount'] as num?)?.toDouble();
    final String? category = params['category'];
    final String? title = params['title'];
    final String? date = params['date'];
    final String? note = params['note'];
    final String? tag = params['tag'];

    // 解析日期
    DateTime? billDate;
    if (date != null && date.isNotEmpty) {
      try {
        billDate = DateTime.parse(date);
      } catch (e) {
        throw '日期格式错误: $date，应为 YYYY-MM-DD 格式';
      }
    }

    // 更新账单
    final updatedBill = bill.copyWith(
      amount: amount,
      category: category,
      title: title,
      date: billDate,
      note: note,
      tag: tag,
      updatedAt: DateTime.now(),
    );

    await _billController.saveBill(updatedBill);
    return jsonEncode(updatedBill.toJson());
  }

  /// 删除账单
  /// @param params.accountId 账户ID (必需)
  /// @param params.billId 账单ID (必需)
  Future<String> _jsDeleteBill(Map<String, dynamic> params) async {
    try {
      final String? accountId = params['accountId'];
      if (accountId == null || accountId.isEmpty) {
        return jsonEncode({'success': false, 'error': '缺少必需参数: accountId'});
      }

      final String? billId = params['billId'];
      if (billId == null || billId.isEmpty) {
        return jsonEncode({'success': false, 'error': '缺少必需参数: billId'});
      }

      await _billController.deleteBill(accountId, billId);
      return jsonEncode({'success': true, 'accountId': accountId, 'billId': billId});
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// 获取统计信息
  /// @param params.startDate 开始日期 (可选，格式: YYYY-MM-DD)
  /// @param params.endDate 结束日期 (可选，格式: YYYY-MM-DD)
  /// @param params.accountId 账户ID (可选，不传则统计所有账户)
  Future<String> _jsGetStats(Map<String, dynamic> params) async {
    final String? startDate = params['startDate'];
    final String? endDate = params['endDate'];
    final String? accountId = params['accountId'];

    // 解析日期参数
    DateTime? start;
    DateTime? end;

    if (startDate != null && startDate.isNotEmpty) {
      try {
        start = DateTime.parse(startDate);
      } catch (e) {
        throw '日期格式错误: $startDate，应为 YYYY-MM-DD 格式';
      }
    }

    if (endDate != null && endDate.isNotEmpty) {
      try {
        end = DateTime.parse(endDate);
      } catch (e) {
        throw '日期格式错误: $endDate，应为 YYYY-MM-DD 格式';
      }
    }

    // 获取账单列表
    final bills = await _billController.getBills(
      startDate: start,
      endDate: end,
    );

    // 如果指定了 accountId，只统计该账户的账单
    final filteredBills =
        accountId != null && accountId.isNotEmpty
            ? bills.where((b) => b.accountId == accountId).toList()
            : bills;

    // 计算统计信息
    final totalIncome = await _billController.getTotalIncome(
      startDate: start,
      endDate: end,
    );
    final totalExpense = await _billController.getTotalExpense(
      startDate: start,
      endDate: end,
    );

    return jsonEncode({
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'balance': totalIncome - totalExpense,
      'billCount': filteredBills.length,
      'todayFinance': _billController.getTodayFinance(),
      'monthFinance': _billController.getMonthFinance(),
      'monthBillCount': _billController.getMonthBillCount(),
    });
  }

  /// 获取分类统计
  /// @param params.startDate 开始日期 (可选，格式: YYYY-MM-DD)
  /// @param params.endDate 结束日期 (可选，格式: YYYY-MM-DD)
  /// @param params.accountId 账户ID (可选，不传则统计所有账户)
  Future<String> _jsGetCategoryStats(Map<String, dynamic> params) async {
    final String? startDate = params['startDate'];
    final String? endDate = params['endDate'];
    final String? accountId = params['accountId'];

    // 解析日期参数
    DateTime? start;
    DateTime? end;

    if (startDate != null && startDate.isNotEmpty) {
      try {
        start = DateTime.parse(startDate);
      } catch (e) {
        throw '日期格式错误: $startDate，应为 YYYY-MM-DD 格式';
      }
    }

    if (endDate != null && endDate.isNotEmpty) {
      try {
        end = DateTime.parse(endDate);
      } catch (e) {
        throw '日期格式错误: $endDate，应为 YYYY-MM-DD 格式';
      }
    }

    // 获取分类统计
    final categoryStats = await _billController.getCategoryStatistics(
      startDate: start,
      endDate: end,
    );

    // 如果指定了 accountId，只统计该账户的账单
    if (accountId != null && accountId.isNotEmpty) {
      final bills = await _billController.getBills(
        startDate: start,
        endDate: end,
      );
      final filteredBills = bills.where((b) => b.accountId == accountId);

      final Map<String, double> filteredStats = {};
      for (final bill in filteredBills) {
        filteredStats[bill.category] =
            (filteredStats[bill.category] ?? 0) + bill.amount;
      }
      return jsonEncode(filteredStats);
    }

    return jsonEncode(categoryStats);
  }
}

/// 账单插件主视图
class BillMainView extends StatefulWidget {
  const BillMainView({super.key});
  @override
  State<BillMainView> createState() => _BillMainViewState();
}

class _BillMainViewState extends State<BillMainView> {
  final BillPlugin billPlugin = PluginManager().getPlugin('bill') as BillPlugin;

  @override
  Widget build(BuildContext context) {
    // 如果没有账户，跳转到账户列表页面
    if (billPlugin.accounts.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => AccountListScreen(billPlugin: billPlugin),
          ),
        );
      });
      return const Center(child: CircularProgressIndicator());
    }
    if (billPlugin.selectedAccountId == null &&
        billPlugin.accounts.isNotEmpty) {
      billPlugin.selectedAccount = billPlugin.accounts.first;
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => PluginManager.toHomeScreen(context),
          ),
          title: Text(
            billPlugin.selectedAccount?.title ??
                BillLocalizations.of(context).accountTitle,
          ),
          bottom: const TabBar(tabs: [Tab(text: '账单列表'), Tab(text: '统计分析')]),
          actions: [
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder:
                        (context) => AccountListScreen(billPlugin: billPlugin),
                  ),
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            BillListScreen(
              billPlugin: billPlugin,
              accountId: billPlugin.selectedAccount!.id,
            ),
            BillStatsScreen(
              billPlugin: billPlugin,
              accountId: billPlugin.selectedAccount!.id,
              startDate: DateTime.now().subtract(
                const Duration(days: 30),
              ), // 默认显示最近30天
              endDate: DateTime.now(),
            ),
          ],
        ),
      ),
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
