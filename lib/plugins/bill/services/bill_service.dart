import 'dart:math';
import 'package:flutter/material.dart';
import '../models/bill.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 账单服务，负责处理账单相关的业务逻辑
class BillService {
  static final BillService _instance = BillService._internal();
  factory BillService() => _instance;
  
  BillService._internal() {
    // 在构造函数中自动初始化
    initialize().then((_) {
      debugPrint('BillService 初始化完成');
    }).catchError((e) {
      debugPrint('BillService 初始化失败: $e');
    });
  }

  static const String _billsKey = 'bills_data';
  final List<Bill> _bills = [];
  bool _initialized = false;
  bool _isLoading = false;
  
  /// 初始化服务，加载账单数据
  Future<void> initialize() async {
    if (_initialized || _isLoading) return;
    
    _isLoading = true;
    try {
      await _loadBills();
      _initialized = true;
    } finally {
      _isLoading = false;
    }
  }
  
  /// 从本地存储加载账单数据
  Future<void> _loadBills() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final billsJson = prefs.getStringList(_billsKey);
      
      // 如果数据为null，可能是第一次使用，不需要抛出错误
      if (billsJson == null) {
        debugPrint('未找到已保存的账单数据，可能是首次使用');
        return;
      }
      
      _bills.clear();
      List<String> failedEntries = [];
      
      for (final json in billsJson) {
        try {
          final billData = jsonDecode(json);
          final bill = Bill.fromJson(billData);
          _bills.add(bill);
        } catch (e) {
          failedEntries.add(json);
          debugPrint('解析账单数据失败: $e');
          debugPrint('问题数据: $json');
        }
      }
      
      // 按日期排序
      _bills.sort((a, b) => b.date.compareTo(a.date));
      
      if (failedEntries.isNotEmpty) {
        debugPrint('警告：${failedEntries.length}条账单数据解析失败');
        // 可以选择保存有效的数据
        await _saveBills();
      }
      
      debugPrint('成功加载 ${_bills.length} 条账单数据');
    } catch (e, stackTrace) {
      debugPrint('加载账单数据失败: $e');
      debugPrint('错误堆栈: $stackTrace');
      // 重新抛出错误，让上层知道发生了问题
      rethrow;
    }
  }
  
  /// 保存账单数据到本地存储
  Future<void> _saveBills() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final billsJson = _bills.map((bill) => jsonEncode(bill.toJson())).toList();
      await prefs.setStringList(_billsKey, billsJson);
      debugPrint('成功保存 ${_bills.length} 条账单数据');
    } catch (e) {
      debugPrint('保存账单数据失败: $e');
      throw '保存账单数据失败: $e';
    }
  }
  
  /// 获取所有账单
  Future<List<Bill>> getAllBills() async {
    await _ensureInitialized();
    return List.unmodifiable(_bills);
  }
  
  /// 确保服务已经初始化
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }
  
  /// 根据日期范围获取账单
  Future<List<Bill>> getBills({DateTime? startDate, DateTime? endDate}) async {
    await _ensureInitialized();
    
    if (startDate == null && endDate == null) {
      return List.unmodifiable(_bills);
    }
    
    return _bills.where((bill) {
      bool match = true;
      if (startDate != null) {
        match = match && bill.date.isAfter(startDate.subtract(const Duration(days: 1)));
      }
      if (endDate != null) {
        match = match && bill.date.isBefore(endDate.add(const Duration(days: 1)));
      }
      return match;
    }).toList();
  }
  
  /// 添加新账单
  Future<Bill> addBill(Bill bill) async {
    await _ensureInitialized();
    _bills.add(bill);
    await _saveBills();
    return bill;
  }
  
  /// 更新账单
  Future<Bill> updateBill(Bill bill) async {
    await _ensureInitialized();
    final index = _bills.indexWhere((b) => b.id == bill.id);
    if (index == -1) {
      throw '账单不存在';
    }
    
    _bills[index] = bill;
    await _saveBills();
    return bill;
  }
  
  /// 删除账单
  Future<void> deleteBill(String billId) async {
    await _ensureInitialized();
    _bills.removeWhere((bill) => bill.id == billId);
    await _saveBills();
  }
  
  /// 获取账单类别统计
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
  
  /// 获取日期范围内的总收入
  Future<double> getTotalIncome({DateTime? startDate, DateTime? endDate}) async {
    final bills = await getBills(startDate: startDate, endDate: endDate);
    return bills
        .where((bill) => bill.amount > 0)
        .fold<double>(0, (sum, bill) => sum + bill.amount);
  }
  
  /// 获取日期范围内的总支出
  Future<double> getTotalExpense({DateTime? startDate, DateTime? endDate}) async {
    final bills = await getBills(startDate: startDate, endDate: endDate);
    return bills
        .where((bill) => bill.amount < 0)
        .fold<double>(0, (sum, bill) => sum + bill.amount.abs());
  }
  
  /// 检查账单数据存储状态
  Future<Map<String, dynamic>> checkBillsStorage() async {
    try {
      await _ensureInitialized();
      final prefs = await SharedPreferences.getInstance();
      final billsJson = prefs.getStringList(_billsKey);
      
      return {
        'success': true,
        'billsInMemory': _bills.length,
        'billsInStorage': billsJson?.length ?? 0,
        'storageExists': billsJson != null,
        'initialized': _initialized,
        'storageKeys': prefs.getKeys().toList(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'billsInMemory': _bills.length,
        'initialized': _initialized,
      };
    }
  }
  
  /// 强制重新加载账单数据
  Future<int> forceReloadBills() async {
    _initialized = false;
    await initialize();
    return _bills.length;
  }
  
  /// 添加测试账单数据（仅用于开发和测试）
  Future<List<Bill>> addTestBills(int count) async {
    await _ensureInitialized();
    
    final List<Bill> newBills = [];
    final List<String> categories = ['餐饮', '交通', '购物', '娱乐', '住宿', '工资', '奖金'];
    final List<String> titles = ['早餐', '午餐', '晚餐', '打车', '地铁', '公交', '购物', '电影', '游戏', '房租', '月薪', '奖金'];
    final Random random = Random();
    
    for (int i = 0; i < count; i++) {
      final bool isExpense = random.nextBool();
      final double amount = isExpense 
          ? -random.nextDouble() * 1000 
          : random.nextDouble() * 5000;
      
      final Bill bill = Bill(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: titles[random.nextInt(titles.length)],
        amount: double.parse(amount.toStringAsFixed(2)),
        category: categories[random.nextInt(categories.length)],
        date: DateTime.now().subtract(Duration(days: random.nextInt(30))),
        accountId: 'default',
        note: '测试数据 #$i',
      );
      
      _bills.add(bill);
      newBills.add(bill);
    }
    
    await _saveBills();
    return newBills;
  }
}