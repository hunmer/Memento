
/// 时间线过滤器设置
class TimelineFilter {
  // 搜索范围设置
  bool includeChannels;
  bool includeUsernames;
  bool includeContent;
  bool? isAI;
  bool? isFavorite;

  // 日期范围
  DateTime? startDate;
  DateTime? endDate;

  // 选中的频道和用户
  Set<String> selectedChannelIds;
  Set<String> selectedUserIds;

  TimelineFilter({
    this.includeChannels = true,
    this.includeUsernames = true,
    this.includeContent = true,
    this.isAI,
    this.isFavorite,
    this.startDate,
    this.endDate,
    Set<String>? selectedChannelIds,
    Set<String>? selectedUserIds,
  })  : selectedChannelIds = selectedChannelIds ?? {},
        selectedUserIds = selectedUserIds ?? {};

  // 创建过滤器的副本
  TimelineFilter copyWith({
    bool? includeChannels,
    bool? includeUsernames,
    bool? includeContent,
    bool? isAI,
    bool? isFavorite,
    DateTime? startDate,
    DateTime? endDate,
    Set<String>? selectedChannelIds,
    Set<String>? selectedUserIds,
  }) {
    return TimelineFilter(
      includeChannels: includeChannels ?? this.includeChannels,
      includeUsernames: includeUsernames ?? this.includeUsernames,
      includeContent: includeContent ?? this.includeContent,
      isAI: isAI ?? this.isAI,
      isFavorite: isFavorite ?? this.isFavorite,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedChannelIds: selectedChannelIds ?? this.selectedChannelIds,
      selectedUserIds: selectedUserIds ?? this.selectedUserIds,
    );
  }

  // 重置过滤器
  void reset() {
    includeChannels = true;
    includeUsernames = true;
    includeContent = true;
    isAI = null;
    isFavorite = null;
    startDate = null;
    endDate = null;
    selectedChannelIds.clear();
    selectedUserIds.clear();
  }
}