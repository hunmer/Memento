/// 日历相册插件主页小组件工具函数
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 获取当前周的周一到周日日期列表
List<DateTime> getCurrentWeekDays(DateTime date) {
  final normalizedDate = DateTime(date.year, date.month, date.day);
  // Monday = 1, Sunday = 7
  final weekday = normalizedDate.weekday;
  // 计算周一
  final monday = normalizedDate.subtract(Duration(days: weekday - 1));
  // 生成周一到周日的日期列表
  return List.generate(7, (index) => monday.add(Duration(days: index)));
}

/// 检查两个日期是否是同一天
bool isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;
}

/// 格式化星期几（中文）
String formatWeekday(DateTime date) {
  final format = DateFormat.E('zh');
  return format.format(date);
}

/// 格式化日期数字
String formatDay(DateTime date) {
  final format = DateFormat.d();
  return format.format(date);
}

/// 获取插件颜色
const Color pluginColor = Color.fromARGB(255, 245, 210, 52);
