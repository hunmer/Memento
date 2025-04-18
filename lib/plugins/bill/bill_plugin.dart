import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/plugin_base.dart';
import '../../core/storage/storage_manager.dart';
import 'screens/bill_list_screen.dart';
import 'screens/bill_stats_screen.dart';
import 'screens/account_list_screen.dart';
import 'models/account.dart';
import 'models/bill.dart';
import 'models/bill_statistics.dart';
import 'models/statistic_range.dart';

class BillPlugin extends PluginBase with ChangeNotifier {
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
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = _accounts
          .map((account) => jsonEncode(account.toJson()))
          .toList();
      await prefs.setStringList(_accountsKey, accountsJson);
      notifyListeners();
    } catch (e) {
      debugPrint('保存账户失败: $e');
      throw '保存账户失败';
    }
  }

  // 创建新账户
  Future<void> createAccount(Account account) async {
    if (_accounts.any((a) => a.title == account.title)) {
      throw '账户名称已存在';
    }
    _accounts.add(account);
    await _saveAccounts();
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
    _accounts[index] = account;
    await _saveAccounts();
  }

  // 删除账户
  Future<void> deleteAccount(String accountId) async {
    _accounts.removeWhere((account) => account.id == accountId);
    await _saveAccounts();
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
        filteredBills = bills.where((bill) => bill.createdAt.isAfter(weekStart)).toList();
        break;
      case StatisticRange.month:
        final monthStart = DateTime(now.year, now.month, 1);
        filteredBills = bills.where((bill) => bill.createdAt.isAfter(monthStart)).toList();
        break;
      case StatisticRange.year:
        final yearStart = DateTime(now.year, 1, 1);
        filteredBills = bills.where((bill) => bill.createdAt.isAfter(yearStart)).toList();
        break;
      case StatisticRange.custom:
        if (startDate != null && endDate != null) {
          filteredBills = bills.where((bill) =>
            bill.createdAt.isAfter(startDate) &&
            bill.createdAt.isBefore(endDate.add(const Duration(days: 1)))
          ).toList();
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
    _accounts[accountIndex] = account.copyWith(bills: updatedBills);
    await _saveAccounts();
  }
  // 移除静态常量，因为已经在接口实现中定义

  @override
  Map<String, dynamic> _settings = {};

  @override
  Map<String, dynamic> get settings => _settings;

  @override
  Future<void> loadSettings(Map<String, dynamic> defaultSettings) async {
    try {
      final storedSettings = await storage.read('${getPluginStoragePath()}/settings.json');
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
        ListTile(
          title: const Text('数据存储位置'),
          subtitle: Text(storage.getPluginStoragePath(id)),
          trailing: const Icon(Icons.folder),
          onTap: () async {
            // TODO: 实现目录选择功能
          },
        ),
        const Divider(),
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

    // 默认选择第一个账户
    final defaultAccount = _accounts.first;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('账单管理'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '账单列表'),
              Tab(text: '统计分析'),
            ],
          ),
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
            BillListScreen(
              billPlugin: this,
              account: defaultAccount,
            ),
            BillStatsScreen(
              billPlugin: this,
              account: defaultAccount,
            ),
          ],
        ),
      ),
    );
  }
}