import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DayDateUtils {
  // 格式化日期为 YYYY-MM-DD
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // 格式化日期为本地化格式
  static String formatDateLocalized(DateTime date, Locale locale) {
    return DateFormat.yMMMMd(locale.languageCode).format(date);
  }

  // 计算两个日期之间的天数
  static int daysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return toDate.difference(fromDate).inDays;
  }

  // 判断日期是否为今天
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // 判断日期是否为过去
  static bool isPast(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compareDate = DateTime(date.year, date.month, date.day);
    return compareDate.isBefore(today);
  }

  // 判断日期是否为未来
  static bool isFuture(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compareDate = DateTime(date.year, date.month, date.day);
    return compareDate.isAfter(today);
  }

  // 获取下一个周年日期
  static DateTime getNextAnniversary(DateTime originalDate) {
    final now = DateTime.now();
    final anniversaryThisYear = DateTime(
      now.year,
      originalDate.month,
      originalDate.day,
    );
    
    if (anniversaryThisYear.isBefore(now) || 
        (anniversaryThisYear.day == now.day && 
         anniversaryThisYear.month == now.month)) {
      // 如果今年的周年已过，返回明年的周年
      return DateTime(
        now.year + 1,
        originalDate.month,
        originalDate.day,
      );
    } else {
      // 否则返回今年的周年
      return anniversaryThisYear;
    }
  }
}