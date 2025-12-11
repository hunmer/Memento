import 'dart:convert';
import 'package:get/get.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
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

  // ==================== 辅助方法 ====================

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
    final result = await _billUseCase.getAccounts(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message ?? '获取账户失败'});
    }

    return jsonEncode(result.dataOrNull);
  }

  /// 创建账户
  /// @param params.title 账户名称 (必需)
  /// @param params.id 账户ID (可选，不传则自动生成 UUID)
  /// @param params.iconCodePoint 图标代码点 (可选，默认 Icons.account_balance_wallet)
  /// @param params.backgroundColor 背景颜色值 (可选，默认绿色)
  Future<String> _jsCreateAccount(Map<String, dynamic> params) async {
    final result = await _billUseCase.createAccount(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message ?? '创建账户失败'});
    }

    return jsonEncode(result.dataOrNull);
  }

  /// 更新账户
  /// @param params.accountId 账户ID (必需)
  /// @param params.title 新账户名称 (可选)
  /// @param params.iconCodePoint 新图标代码点 (可选)
  /// @param params.backgroundColor 新背景颜色值 (可选)
  Future<String> _jsUpdateAccount(Map<String, dynamic> params) async {
    final result = await _billUseCase.updateAccount(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message ?? '更新账户失败'});
    }

    return jsonEncode(result.dataOrNull);
  }

  /// 删除账户
  /// @param params.accountId 账户ID (必需)
  Future<String> _jsDeleteAccount(Map<String, dynamic> params) async {
    final result = await _billUseCase.deleteAccount(params);

    if (result.isFailure) {
      return jsonEncode({'success': false, 'error': result.errorOrNull?.message ?? '删除账户失败'});
    }

    return jsonEncode({'success': true, 'accountId': params['accountId']});
  }

  /// 获取账单列表
  /// @param params.accountId 账户ID (可选，不传则返回所有账户的账单)
  /// @param params.startDate 开始日期 (可选，格式: YYYY-MM-DD)
  /// @param params.endDate 结束日期 (可选，格式: YYYY-MM-DD)
  /// @param params.offset 分页起始位置 (可选，默认 0)
  /// @param params.count 返回数量 (可选，默认 100)
  Future<String> _jsGetBills(Map<String, dynamic> params) async {
    final result = await _billUseCase.getBills(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message ?? '获取账单失败'});
    }

    return jsonEncode(result.dataOrNull);
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
    final result = await _billUseCase.createBill(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message ?? '创建账单失败'});
    }

    return jsonEncode(result.dataOrNull);
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
    final result = await _billUseCase.updateBill(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message ?? '更新账单失败'});
    }

    return jsonEncode(result.dataOrNull);
  }

  /// 删除账单
  /// @param params.accountId 账户ID (必需)
  /// @param params.billId 账单ID (必需)
  Future<String> _jsDeleteBill(Map<String, dynamic> params) async {
    final result = await _billUseCase.deleteBill(params);

    if (result.isFailure) {
      return jsonEncode({'success': false, 'error': result.errorOrNull?.message ?? '删除账单失败'});
    }

    return jsonEncode({
      'success': true,
      'accountId': params['accountId'],
      'billId': params['billId'],
    });
  }

  /// 获取统计信息
  /// @param params.startDate 开始日期 (可选，格式: YYYY-MM-DD)
  /// @param params.endDate 结束日期 (可选，格式: YYYY-MM-DD)
  /// @param params.accountId 账户ID (可选，不传则统计所有账户)
  Future<String> _jsGetStats(Map<String, dynamic> params) async {
    final result = await _billUseCase.getStats(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message ?? '获取统计失败'});
    }

    // result.dataOrNull 返回的是 Map<String, dynamic>
    final stats = result.dataOrNull as Map<String, dynamic>;
    return jsonEncode({
      'totalIncome': stats['totalIncome'],
      'totalExpense': stats['totalExpense'],
      'balance': stats['balance'],
      'billCount': stats['billCount'],
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
    final result = await _billUseCase.getCategoryStats(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message ?? '获取分类统计失败'});
    }

    // result.dataOrNull 返回的是 List<Map<String, dynamic>>
    final categoryStats = result.dataOrNull as List<Map<String, dynamic>>;
    final statsMap = <String, double>{};
    for (final stat in categoryStats) {
      statsMap[stat['category'] as String] = stat['amount'] as double;
    }

    return jsonEncode(statsMap);
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
      final accountsJson =
          matchedAccounts.map((a) {
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
      orElse:
          () => Account(
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
      final accountsJson =
          matchedAccounts.map((a) {
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
      if (accountId != null &&
          accountId.isNotEmpty &&
          bill.accountId != accountId) {
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
        if (accountId == null ||
            accountId.isEmpty ||
            bill.accountId == accountId) {
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
      if (accountId != null &&
          accountId.isNotEmpty &&
          bill.accountId != accountId) {
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
    final matchedBills =
        allBills.where((bill) {
          // 匹配分类
          if (bill.category != category) return false;

          // 如果指定了 accountId，过滤账户
          if (accountId != null &&
              accountId.isNotEmpty &&
              bill.accountId != accountId) {
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

  // ==================== 数据选择器注册 ====================

  /// 注册数据选择器
  void _registerDataSelectors() {
    // 1. 选择账户（单级）
    pluginDataSelectorService.registerSelector(SelectorDefinition(
      id: 'bill.account',
      pluginId: id,
      name: '选择账户',
      icon: icon,
      color: color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'account',
          title: '选择账户',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (_) async {
            return _billController.accounts.map((account) => SelectableItem(
              id: account.id,
              title: account.title,
              subtitle: '余额: ¥${account.totalAmount.toStringAsFixed(2)}',
              icon: account.icon,
              color: account.backgroundColor,
              rawData: account,
            )).toList();
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items.where((item) {
              return item.title.toLowerCase().contains(lowerQuery);
            }).toList();
          },
        ),
      ],
    ));

    // 2. 选择账单记录（两级：账户 → 账单）
    pluginDataSelectorService.registerSelector(SelectorDefinition(
      id: 'bill.record',
      pluginId: id,
      name: '选择账单记录',
      icon: Icons.receipt_long,
      color: color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        // 第一步：选择账户
        SelectorStep(
          id: 'account',
          title: '选择账户',
          viewType: SelectorViewType.list,
          isFinalStep: false,
          dataLoader: (_) async {
            return _billController.accounts.map((account) => SelectableItem(
              id: account.id,
              title: account.title,
              subtitle: '余额: ¥${account.totalAmount.toStringAsFixed(2)} | ${account.bills.length} 条账单',
              icon: account.icon,
              color: account.backgroundColor,
              rawData: account,
            )).toList();
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items.where((item) {
              return item.title.toLowerCase().contains(lowerQuery);
            }).toList();
          },
        ),
        // 第二步：选择账单
        SelectorStep(
          id: 'bill',
          title: '选择账单',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (previousSelections) async {
            final account = previousSelections['account'] as Account;
            // 按日期倒序排列
            final sortedBills = List<Bill>.from(account.bills)
              ..sort((a, b) => b.date.compareTo(a.date));

            return sortedBills.map((bill) => SelectableItem(
              id: bill.id,
              title: bill.title,
              subtitle: '${bill.category} | ${bill.date.toString().substring(0, 10)} | ¥${bill.amount.toStringAsFixed(2)}',
              icon: bill.icon,
              color: bill.iconColor,
              rawData: bill,
            )).toList();
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items.where((item) {
              final bill = item.rawData as Bill;
              return item.title.toLowerCase().contains(lowerQuery) ||
                  bill.category.toLowerCase().contains(lowerQuery) ||
                  bill.note.toLowerCase().contains(lowerQuery);
            }).toList();
          },
          emptyText: '该账户暂无账单记录',
        ),
      ],
    ));
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
  static const double _bottomBarOffset = 12.0;
  final GlobalKey _bottomBarKey = GlobalKey(debugLabel: 'bill_bottom_bar');
  double _bottomBarHeight = kBottomNavigationBarHeight + _bottomBarOffset * 2;

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
      NavigationHelper.pushReplacement(context, AccountListScreen(billPlugin: billPlugin),
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

  void _scheduleBottomBarHeightMeasurement() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderObject = _bottomBarKey.currentContext?.findRenderObject();
      if (renderObject is RenderBox) {
        final safeAreaBottom = MediaQuery.of(context).padding.bottom;
        final newHeight =
            renderObject.size.height + _bottomBarOffset * 2 + safeAreaBottom;
        if ((newHeight - _bottomBarHeight).abs() > 0.5) {
          setState(() {
            _bottomBarHeight = newHeight;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleBottomBarHeightMeasurement();

    // 如果没有账户，显示加载指示器
    if (billPlugin.accounts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final Color unselectedColor =
        _colors[_currentPage].computeLuminance() < 0.5
            ? Colors.black.withOpacity(0.6)
            : Colors.white.withOpacity(0.6);
    final Color bottomAreaColor = Theme.of(context).scaffoldBackgroundColor;
    final mediaQuery = MediaQuery.of(context);

    return BottomBar(
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
      width: mediaQuery.size.width * 0.85,
      barColor:
          _colors[_currentPage].computeLuminance() > 0.5
              ? Colors.black
              : Colors.white,
      start: 2,
      end: 0,
      offset: _bottomBarOffset,
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
          (context, controller) => Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(bottom: _bottomBarHeight),
                  child: TabBarView(
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
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: _bottomBarHeight,
                  color: bottomAreaColor,
                ),
              ),
            ],
          ),
      child: Stack(
        key: _bottomBarKey,
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
            child: OpenContainer<bool>(
              transitionType: ContainerTransitionType.fade,
              tappable: false,
              closedElevation: 0.0,
              closedShape: const RoundedRectangleBorder(),
              closedColor: Colors.transparent,
              openBuilder: (BuildContext context, VoidCallback _) {
                return BillEditScreen(
                  billPlugin: billPlugin,
                  accountId: billPlugin.selectedAccount?.id ?? '',
                );
              },
              closedBuilder: (BuildContext context, VoidCallback openContainer) {
                return FloatingActionButton(
                  onPressed: openContainer,
                  backgroundColor: Color(0xFF3498DB),
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, color: Colors.white, size: 32),
                );
              },
            ),
          ),
        ],
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
