import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/bill.dart';
import '../models/bill_statistics.dart';
import '../models/statistic_range.dart';

class BillController with ChangeNotifier {
  static final BillController _instance = BillController._internal();
  factory BillController() => _instance;
  
  BillController._internal() {
    _loadAccounts();
  }

  static const String _accountsKey = 'accounts';
  final List<Account> _accounts = [];
  String? _selectedAccountId;
  bool _initialized = false;
  bool _isLoading = false;

  List<Account> get accounts => List.unmodifiable(_accounts);
  
  String? get selectedAccountId => _selectedAccountId;
  
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

  // 确保控制器已初始化
  Future<void> _ensureInitialized() async {
    if (!_initialized && !_isLoading) {
      await _loadAccounts();
    }
  }

  // 从本地存储加载账户列表
  Future<void> initialize() async {
    if (_initialized || _isLoading) return;
    
    _isLoading = true;
    try {
      await _loadAccounts();
      _initialized = true;
    } finally {
      _isLoading = false;
    }
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

  // 根据日期范围获取账单
  Future<List<Bill>> getBills({DateTime? startDate, DateTime? endDate}) async {
    await _ensureInitialized();
    List<Bill> allBills = [];
    
    // 从所有账户收集账单
    for (var account in _accounts) {
      allBills.addAll(account.bills);
    }
    
    if (startDate == null && endDate == null) {
      return List.unmodifiable(allBills);
    }
    
    return allBills.where((bill) {
      bool match = true;
      if (startDate != null) {
        match = match && bill.createdAt.isAfter(startDate.subtract(const Duration(days: 1)));
      }
      if (endDate != null) {
        match = match && bill.createdAt.isBefore(endDate.add(const Duration(days: 1)));
      }
      return match;
    }).toList();
  }

  // 获取账单类别统计
  Future<Map<String, double>> getCategoryStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final bills = await getBills(startDate: startDate, endDate: endDate);
    final Map<String, double> result = {};
    
    for (final bill in bills) {
      if (!result.containsKey(bill.category)) {
        result[bill.category] = 0;
      }
      result[bill.category] = (result[bill.category] ?? 0) + bill.amount;
    }
    
    return result;
  }

  // 获取日期范围内的总收入
  Future<double> getTotalIncome({DateTime? startDate, DateTime? endDate}) async {
    final bills = await getBills(startDate: startDate, endDate: endDate);
    return bills
        .where((bill) => bill.amount > 0)
        .fold<double>(0, (sum, bill) => sum + bill.amount);
  }

  // 获取日期范围内的总支出
  Future<double> getTotalExpense({DateTime? startDate, DateTime? endDate}) async {
    final bills = await getBills(startDate: startDate, endDate: endDate);
    return bills
        .where((bill) => bill.amount < 0)
        .fold<double>(0, (sum, bill) => sum + bill.amount.abs());
  }

  // 检查账单数据存储状态
  Future<Map<String, dynamic>> checkBillsStorage() async {
    try {
      await _ensureInitialized();
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'success': true,
        'accountsCount': _accounts.length,
        'billsCount': _accounts.fold<int>(0, (sum, account) => sum + account.bills.length),
        'initialized': _initialized,
        'storageKeys': prefs.getKeys().toList(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'accountsCount': _accounts.length,
        'initialized': _initialized,
      };
    }
  }

  // 强制重新加载账单数据
  Future<int> forceReloadBills() async {
    _initialized = false;
    await initialize();
    return _accounts.fold<int>(0, (sum, account) => sum + account.bills.length);
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
}