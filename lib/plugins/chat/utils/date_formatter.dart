import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DateFormatter {
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  static String formatDateTime(DateTime dateTime, BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'chat_justNow'.tr;
    } else if (difference.inHours < 1) {
      return 'chat_minutesAgo'.trParams({'minutes': difference.inMinutes.toString()});
    } else if (difference.inDays < 1) {
      return 'chat_hoursAgo'.trParams({'hours': difference.inHours.toString()});
    } else if (difference.inDays < 7) {
      return 'chat_daysAgo'.trParams({'days': difference.inDays.toString()});
    } else {
      final DateFormat formatter = DateFormat('MM-dd HH:mm');
      return formatter.format(dateTime);
    }
  }
  
  static String formatDate(DateTime date, [BuildContext? context]) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return 'chat_today'.tr;
    } else if (dateDay == yesterday) {
      return 'chat_yesterday'.tr;
    } else if (date.year == now.year) {
      // 如果是今年，只显示月份和日期
      return DateFormat('MM-dd').format(date);
    } else {
      // 如果不是今年，显示年份、月份和日期
      return DateFormat('yyyy-MM-dd').format(date);
    }
  }
}