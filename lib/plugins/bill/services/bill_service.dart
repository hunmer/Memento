import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/bill_model.dart';

class BillService {
  static const String _billKey = 'bills';
  List<BillModel> _bills = [];

  // 单例模式
  static final BillService _instance = BillService._internal();

  factory BillService() {
    return _instance;
  }

  BillService._internal();

  Future<void> init() async {
    await loadBills();
  }

  Future<void> loadBills() async {
    final prefs = await SharedPreferences.getInstance();
    final billsJson = prefs.getStringList(_billKey) ?? [];

    _bills =
        billsJson.map((json) => BillModel.fromMap(jsonDecode(json))).toList();
  }

  Future<void> saveBills() async {
    final prefs = await SharedPreferences.getInstance();
    final billsJson = _bills.map((bill) => jsonEncode(bill.toMap())).toList();

    await prefs.setStringList(_billKey, billsJson);
  }

  List<BillModel> getBills() {
    return [..._bills];
  }

  Future<void> addBill(BillModel bill) async {
    _bills.add(bill);
    await saveBills();
  }

  Future<void> updateBill(BillModel updatedBill) async {
    final index = _bills.indexWhere((bill) => bill.id == updatedBill.id);
    if (index != -1) {
      _bills[index] = updatedBill;
      await saveBills();
    }
  }

  Future<void> deleteBill(String id) async {
    _bills.removeWhere((bill) => bill.id == id);
    await saveBills();
  }

  // 获取总支出
  double getTotalExpense() {
    return _bills
        .where((bill) => bill.isExpense)
        .fold(0, (sum, bill) => sum + bill.amount);
  }

  // 获取总收入
  double getTotalIncome() {
    return _bills
        .where((bill) => !bill.isExpense)
        .fold(0, (sum, bill) => sum + bill.amount);
  }

  // 按类别获取支出统计
  Map<String, double> getExpenseByCategory() {
    final result = <String, double>{};

    for (final bill in _bills.where((bill) => bill.isExpense)) {
      if (result.containsKey(bill.category)) {
        result[bill.category] = result[bill.category]! + bill.amount;
      } else {
        result[bill.category] = bill.amount;
      }
    }

    return result;
  }

  // 获取一段时间内的账单
  List<BillModel> getBillsInRange(DateTime start, DateTime end) {
    return _bills
        .where(
          (bill) =>
              bill.date.isAfter(start) &&
              bill.date.isBefore(end.add(const Duration(days: 1))),
        )
        .toList();
  }
}
