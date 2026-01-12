/// 时间线状态卡片数据模型
/// 用于显示时间线进度和状态信息
class TimelineStatusCardData {
  /// 位置名称
  final String location;

  /// 主标题
  final String title;

  /// 描述文本
  final String description;

  /// 进度百分比 (0.0 - 1.0)
  final double progressPercent;

  /// 当前时间标签
  final String currentTimeLabel;

  /// 时间标签列表
  final List<String> timeLabels;

  const TimelineStatusCardData({
    required this.location,
    required this.title,
    required this.description,
    required this.progressPercent,
    required this.currentTimeLabel,
    this.timeLabels = const [],
  });

  /// 从 JSON 创建
  factory TimelineStatusCardData.fromJson(Map<String, dynamic> json) {
    return TimelineStatusCardData(
      location: json['location'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0.0,
      currentTimeLabel: json['currentTimeLabel'] as String? ?? '',
      timeLabels: (json['timeLabels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'title': title,
      'description': description,
      'progressPercent': progressPercent,
      'currentTimeLabel': currentTimeLabel,
      'timeLabels': timeLabels,
    };
  }
}
