import 'package:flutter/material.dart';

class Bill {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? tag;
  final IconData icon;
  final Color iconColor;
  final String accountId;

  /// 订阅相关字段
  final String? subscriptionId;
  final bool isSubscription;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;

  /// 判断是否为支出
  bool get isExpense => amount < 0;
  /// 获取账单金额的绝对值
  double get absoluteAmount => amount.abs();

  /// 判断是否为订阅账单
  bool get isFromSubscription => isSubscription && subscriptionId != null;

  /// 获取订阅账单标题（带[订阅]前缀）
  String get subscriptionTitle {
    if (isFromSubscription) {
      return '[订阅] $title';
    }
    return title;
  }

  Bill({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.accountId,
    this.note = '',
    this.tag,
    this.icon = Icons.attach_money,
    this.iconColor = Colors.blue,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.subscriptionId,
    this.isSubscription = false,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Bill copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? note,
    String? tag,
    String? accountId,
    IconData? icon,
    Color? iconColor,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? subscriptionId,
    bool? isSubscription,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
  }) {
    return Bill(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      tag: tag ?? this.tag,
      accountId: accountId ?? this.accountId,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      isSubscription: isSubscription ?? this.isSubscription,
      subscriptionStartDate: subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
      'tag': tag,
      'accountId': accountId,
      'icon': icon.codePoint,
      'iconColor': iconColor.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };

    // 只有当字段非null时才添加到JSON中（确保向后兼容）
    if (subscriptionId != null) {
      json['subscriptionId'] = subscriptionId;
    }
    if (isSubscription != false) {
      json['isSubscription'] = isSubscription;
    }
    if (subscriptionStartDate != null) {
      json['subscriptionStartDate'] = subscriptionStartDate!.toIso8601String();
    }
    if (subscriptionEndDate != null) {
      json['subscriptionEndDate'] = subscriptionEndDate!.toIso8601String();
    }

    return json;
  }

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: json['amount'] as double,
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String? ?? '',
      tag: json['tag'] as String?,
      accountId: json['accountId'] as String,
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
      iconColor: Color(json['iconColor'] as int),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      subscriptionId: json['subscriptionId'] as String?,
      isSubscription: json['isSubscription'] as bool? ?? false,
      subscriptionStartDate: json['subscriptionStartDate'] != null
          ? DateTime.parse(json['subscriptionStartDate'] as String)
          : null,
      subscriptionEndDate: json['subscriptionEndDate'] != null
          ? DateTime.parse(json['subscriptionEndDate'] as String)
          : null,
    );
  }
}