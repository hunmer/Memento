/// 联系人插件主页小组件工具函数
library;

import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;

/// 格式化最后联系时间
String formatLastContactTime(DateTime lastContactTime) {
  final now = DateTime.now();
  final difference = now.difference(lastContactTime);

  if (difference.inDays == 0) {
    return 'contact_today'.tr;
  } else if (difference.inDays == 1) {
    return 'contact_yesterday'.tr;
  } else if (difference.inDays < 7) {
    return 'contact_daysAgo'.trParams({'days': '${difference.inDays}'});
  } else {
    return timeago.format(lastContactTime, locale: 'zh_CN');
  }
}
