/// 日历相册插件主页小组件数据模型

import '../models/calendar_entry.dart';

/// 图片项数据类
class PhotoItem {
  /// 图片URL（相对路径）
  final String imageUrl;
  /// 关联的日记条目
  final CalendarEntry entry;
  /// 日期（已标准化）
  final DateTime date;

  const PhotoItem({
    required this.imageUrl,
    required this.entry,
    required this.date,
  });
}
