/// 聊天插件 - 主页小组件工具函数
///
/// 提供时间格式化等工具函数
library;

import 'package:get/get.dart';

/// 格式化时间显示
///
/// 根据时间差返回友好的时间字符串
String formatDateTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) {
    return 'chat_justNow'.tr;
  } else if (difference.inHours < 1) {
    return 'chat_minutesAgo'.trParams({'minutes': '${difference.inMinutes}'});
  } else if (difference.inDays < 1) {
    return 'chat_hoursAgo'.trParams({'hours': '${difference.inHours}'});
  } else if (difference.inDays < 7) {
    return 'chat_daysAgo'.trParams({'days': '${difference.inDays}'});
  } else {
    return '${dateTime.month}/${dateTime.day}';
  }
}
