import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Bill {
  final String id;
  String title;
  String? tag;
  double amount; // 正数表示收入，负数表示支出
  String accountId;
  String? note;
  DateTime createdAt;
  IconData icon;

  Bill({
    String? id,
    required this.title,
    this.tag,
    required this.amount,
    required this.accountId,
    this.note,
    DateTime? createdAt,
    required this.icon,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();

  // 从JSON创建账单
  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as String,
      title: json['title'] as String,
      tag: json['tag'] as String?,
      amount: (json['amount'] as num).toDouble(),
      accountId: json['accountId'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      icon: IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String?,
        fontPackage: json['iconFontPackage'] as String?,
      ),
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'tag': tag,
      'amount': amount,
      'accountId': accountId,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
    };
  }

  // 创建账单副本
  Bill copyWith({
    String? title,
    String? tag,
    double? amount,
    String? accountId,
    String? note,
    DateTime? createdAt,
    IconData? icon,
  }) {
    return Bill(
      id: id,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      icon: icon ?? this.icon,
    );
  }

  // 判断是否为支出
  bool get isExpense => amount < 0;

  // 判断是否为收入
  bool get isIncome => amount > 0;

  // 获取绝对金额
  double get absoluteAmount => amount.abs();
}