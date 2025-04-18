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
