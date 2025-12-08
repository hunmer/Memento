import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Memento/plugins/chat/l10n/chat_localizations.dart';

class DateFormatter {
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  static String formatDateTime(DateTime dateTime, BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // 尝试获取本地化实例，如果不可用则使用默认文本
    final l10n = ChatLocalizations.of(context);
    if (l10n != null) {
      if (difference.inMinutes < 1) {
        return l10n.justNow;
      } else if (difference.inHours < 1) {
        return l10n.minutesAgo(difference.inMinutes);
      } else if (difference.inDays < 1) {
        return l10n.hoursAgo(difference.inHours);
      } else if (difference.inDays < 7) {
        return l10n.daysAgo(difference.inDays);
      }
    }
    
    // 如果本地化不可用或者超过7天，使用标准格式
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
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
    
    if (context != null) {
      final l10n = ChatLocalizations.of(context);
      if (l10n != null) {
        if (dateDay == today) {
          return l10n.today;
        } else if (dateDay == yesterday) {
          return l10n.yesterday;
        }
      }
    }
    
    if (dateDay == today) {
      return '今天';
    } else if (dateDay == yesterday) {
      return '昨天';
    } else if (date.year == now.year) {
      // 如果是今年，只显示月份和日期
      return DateFormat('MM-dd').format(date);
    } else {
      // 如果不是今年，显示年份、月份和日期
      return DateFormat('yyyy-MM-dd').format(date);
    }
  }
}