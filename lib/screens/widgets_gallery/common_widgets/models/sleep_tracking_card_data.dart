import 'dart:convert';

/// 周睡眠数据模型
///
/// 用于表示一周中某一天的睡眠数据
class DaySleepData {
  final String day;
  final bool achieved;
  final double progress;

  const DaySleepData({
    required this.day,
    required this.achieved,
    required this.progress,
  });

  /// 从 JSON 创建
  factory DaySleepData.fromJson(Map<String, dynamic> json) {
    return DaySleepData(
      day: json['day'] as String,
      achieved: json['achieved'] as bool,
      progress: (json['progress'] as num).toDouble(),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'achieved': achieved,
      'progress': progress,
    };
  }

  /// 从列表创建
  static List<DaySleepData> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((json) => DaySleepData.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 转换为 JSON 列表
  static List<Map<String, dynamic>> listToJson(List<DaySleepData> data) {
    return data.map((item) => item.toJson()).toList();
  }

  /// 复制并修改
  DaySleepData copyWith({
    String? day,
    bool? achieved,
    double? progress,
  }) {
    return DaySleepData(
      day: day ?? this.day,
      achieved: achieved ?? this.achieved,
      progress: progress ?? this.progress,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DaySleepData &&
        other.day == day &&
        other.achieved == achieved &&
        other.progress == progress;
  }

  @override
  int get hashCode => day.hashCode ^ achieved.hashCode ^ progress.hashCode;
}

/// 睡眠追踪卡片数据模型
///
/// 用于睡眠追踪卡片的配置和数据序列化
class SleepTrackingCardData {
  /// 睡眠时长（小时）
  final double sleepHours;

  /// 睡眠标签（如 'Good Sleep', 'Insomniac'）
  final String sleepLabel;

  /// 周进度数据列表（7天）
  final List<DaySleepData> weeklyProgress;

  /// 卡片标题，默认为 'Sleep'
  final String title;

  /// 右上角操作标签，默认为 'Today'
  final String actionLabel;

  /// 主色调（十六进制颜色字符串），默认使用主题色
  final String? primaryColor;

  const SleepTrackingCardData({
    required this.sleepHours,
    required this.sleepLabel,
    required this.weeklyProgress,
    this.title = 'Sleep',
    this.actionLabel = 'Today',
    this.primaryColor,
  });

  /// 从 JSON 创建
  factory SleepTrackingCardData.fromJson(Map<String, dynamic> json) {
    return SleepTrackingCardData(
      sleepHours: (json['sleepHours'] as num).toDouble(),
      sleepLabel: json['sleepLabel'] as String,
      weeklyProgress: DaySleepData.listFromJson(
        json['weeklyProgress'] as List<dynamic>,
      ),
      title: json['title'] as String? ?? 'Sleep',
      actionLabel: json['actionLabel'] as String? ?? 'Today',
      primaryColor: json['primaryColor'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'sleepHours': sleepHours,
      'sleepLabel': sleepLabel,
      'weeklyProgress': DaySleepData.listToJson(weeklyProgress),
      'title': title,
      'actionLabel': actionLabel,
      if (primaryColor != null) 'primaryColor': primaryColor,
    };
  }

  /// 转换为 JSON 字符串
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// 从 JSON 字符串创建
  factory SleepTrackingCardData.fromJsonString(String jsonString) {
    return SleepTrackingCardData.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  /// 复制并修改
  SleepTrackingCardData copyWith({
    double? sleepHours,
    String? sleepLabel,
    List<DaySleepData>? weeklyProgress,
    String? title,
    String? actionLabel,
    String? primaryColor,
  }) {
    return SleepTrackingCardData(
      sleepHours: sleepHours ?? this.sleepHours,
      sleepLabel: sleepLabel ?? this.sleepLabel,
      weeklyProgress: weeklyProgress ?? this.weeklyProgress,
      title: title ?? this.title,
      actionLabel: actionLabel ?? this.actionLabel,
      primaryColor: primaryColor ?? this.primaryColor,
    );
  }

  /// 创建默认数据
  static SleepTrackingCardData createDefault() {
    return SleepTrackingCardData(
      sleepHours: 7.5,
      sleepLabel: 'Good Sleep',
      weeklyProgress: [
        DaySleepData(day: 'M', achieved: true, progress: 1.0),
        DaySleepData(day: 'T', achieved: false, progress: 0.68),
        DaySleepData(day: 'W', achieved: true, progress: 1.0),
        DaySleepData(day: 'T', achieved: true, progress: 0.92),
        DaySleepData(day: 'F', achieved: false, progress: 0.6),
        DaySleepData(day: 'S', achieved: false, progress: 0.76),
        DaySleepData(day: 'S', achieved: true, progress: 1.0),
      ],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SleepTrackingCardData &&
        other.sleepHours == sleepHours &&
        other.sleepLabel == sleepLabel &&
        _listEquals(other.weeklyProgress, weeklyProgress) &&
        other.title == title &&
        other.actionLabel == actionLabel &&
        other.primaryColor == primaryColor;
  }

  @override
  int get hashCode {
    return sleepHours.hashCode ^
        sleepLabel.hashCode ^
        weeklyProgress.hashCode ^
        title.hashCode ^
        actionLabel.hashCode ^
        primaryColor.hashCode;
  }

  /// 列表相等性辅助方法
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'SleepTrackingCardData('
        'sleepHours: $sleepHours, '
        'sleepLabel: $sleepLabel, '
        'title: $title, '
        'actionLabel: $actionLabel, '
        'weeklyProgress: [${weeklyProgress.length} days])';
  }
}
