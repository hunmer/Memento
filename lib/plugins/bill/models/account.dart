import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'bill.dart';

class Account {
  final String id;
  String title;
  IconData icon;
  Color backgroundColor;
  double totalAmount;
  List<Bill> bills;

  Account({
    String? id,
    required this.title,
    required this.icon,
    required this.backgroundColor,
    this.totalAmount = 0.0,
    List<Bill>? bills,
  }) : id = id ?? const Uuid().v4(),
       bills = bills ?? [];

  // 计算总金额
  void calculateTotal() {
    totalAmount = bills.fold(0.0, (sum, bill) => sum + bill.amount);
  }

  // 从JSON创建账户
  factory Account.fromJson(Map<String, dynamic> json) {
    final List<dynamic> billsJson = json['bills'] as List<dynamic>? ?? [];
    return Account(
      id: json['id'] as String,
      title: json['title'] as String,
      icon: IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String?,
        fontPackage: json['iconFontPackage'] as String?,
      ),
      backgroundColor: Color(json['backgroundColor'] as int),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      bills:
          billsJson
              .map(
                (billJson) => Bill.fromJson(billJson as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  // 添加账单
  void addBill(Bill bill) {
    // bill.id 永远不会为 null，因为 Bill 构造函数会自动生成 ID
    // 检查是否已存在相同 ID 的账单
    if (bills.any((existingBill) => existingBill.id == bill.id)) {
      throw Exception('Bill with the same ID already exists');
    }
    bills.add(bill);
    calculateTotal();
  }

  // 更新账单
  void updateBill(Bill updatedBill) {
    final index = bills.indexWhere((bill) => bill.id == updatedBill.id);
    if (index != -1) {
      bills[index] = updatedBill;
      calculateTotal();
    } else {
      // 如果找不到账单，添加为新账单
      addBill(updatedBill);
    }
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    calculateTotal(); // 保存前更新总金额
    return {
      'id': id,
      'title': title,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'backgroundColor': backgroundColor.value,
      'totalAmount': totalAmount,
      'bills': bills.map((bill) => bill.toJson()).toList(),
    };
  }

  // 创建账户副本
  Account copyWith({
    String? title,
    IconData? icon,
    Color? backgroundColor,
    double? totalAmount,
    List<Bill>? bills,
  }) {
    return Account(
      id: id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      totalAmount: totalAmount ?? this.totalAmount,
      bills: bills ?? this.bills,
    );
  }
}
