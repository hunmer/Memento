import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/plugin_base.dart';
// import '../../core/storage/storage_manager.dart';
import 'screens/bill_list_screen.dart';
import 'screens/bill_stats_screen.dart';
import 'screens/account_list_screen.dart';
import 'models/account.dart';
import 'models/bill.dart';
import 'models/bill_statistics.dart';
import 'models/statistic_range.dart';

class BillPlugin extends PluginBase with ChangeNotifier {
  String? _selectedAccountId;

  Account? get selectedAccount {
    if (_selectedAccountId == null) return null;
    try {
      return _accounts.firstWhere(
        (account) => account.id == _selectedAccountId,
      );
    } catch (e) {
      return _accounts.isNotEmpty ? _accounts.first : null;
    }
  }
  
  set selectedAccount(Account? account) {
    _selectedAccountId = account?.id;
    notifyListeners();
  }

  String? get selectedAccountId => _selectedAccountId;

  @override
  String get id => 'bill_plugin';

  @override
  String get name => '账单';

  @override
  String get version => '1.0.0';

  @override
  String get description => '管理个人账单和财务统计';

  @override
  String get author => 'Memento Team';

  @override
  IconData get icon => Icons.account_balance_wallet;

  @override
  Color get color => Colors.green;

  @override
  Future<void> initialize() async {
    await _loadAccounts();
  }

