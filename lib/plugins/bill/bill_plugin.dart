import 'dart:convert';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/plugins/bill/l10n/bill_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter/gestures.dart';
import '../../core/plugin_base.dart';
import '../../core/plugin_manager.dart';
import 'controls/bill_controller.dart';
import 'screens/bill_list_screen.dart';
import 'screens/bill_stats_screen.dart';
import 'screens/account_list_screen.dart';
import 'screens/bill_edit_screen.dart';
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

  // ==================== 分页控制器 ====================

  /// 分页控制器 - 对列表进行分页处理
  /// @param list 原始数据列表
  /// @param offset 起始位置（默认 0）
  /// @param count 返回数量（默认 100）
  /// @return 分页后的数据，包含 data、total、offset、count、hasMore
  Map<String, dynamic> _paginate<T>(
    List<T> list, {
    int offset = 0,
    int count = 100,
  }) {
    final total = list.length;
    final start = offset.clamp(0, total);
    final end = (start + count).clamp(start, total);
    final data = list.sublist(start, end);

    return {
      'data': data,
      'total': total,
      'offset': start,
      'count': data.length,
      'hasMore': end < total,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取所有账户(不包含账单数据)
  /// 支持分页参数: offset, count
  Future<String> _jsGetAccounts(Map<String, dynamic> params) async {
    final accounts = _billController.accounts;
    // 只返回账户基本信息,移除 bills 字段
    final accountsJson = accounts.map((a) {
      final json = a.toJson();
      json.remove('bills');
      return json;
    }).toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        accountsJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    // 兼容旧版本：无分页参数时返回全部数据
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
  /// @param params.offset 分页起始位置 (可选，默认 0)
  /// @param params.count 返回数量 (可选，默认 100)
  Future<String> _jsGetBills(Map<String, dynamic> params) async {
    final String? accountId = params['accountId'];
    final String? startDate = params['startDate'];
    final String? endDate = params['endDate'];
    final int? offset = params['offset'];
    final int? count = params['count'];

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

    final billsJson = filteredBills.map((b) => b.toJson()).toList();

    // 检查是否需要分页
    if (offset != null || count != null) {
      final paginated = _paginate(
        billsJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    // 兼容旧版本：无分页参数时返回全部数据
    return jsonEncode(billsJson);
  }

  /// 创建账单
  /// @param params.accountId 账户ID (可选，不传则使用第一个账户)
  /// @param params.amount 金额 (必需，正数=收入，负数=支出)
  /// @param params.category 分类 (必需)
  /// @param params.title 标题 (必需)
  /// @param params.date 日期 (可选，格式: YYYY-MM-DD，默认今天)
  /// @param params.note 备注 (可选，默认空字符串)
  /// @param params.tag 标签 (可选)
  Future<String> _jsCreateBill(Map<String, dynamic> params) async {
    String? accountId = params['accountId'];

    // 如果没有提供 accountId，使用第一个账户
    if (accountId == null || accountId.isEmpty) {
      final accounts = _billController.accounts;
      if (accounts.isEmpty) {
        return jsonEncode({'error': '没有可用账户，请先创建账户'});
      }
      accountId = accounts.first.id;
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

  // ==================== 账户查找方法 ====================

  /// 通用账户查找
  /// @param params.field 要匹配的字段名 (必需)
  /// @param params.value 要匹配的值 (必需)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  /// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
  /// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
  Future<String> _jsFindAccountBy(Map<String, dynamic> params) async {
    final String? field = params['field'];
    if (field == null || field.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: field'});
    }

    final dynamic value = params['value'];
    if (value == null) {
      return jsonEncode({'error': '缺少必需参数: value'});
    }

    final bool findAll = params['findAll'] ?? false;
    final int? offset = params['offset'];
    final int? count = params['count'];

    final accounts = _billController.accounts;
    final List<Account> matchedAccounts = [];

    for (final account in accounts) {
      final accountJson = account.toJson();
      accountJson.remove('bills'); // 移除 bills 字段

      // 检查字段是否匹配
      if (accountJson.containsKey(field) && accountJson[field] == value) {
        matchedAccounts.add(account);
        if (!findAll) break; // 只找第一个
      }
    }

    if (findAll) {
      final accountsJson = matchedAccounts.map((a) {
        final json = a.toJson();
        json.remove('bills');
        return json;
      }).toList();

      // 检查是否需要分页
      if (offset != null || count != null) {
        final paginated = _paginate(
          accountsJson,
          offset: offset ?? 0,
          count: count ?? 100,
        );
        return jsonEncode(paginated);
      }

      return jsonEncode(accountsJson);
    } else {
      if (matchedAccounts.isEmpty) {
        return jsonEncode(null);
      }
      final json = matchedAccounts.first.toJson();
      json.remove('bills');
      return jsonEncode(json);
    }
  }

  /// 根据ID查找账户
  /// @param params.id 账户ID (必需)
  Future<String> _jsFindAccountById(Map<String, dynamic> params) async {
    final String? id = params['id'];
    if (id == null || id.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: id'});
    }

    final account = _billController.accounts.firstWhere(
      (a) => a.id == id,
      orElse: () => Account(
        id: '',
        title: '',
        icon: Icons.error,
        backgroundColor: Colors.transparent,
      ),
    );

    if (account.id.isEmpty) {
      return jsonEncode(null);
    }

    final json = account.toJson();
    json.remove('bills');
    return jsonEncode(json);
  }

  /// 根据名称查找账户
  /// @param params.name 账户名称 (必需)
  /// @param params.fuzzy 是否模糊匹配 (可选，默认 false)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  /// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
  /// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
  Future<String> _jsFindAccountByName(Map<String, dynamic> params) async {
    final String? name = params['name'];
    if (name == null || name.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: name'});
    }

    final bool fuzzy = params['fuzzy'] ?? false;
    final bool findAll = params['findAll'] ?? false;
    final int? offset = params['offset'];
    final int? count = params['count'];

    final accounts = _billController.accounts;
    final List<Account> matchedAccounts = [];

    for (final account in accounts) {
      bool matches = false;
      if (fuzzy) {
        matches = account.title.contains(name);
      } else {
        matches = account.title == name;
      }

      if (matches) {
        matchedAccounts.add(account);
        if (!findAll) break;
      }
    }

    if (findAll) {
      final accountsJson = matchedAccounts.map((a) {
        final json = a.toJson();
        json.remove('bills');
        return json;
      }).toList();

      // 检查是否需要分页
      if (offset != null || count != null) {
        final paginated = _paginate(
          accountsJson,
          offset: offset ?? 0,
          count: count ?? 100,
        );
        return jsonEncode(paginated);
      }

      return jsonEncode(accountsJson);
    } else {
      if (matchedAccounts.isEmpty) {
        return jsonEncode(null);
      }
      final json = matchedAccounts.first.toJson();
      json.remove('bills');
      return jsonEncode(json);
    }
  }

  // ==================== 账单查找方法 ====================

  /// 通用账单查找
  /// @param params.field 要匹配的字段名 (必需)
  /// @param params.value 要匹配的值 (必需)
  /// @param params.accountId 限定在特定账户内查找 (可选)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  /// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
  /// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
  Future<String> _jsFindBillBy(Map<String, dynamic> params) async {
    final String? field = params['field'];
    if (field == null || field.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: field'});
    }

    final dynamic value = params['value'];
    if (value == null) {
      return jsonEncode({'error': '缺少必需参数: value'});
    }

    final String? accountId = params['accountId'];
    final bool findAll = params['findAll'] ?? false;
    final int? offset = params['offset'];
    final int? count = params['count'];

    // 获取所有账单
    final allBills = await _billController.getBills();
    final List<Bill> matchedBills = [];

    for (final bill in allBills) {
      // 如果指定了 accountId，先过滤账户
      if (accountId != null && accountId.isNotEmpty && bill.accountId != accountId) {
        continue;
      }

      final billJson = bill.toJson();

      // 检查字段是否匹配
      if (billJson.containsKey(field) && billJson[field] == value) {
        matchedBills.add(bill);
        if (!findAll) break;
      }
    }

    if (findAll) {
      final billsJson = matchedBills.map((b) => b.toJson()).toList();

      // 检查是否需要分页
      if (offset != null || count != null) {
        final paginated = _paginate(
          billsJson,
          offset: offset ?? 0,
          count: count ?? 100,
        );
        return jsonEncode(paginated);
      }

      return jsonEncode(billsJson);
    } else {
      if (matchedBills.isEmpty) {
        return jsonEncode(null);
      }
      return jsonEncode(matchedBills.first.toJson());
    }
  }

  /// 根据ID查找账单
  /// @param params.id 账单ID (必需)
  /// @param params.accountId 限定在特定账户内查找 (可选)
  Future<String> _jsFindBillById(Map<String, dynamic> params) async {
    final String? id = params['id'];
    if (id == null || id.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: id'});
    }

    final String? accountId = params['accountId'];
    final allBills = await _billController.getBills();

    Bill? foundBill;
    for (final bill in allBills) {
      if (bill.id == id) {
        if (accountId == null || accountId.isEmpty || bill.accountId == accountId) {
          foundBill = bill;
          break;
        }
      }
    }

    if (foundBill == null) {
      return jsonEncode(null);
    }

    return jsonEncode(foundBill.toJson());
  }

  /// 根据标题查找账单
  /// @param params.title 账单标题 (必需)
  /// @param params.fuzzy 是否模糊匹配 (可选，默认 false)
  /// @param params.accountId 限定在特定账户内查找 (可选)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  /// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
  /// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
  Future<String> _jsFindBillByTitle(Map<String, dynamic> params) async {
    final String? title = params['title'];
    if (title == null || title.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: title'});
    }

    final bool fuzzy = params['fuzzy'] ?? false;
    final String? accountId = params['accountId'];
    final bool findAll = params['findAll'] ?? false;
    final int? offset = params['offset'];
    final int? count = params['count'];

    final allBills = await _billController.getBills();
    final List<Bill> matchedBills = [];

    for (final bill in allBills) {
      // 如果指定了 accountId，先过滤账户
      if (accountId != null && accountId.isNotEmpty && bill.accountId != accountId) {
        continue;
      }

      bool matches = false;
      if (fuzzy) {
        matches = bill.title.contains(title);
      } else {
        matches = bill.title == title;
      }

      if (matches) {
        matchedBills.add(bill);
        if (!findAll) break;
      }
    }

    if (findAll) {
      final billsJson = matchedBills.map((b) => b.toJson()).toList();

      // 检查是否需要分页
      if (offset != null || count != null) {
        final paginated = _paginate(
          billsJson,
          offset: offset ?? 0,
          count: count ?? 100,
        );
        return jsonEncode(paginated);
      }

      return jsonEncode(billsJson);
    } else {
      if (matchedBills.isEmpty) {
        return jsonEncode(null);
      }
      return jsonEncode(matchedBills.first.toJson());
    }
  }

  /// 根据分类查找账单
  /// @param params.category 分类名称 (必需)
  /// @param params.accountId 限定在特定账户内查找 (可选)
  /// @param params.startDate 开始日期 (可选，格式: YYYY-MM-DD)
  /// @param params.endDate 结束日期 (可选，格式: YYYY-MM-DD)
  /// @param params.offset 分页起始位置 (可选，默认 0)
  /// @param params.count 返回数量 (可选，默认 100)
  Future<String> _jsFindBillsByCategory(Map<String, dynamic> params) async {
    final String? category = params['category'];
    if (category == null || category.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: category'});
    }

    final String? accountId = params['accountId'];
    final String? startDate = params['startDate'];
    final String? endDate = params['endDate'];
    final int? offset = params['offset'];
    final int? count = params['count'];

    // 解析日期参数
    DateTime? start;
    DateTime? end;

    if (startDate != null && startDate.isNotEmpty) {
      try {
        start = DateTime.parse(startDate);
      } catch (e) {
        return jsonEncode({'error': '日期格式错误: $startDate，应为 YYYY-MM-DD 格式'});
      }
    }

    if (endDate != null && endDate.isNotEmpty) {
      try {
        end = DateTime.parse(endDate);
      } catch (e) {
        return jsonEncode({'error': '日期格式错误: $endDate，应为 YYYY-MM-DD 格式'});
      }
    }

    // 获取账单列表
    final allBills = await _billController.getBills(
      startDate: start,
      endDate: end,
    );

    // 过滤账单
    final matchedBills = allBills.where((bill) {
      // 匹配分类
      if (bill.category != category) return false;

      // 如果指定了 accountId，过滤账户
      if (accountId != null && accountId.isNotEmpty && bill.accountId != accountId) {
        return false;
      }

      return true;
    }).toList();

    final billsJson = matchedBills.map((b) => b.toJson()).toList();

    // 检查是否需要分页
    if (offset != null || count != null) {
      final paginated = _paginate(
        billsJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    return jsonEncode(billsJson);
  }
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
    Colors.orange,
    Colors.purple,
  ];

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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => AccountListScreen(billPlugin: billPlugin),
        ),
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

  @override
  Widget build(BuildContext context) {
    // 如果没有账户，显示加载指示器
    if (billPlugin.accounts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final Color unselectedColor =
        _colors[_currentPage].computeLuminance() < 0.5
            ? Colors.black.withOpacity(0.6)
            : Colors.white.withOpacity(0.6);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => PluginManager.toHomeScreen(context),
        ),
        title: Text(
          billPlugin.selectedAccount?.title ??
              BillLocalizations.of(context).accountTitle,
        ),
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
      body: BottomBar(
        fit: StackFit.expand,
        icon:
            (width, height) => Center(
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  // 滚动到顶部功能
                  if (_tabController.indexIsChanging) return;

                  // 这里可以添加滚动到顶部的逻辑
                  // 由于我们使用的是TabBarView，可以考虑切换到第一个tab
                  if (_currentPage != 0) {
                    _tabController.animateTo(0);
                  }
                },
                icon: Icon(
                  Icons.keyboard_arrow_up,
                  color: _colors[_currentPage],
                  size: width,
                ),
              ),
            ),
        borderRadius: BorderRadius.circular(25),
        duration: const Duration(milliseconds: 300),
        curve: Curves.decelerate,
        showIcon: true,
        width: MediaQuery.of(context).size.width * 0.85,
        barColor:
            _colors[_currentPage].computeLuminance() > 0.5
                ? Colors.black
                : Colors.white,
        start: 2,
        end: 0,
        offset: 12,
        barAlignment: Alignment.bottomCenter,
        iconHeight: 35,
        iconWidth: 35,
        reverse: false,
        barDecoration: BoxDecoration(
          color: _colors[_currentPage].withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: _colors[_currentPage].withOpacity(0.3),
            width: 1,
          ),
        ),
        iconDecoration: BoxDecoration(
          color: _colors[_currentPage].withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _colors[_currentPage].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        hideOnScroll: true,
        scrollOpposite: false,
        onBottomBarHidden: () {},
        onBottomBarShown: () {},
        body:
            (context, controller) => TabBarView(
              controller: _tabController,
              dragStartBehavior: DragStartBehavior.down,
              physics: const BouncingScrollPhysics(),
          children: [
            BillListScreen(
              billPlugin: billPlugin,
              accountId: billPlugin.selectedAccount?.id ?? '',
            ),
            BillStatsScreen(
              billPlugin: billPlugin,
              accountId: billPlugin.selectedAccount?.id ?? '',
              startDate: DateTime.now().subtract(
                const Duration(days: 30),
              ), // 默认显示最近30天
              endDate: DateTime.now(),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              indicatorPadding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color:
                      _currentPage < 2
                          ? _colors[_currentPage]
                          : unselectedColor,
                  width: 4,
                ),
                insets: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              ),
              labelColor:
                  _currentPage < 2 ? _colors[_currentPage] : unselectedColor,
              unselectedLabelColor: unselectedColor,
              tabs: const [
                Tab(icon: Icon(Icons.receipt_long), text: '账单列表'),
                Tab(icon: Icon(Icons.bar_chart), text: '统计分析'),
              ],
            ),
            Positioned(
              top: -25,
              child: FloatingActionButton(
                backgroundColor: Color(0xFF3498DB),
                elevation: 4,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: Colors.white, size: 32),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => BillEditScreen(
                            billPlugin: billPlugin,
                            accountId: billPlugin.selectedAccount?.id ?? '',
                          ),
                    ),
                  );
                },
              ),
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
