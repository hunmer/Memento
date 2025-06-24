import 'package:flutter/material.dart';

/// 时间线筛选器，用于筛选消息列表
class TimelineFilter {
  /// 筛选器类型
  final TimelineFilterType type;

  /// 筛选器标题
  final String title;

  /// 筛选器图标
  final IconData icon;

  /// 筛选器颜色
  final Color color;

  /// 筛选器描述
  final String description;

  /// 搜索范围 - 是否包含频道名称
  bool includeChannels;

  /// 搜索范围 - 是否包含用户名
  bool includeUsernames;

  /// 搜索范围 - 是否包含消息内容
  bool includeContent;

  /// 筛选开始日期
  DateTime? startDate;

  /// 筛选结束日期
  DateTime? endDate;

  /// 选中的频道ID列表
  Set<String> selectedChannelIds;

  /// 选中的用户ID列表
  Set<String> selectedUserIds;

  /// 是否筛选AI消息
  bool? isAI;

  /// 是否筛选收藏消息
  bool? isFavorite;

  /// 创建一个时间线筛选器
  TimelineFilter({
    required this.type,
    required this.title,
    required this.icon,
    this.color = Colors.blue,
    this.description = '',
    this.includeChannels = true,
    this.includeUsernames = true,
    this.includeContent = true,
    this.startDate,
    this.endDate,
    Set<String>? selectedChannelIds,
    Set<String>? selectedUserIds,
    this.isAI,
    this.isFavorite,
  }) : selectedChannelIds = selectedChannelIds ?? {},
       selectedUserIds = selectedUserIds ?? {};

  /// 创建一个筛选器的副本，但可以更改某些属性
  TimelineFilter copyWith({
    TimelineFilterType? type,
    String? title,
    IconData? icon,
    Color? color,
    String? description,
    bool? includeChannels,
    bool? includeUsernames,
    bool? includeContent,
    DateTime? startDate,
    DateTime? endDate,
    Set<String>? selectedChannelIds,
    Set<String>? selectedUserIds,
    bool? isAI,
    bool? isFavorite,
  }) {
    return TimelineFilter(
      type: type ?? this.type,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      description: description ?? this.description,
      includeChannels: includeChannels ?? this.includeChannels,
      includeUsernames: includeUsernames ?? this.includeUsernames,
      includeContent: includeContent ?? this.includeContent,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedChannelIds:
          selectedChannelIds ?? Set.from(this.selectedChannelIds),
      selectedUserIds: selectedUserIds ?? Set.from(this.selectedUserIds),
      isAI: isAI ?? this.isAI,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// 从另一个筛选器更新属性
  void updateFrom(TimelineFilter other) {
    // 更新可变属性
    includeChannels = other.includeChannels;
    includeUsernames = other.includeUsernames;
    includeContent = other.includeContent;
    startDate = other.startDate;
    endDate = other.endDate;
    selectedChannelIds = Set.from(other.selectedChannelIds);
    selectedUserIds = Set.from(other.selectedUserIds);
    isAI = other.isAI;
    isFavorite = other.isFavorite;
  }

  /// 重置筛选器为默认状态
  void reset() {
    includeChannels = true;
    includeUsernames = true;
    includeContent = true;
    startDate = null;
    endDate = null;
    selectedChannelIds.clear();
    selectedUserIds.clear();
    isAI = null;
    isFavorite = null;
  }
}

/// 时间线筛选器类型
enum TimelineFilterType {
  /// 全部消息
  all,

  /// 仅显示文本消息
  text,

  /// 仅显示图片消息
  image,

  /// 仅显示文件消息
  file,

  /// 仅显示系统消息
  system,

  /// 仅显示特定日期范围的消息
  dateRange,

  /// 仅显示特定用户的消息
  user,

  /// 自定义筛选条件
  custom,
}