  @override
  Widget buildMainView(BuildContext context) {
    return buildPluginEntryWidget(context);
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
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 统计信息卡片
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // 今日财务
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('今日财务', style: theme.textTheme.bodyMedium),
                    Text(
                      '¥${getTodayFinance().toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            getTodayFinance() >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),

                // 本月财务
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('本月财务', style: theme.textTheme.bodyMedium),
                    Text(
                      '¥${getMonthFinance().toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            getMonthFinance() >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),

                // 本月记账
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('本月记账', style: theme.textTheme.bodyMedium),
                    Text(
                      '${getMonthBillCount()} 笔',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const String _accountsKey = 'accounts';
  final List<Account> _accounts = [];

  List<Account> get accounts => List.unmodifiable(_accounts);

  BillPlugin() {
    _loadAccounts();
  }

  // 从本地存储加载账户列表
  Future<void> _loadAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = prefs.getStringList(_accountsKey) ?? [];
      _accounts.clear();
      _accounts.addAll(
        accountsJson.map((json) => Account.fromJson(jsonDecode(json))),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('加载账户失败: $e');
    }
  }

  // 保存账户列表到本地存储
  Future<void> _saveAccounts() async {
    try {
      // 确保所有账户的总金额都是最新的
      for (var i = 0; i < _accounts.length; i++) {
        _accounts[i].calculateTotal();
      }
      
      final prefs = await SharedPreferences.getInstance();
      final accountsJson =
          _accounts.map((account) => jsonEncode(account.toJson())).toList();
      final success = await prefs.setStringList(_accountsKey, accountsJson);
      if (!success) {
        throw '保存账户数据失败';
      }
    } catch (e) {
      debugPrint('保存账户失败: $e');
      throw '保存账户失败: $e';
    }
  }

  // 创建新账户
  Future<void> createAccount(Account account) async {
    if (_accounts.any((a) => a.title == account.title)) {
      throw '账户名称已存在';
    }
    // 确保账户总金额是正确的
    account.calculateTotal();
    _accounts.add(account);
    await _saveAccounts();
    // 确保在数据保存成功后再通知监听器
    notifyListeners();
  }

  // 更新账户信息
  Future<void> saveAccount(Account account) async {
    final index = _accounts.indexWhere((a) => a.id == account.id);
    if (index == -1) {
      throw '账户不存在';
    }
    if (_accounts.any((a) => a.id != account.id && a.title == account.title)) {
      throw '账户名称已存在';
    }
    
    // 确保账户总金额与账单总和一致
    account.calculateTotal();
    
    // 更新账户列表
    _accounts[index] = account;
    // 先保存数据
    await _saveAccounts();
    
    // 再通知监听器，确保数据已经持久化
    notifyListeners();
  }

  // 删除账户
  Future<void> deleteAccount(String accountId) async {
    _accounts.removeWhere((account) => account.id == accountId);
    await _saveAccounts();
    notifyListeners();
  }

  // 获取账单统计信息
  BillStatistics getStatistics({
    required List<Bill> bills,
    required StatisticRange range,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    List<Bill> filteredBills = bills;
    final now = DateTime.now();

    // 根据统计范围筛选账单
    switch (range) {
      case StatisticRange.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        filteredBills =
            bills.where((bill) => bill.createdAt.isAfter(weekStart)).toList();
        break;
      case StatisticRange.month:
        final monthStart = DateTime(now.year, now.month, 1);
        filteredBills =
            bills.where((bill) => bill.createdAt.isAfter(monthStart)).toList();
        break;
      case StatisticRange.year:
        final yearStart = DateTime(now.year, 1, 1);
        filteredBills =
            bills.where((bill) => bill.createdAt.isAfter(yearStart)).toList();
        break;
      case StatisticRange.custom:
        if (startDate != null && endDate != null) {
          filteredBills =
              bills
                  .where(
                    (bill) =>
                        bill.createdAt.isAfter(startDate) &&
                        bill.createdAt.isBefore(
                          endDate.add(const Duration(days: 1)),
                        ),
                  )
                  .toList();
        }
        break;
      case StatisticRange.all:
        // 使用所有账单，无需筛选
        break;
    }

    // 计算收入和支出
    double totalIncome = 0;
    double totalExpense = 0;

    for (final bill in filteredBills) {
      if (bill.amount > 0) {
        totalIncome += bill.amount;
      } else {
        totalExpense += bill.amount.abs();
      }
    }

    return BillStatistics(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: totalIncome - totalExpense,
    );
  }

  // 删除账单
  Future<void> deleteBill(String accountId, String billId) async {
    final accountIndex = _accounts.indexWhere((a) => a.id == accountId);
    if (accountIndex == -1) {
      throw '账户不存在';
    }

    final account = _accounts[accountIndex];
    final updatedBills = account.bills.where((b) => b.id != billId).toList();
    final updatedAccount = account.copyWith(bills: updatedBills);
    updatedAccount.calculateTotal();
    _accounts[accountIndex] = updatedAccount;
    await _saveAccounts();
    notifyListeners();
  }

  // 获取今日财务统计（收入和支出总和）
  double getTodayFinance() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    double total = 0;

    for (var account in _accounts) {
      for (var bill in account.bills) {
        if (bill.createdAt.year == today.year &&
            bill.createdAt.month == today.month &&
            bill.createdAt.day == today.day) {
          total += bill.amount;
        }
      }
    }
    return total;
  }

  // 获取本月财务统计（收入和支出总和）
  double getMonthFinance() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    double total = 0;

    for (var account in _accounts) {
      for (var bill in account.bills) {
        if (bill.createdAt.isAfter(
              monthStart.subtract(const Duration(days: 1)),
            ) &&
            bill.createdAt.isBefore(DateTime(now.year, now.month + 1, 1))) {
          total += bill.amount;
        }
      }
    }
    return total;
  }

  // 获取本月记账次数
  int getMonthBillCount() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    int count = 0;

    for (var account in _accounts) {
      count +=
          account.bills
              .where(
                (bill) =>
                    bill.createdAt.isAfter(
                      monthStart.subtract(const Duration(days: 1)),
                    ) &&
                    bill.createdAt.isBefore(
                      DateTime(now.year, now.month + 1, 1),
                    ),
              )
              .length;
    }
    return count;
  }

  // 移除静态常量，因为已经在接口实现中定义

  @override
  Map<String, dynamic> _settings = {};

  @override
  Map<String, dynamic> get settings => _settings;

  @override
  Future<void> loadSettings(Map<String, dynamic> defaultSettings) async {
    try {
      final storedSettings = await storage.read(
        '${getPluginStoragePath()}/settings.json',
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
      await storage.write('${getPluginStoragePath()}/settings.json', _settings);
    } catch (e) {
      debugPrint('Warning: Failed to save plugin settings: $e');
    }
  }

  @override
  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    _settings.addAll(newSettings);
    await saveSettings();
  }

  @override
  String getPluginStoragePath() {
    return storage.getPluginStoragePath(id);
  }

  @override
  Widget buildSettingsView(BuildContext context) {
    return Column(
      children: [
      
      ],
    );
  }

  Widget buildPluginEntryWidget(BuildContext context) {
    // 如果没有账户，跳转到账户列表页面
    if (_accounts.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => AccountListScreen(billPlugin: this),
          ),
        );
      });
      return const Center(child: CircularProgressIndicator());
    }
    if(_selectedAccountId == null && _accounts.isNotEmpty) {
      _selectedAccountId = _accounts.first.id;
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${selectedAccount?.title}'),
          bottom: const TabBar(tabs: [Tab(text: '账单列表'), Tab(text: '统计分析')]),
          actions: [
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => AccountListScreen(billPlugin: this),
                  ),
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            BillListScreen(billPlugin: this, accountId: selectedAccount!.id),
            BillStatsScreen(billPlugin: this, accountId: selectedAccount!.id),
          ],
        ),
      ),
    );
  }
}
