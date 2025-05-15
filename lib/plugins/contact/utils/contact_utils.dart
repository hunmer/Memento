import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ContactUtils {
  // 格式化电话号码
  static String formatPhoneNumber(String phone) {
    if (phone.length != 11) return phone;
    return '${phone.substring(0, 3)}-${phone.substring(3, 7)}-${phone.substring(7)}';
  }

  // 格式化日期
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // 格式化日期和时间
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  // 获取自上次联系以来的时间描述
  static String getTimeSinceLastContact(DateTime lastContactTime) {
    final now = DateTime.now();
    final difference = now.difference(lastContactTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}年前';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}月前';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  // 验证手机号
  static bool isValidPhoneNumber(String phone) {
    // 简单的中国手机号验证
    return RegExp(r'^1[3-9]\\d{9}$').hasMatch(phone);
  }

  // 获取联系人标签的颜色
  static Color getTagColor(String tag) {
    final Map<String, Color> tagColors = {
      '家人': Colors.red,
      '朋友': Colors.blue,
      '同事': Colors.green,
      '客户': Colors.orange,
      '重要': Colors.purple,
    };

    return tagColors[tag] ?? Colors.grey;
  }

  // 获取联系类型的图标
  static IconData getInteractionTypeIcon(String type) {
    final Map<String, IconData> typeIcons = {
      '电话': Icons.phone,
      '见面': Icons.person,
      '邮件': Icons.email,
      '短信': Icons.sms,
      '视频': Icons.video_call,
    };

    return typeIcons[type] ?? Icons.contact_page;
  }
}