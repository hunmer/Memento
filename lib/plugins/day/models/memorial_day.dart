import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class MemorialDay {
  final String id;
  final String title;
  final DateTime creationDate;
  final DateTime targetDate;
  final List<String> notes;
  final Color backgroundColor;
  final String? backgroundImageUrl;
  final int sortIndex;
  final IconData? icon;
  final Color? iconColor;

  MemorialDay({
    String? id,
    required this.title,
    required this.targetDate,
    DateTime? creationDate,
    List<String>? notes,
    Color? backgroundColor,
    this.backgroundImageUrl,
    int? sortIndex,
    this.icon,
    this.iconColor,
  }) : id = id ?? const Uuid().v4(),
       creationDate = creationDate ?? DateTime.now(),
       notes = notes ?? [],
       backgroundColor = backgroundColor ?? _getRandomColor(),
       sortIndex = sortIndex ?? 0;

  // 计算剩余天数
  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return target.difference(today).inDays;
  }

  // 判断是否已经过期
  bool get isExpired => daysRemaining < 0;

  // 计算已经过去的天数（如果已过期）
  int get daysPassed => isExpired ? -daysRemaining : 0;

  // 计算纪念日是否在今天
  bool get isToday => daysRemaining == 0;

  // 获取格式化的日期字符串
  String get formattedTargetDate {
    return '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
  }

  // 从JSON创建实例
  factory MemorialDay.fromJson(Map<String, dynamic> json) {
    return MemorialDay(
      id: json['id'],
      title: json['title'],
      creationDate: DateTime.parse(json['creationDate']),
      targetDate: DateTime.parse(json['targetDate']),
      notes: List<String>.from(json['notes'] ?? []),
      backgroundColor: Color(json['backgroundColor']),
      backgroundImageUrl: json['backgroundImageUrl'],
      sortIndex: json['sortIndex'] ?? 0,
      icon:
          json['icon'] != null
              ? IconData(json['icon'], fontFamily: 'MaterialIcons')
              : null,
      iconColor: json['iconColor'] != null ? Color(json['iconColor']) : null,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'creationDate': creationDate.toIso8601String(),
      'targetDate': targetDate.toIso8601String(),
      'notes': notes,
      // ignore: deprecated_member_use
      'backgroundColor': backgroundColor.value,
      'backgroundImageUrl': backgroundImageUrl,
      'sortIndex': sortIndex,
      'icon': icon?.codePoint,
      'iconColor': iconColor?.value,
    };
  }

  // 生成随机颜色
  static Color _getRandomColor() {
    final random = Random();
    final colors = [
      Colors.red[300],
      Colors.pink[300],
      Colors.purple[300],
      Colors.deepPurple[300],
      Colors.indigo[300],
      Colors.blue[300],
      Colors.lightBlue[300],
      Colors.cyan[300],
      Colors.teal[300],
      Colors.green[300],
      Colors.lightGreen[300],
      Colors.amber[300],
      Colors.orange[300],
    ];
    return colors[random.nextInt(colors.length)]!;
  }

  // 创建带有修改的副本
  MemorialDay copyWith({
    String? id,
    String? title,
    DateTime? targetDate,
    List<String>? notes,
    Color? backgroundColor,
    String? backgroundImageUrl,
    int? sortIndex,
    IconData? icon,
    Color? iconColor,
  }) {
    return MemorialDay(
      id: id ?? this.id,
      title: title ?? this.title,
      creationDate: creationDate,
      targetDate: targetDate ?? this.targetDate,
      notes: notes ?? this.notes,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      sortIndex: sortIndex ?? this.sortIndex,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
    );
  }

  // 创建测试数据
  static List<MemorialDay> generateTestData() {
    final now = DateTime.now();
    final random = Random();

    return [
      MemorialDay(
        title: '新年倒计时',
        targetDate: DateTime(now.year + 1, 1, 1),
        notes: ['准备跨年活动', '购买礼物'],
      ),
      MemorialDay(
        title: '生日',
        targetDate: DateTime(now.year, now.month + 2, 15),
        notes: ['准备派对', '邀请朋友'],
      ),
      MemorialDay(
        title: '毕业纪念日',
        targetDate: DateTime(now.year - 2, 6, 30),
        notes: ['已经毕业两年了'],
      ),
      MemorialDay(
        title: '结婚纪念日',
        targetDate: DateTime(now.year, now.month, now.day + random.nextInt(10)),
        notes: ['准备惊喜', '订餐厅'],
      ),
      MemorialDay(
        title: '项目截止日',
        targetDate: DateTime(now.year, now.month, now.day + random.nextInt(30)),
        notes: ['完成文档', '准备演示'],
      ),
    ];
  }
}
