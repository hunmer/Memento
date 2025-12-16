import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Subscription {
  final String id;
  final String name;
  final double totalAmount;
  final int days;
  final double dailyAmount;
  final String category;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? terminatedAt;
  final String? note;
  final IconData icon;
  final Color iconColor;

  Subscription({
    String? id,
    required this.name,
    required this.totalAmount,
    required this.days,
    String? category,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.note,
    this.icon = Icons.subscriptions,
    this.iconColor = Colors.blue,
    DateTime? createdAt,
    DateTime? terminatedAt,
  })  : id = id ?? const Uuid().v4(),
        dailyAmount = totalAmount / days,
        category = category ?? '订阅',
        createdAt = createdAt ?? DateTime.now(),
        terminatedAt = terminatedAt;

  /// 计算剩余天数
  int get remainingDays {
    if (endDate != null) {
      final now = DateTime.now();
      final remaining = endDate!.difference(now).inDays;
      return remaining > 0 ? remaining : 0;
    }
    // 如果没有结束日期，计算从今天到总天数的剩余天数
    final now = DateTime.now();
    final totalDuration = Duration(days: days);
    final elapsed = now.difference(startDate);
    final remaining = totalDuration.inDays - elapsed.inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// 计算已完成天数
  int get completedDays {
    final now = DateTime.now();
    final elapsed = now.difference(startDate).inDays;
    return elapsed.clamp(0, days);
  }

  /// 计算进度百分比（0.0 - 1.0）
  double get progress {
    return completedDays / days;
  }

  /// 获取当前应该生成的账单日期列表
  List<DateTime> get pendingBillDates {
    if (!isActive) return [];

    final List<DateTime> dates = [];
    final now = DateTime.now();

    // 从订阅开始日期到今天（或结束日期），生成每一天的日期
    final lastDate = endDate != null && endDate!.isBefore(now)
        ? endDate!
        : now;

    for (int i = 0; i < days; i++) {
      final billDate = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      ).add(Duration(days: i));

      if (billDate.isAfter(lastDate)) break;
      dates.add(billDate);
    }

    return dates;
  }

  Subscription copyWith({
    String? id,
    String? name,
    double? totalAmount,
    int? days,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? note,
    IconData? icon,
    Color? iconColor,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      totalAmount: totalAmount ?? this.totalAmount,
      days: days ?? this.days,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      note: note ?? this.note,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'totalAmount': totalAmount,
      'days': days,
      'dailyAmount': dailyAmount,
      'category': category,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'terminatedAt': terminatedAt?.toIso8601String(),
      'note': note,
      'icon': icon.codePoint,
      'iconColor': iconColor.value,
    };
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      name: json['name'] as String,
      totalAmount: json['totalAmount'] as double,
      days: json['days'] as int,
      category: json['category'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      isActive: json['isActive'] as bool,
      note: json['note'] as String?,
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
      iconColor: Color(json['iconColor'] as int),
      createdAt: DateTime.parse(json['createdAt'] as String),
      terminatedAt: json['terminatedAt'] != null
          ? DateTime.parse(json['terminatedAt'] as String)
          : null,
    );
  }
}
