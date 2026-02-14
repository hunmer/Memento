/// Agent Chat 插件主页小组件工具函数
library;

import 'package:get/get.dart';

/// 格式化时间显示
String formatDateTime(DateTime? dateTime) {
  if (dateTime == null) {
    return '';
  }
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) {
    return 'agent_chat_justNow'.tr;
  } else if (difference.inHours < 1) {
    return 'agent_chat_minutesAgo'.trParams({
      'count': '${difference.inMinutes}',
    });
  } else if (difference.inDays < 1) {
    return 'agent_chat_hoursAgo'.trParams({'count': '${difference.inHours}'});
  } else if (difference.inDays < 7) {
    return 'agent_chat_daysAgo'.trParams({'count': '${difference.inDays}'});
  } else {
    return '${dateTime.month}/${dateTime.day}';
  }
}
