import 'dart:convert';

/// 圆环进度项数据模型
///
/// 用于表示单个圆环进度项的数据
class CircularProgressItemData {
  final String day;
  final bool achieved;
  final double progress;

  const CircularProgressItemData({
    required this.day,
    required this.achieved,
    required this.progress,
  });

  /// 从 JSON 创建
  factory CircularProgressItemData.fromJson(Map<String, dynamic> json) {
    return CircularProgressItemData(
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
  static List<CircularProgressItemData> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((json) => CircularProgressItemData.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 转换为 JSON 列表
  static List<Map<String, dynamic>> listToJson(List<CircularProgressItemData> data) {
    return data.map((item) => item.toJson()).toList();
  }

  /// 复制并修改
  CircularProgressItemData copyWith({
    String? day,
    bool? achieved,
    double? progress,
  }) {
    return CircularProgressItemData(
      day: day ?? this.day,
      achieved: achieved ?? this.achieved,
      progress: progress ?? this.progress,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CircularProgressItemData &&
        other.day == day &&
        other.achieved == achieved &&
        other.progress == progress;
  }

  @override
  int get hashCode => day.hashCode ^ achieved.hashCode ^ progress.hashCode;
}

/// 垂直圆环进度卡片数据模型
///
/// 用于垂直圆环进度卡片的配置和数据序列化
class VerticalCircularProgressCardData {
  /// 主数值（如时长、数量等）
  final double mainValue;

  /// 状态标签（如 'Good', 'Excellent'）
  final String statusLabel;

  /// 周进度数据列表（7天）
  final List<CircularProgressItemData> weeklyProgress;

  /// 卡片标题，默认为 'Sleep'
  final String title;

  /// 右上角操作标签，默认为 'Today'
  final String actionLabel;

  /// 主色调（十六进制颜色字符串），默认使用主题色
  final String? primaryColor;

  /// 单位标签（如 'hr', '次', 'kg'），默认为 'hr'
  final String unit;

  const VerticalCircularProgressCardData({
    required this.mainValue,
    required this.statusLabel,
    required this.weeklyProgress,
    this.title = 'Progress',
    this.actionLabel = 'Today',
    this.primaryColor,
    this.unit = 'hr',
  });

  /// 从 JSON 创建
  factory VerticalCircularProgressCardData.fromJson(Map<String, dynamic> json) {
    return VerticalCircularProgressCardData(
      mainValue: (json['mainValue'] as num?)?.toDouble() ?? (json['sleepHours'] as num?)?.toDouble() ?? 0.0,
      statusLabel: json['statusLabel'] as String? ?? json['sleepLabel'] as String? ?? '',
      weeklyProgress: CircularProgressItemData.listFromJson(
        json['weeklyProgress'] as List<dynamic>? ?? [],
      ),
      title: json['title'] as String? ?? 'Progress',
      actionLabel: json['actionLabel'] as String? ?? 'Today',
      primaryColor: json['primaryColor'] as String?,
      unit: json['unit'] as String? ?? 'hr',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'mainValue': mainValue,
      'statusLabel': statusLabel,
      'weeklyProgress': CircularProgressItemData.listToJson(weeklyProgress),
      'title': title,
      'actionLabel': actionLabel,
      if (primaryColor != null) 'primaryColor': primaryColor,
      'unit': unit,
    };
  }

  /// 转换为 JSON 字符串
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// 从 JSON 字符串创建
  factory VerticalCircularProgressCardData.fromJsonString(String jsonString) {
    return VerticalCircularProgressCardData.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  /// 复制并修改
  VerticalCircularProgressCardData copyWith({
    double? mainValue,
    String? statusLabel,
    List<CircularProgressItemData>? weeklyProgress,
    String? title,
    String? actionLabel,
    String? primaryColor,
    String? unit,
  }) {
    return VerticalCircularProgressCardData(
      mainValue: mainValue ?? this.mainValue,
      statusLabel: statusLabel ?? this.statusLabel,
      weeklyProgress: weeklyProgress ?? this.weeklyProgress,
      title: title ?? this.title,
      actionLabel: actionLabel ?? this.actionLabel,
      primaryColor: primaryColor ?? this.primaryColor,
      unit: unit ?? this.unit,
    );
  }

  /// 创建默认数据
  static VerticalCircularProgressCardData createDefault() {
    return VerticalCircularProgressCardData(
      mainValue: 7.5,
      statusLabel: 'Good Sleep',
      weeklyProgress: [
        CircularProgressItemData(day: 'M', achieved: true, progress: 1.0),
        CircularProgressItemData(day: 'T', achieved: false, progress: 0.68),
        CircularProgressItemData(day: 'W', achieved: true, progress: 1.0),
        CircularProgressItemData(day: 'T', achieved: true, progress: 0.92),
        CircularProgressItemData(day: 'F', achieved: false, progress: 0.6),
        CircularProgressItemData(day: 'S', achieved: false, progress: 0.76),
        CircularProgressItemData(day: 'S', achieved: true, progress: 1.0),
      ],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VerticalCircularProgressCardData &&
        other.mainValue == mainValue &&
        other.statusLabel == statusLabel &&
        _listEquals(other.weeklyProgress, weeklyProgress) &&
        other.title == title &&
        other.actionLabel == actionLabel &&
        other.primaryColor == primaryColor;
  }

  @override
  int get hashCode {
    return mainValue.hashCode ^
        statusLabel.hashCode ^
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
    return 'VerticalCircularProgressCardData('
        'mainValue: $mainValue, '
        'statusLabel: $statusLabel, '
        'title: $title, '
        'actionLabel: $actionLabel, '
        'weeklyProgress: [${weeklyProgress.length} days])';
  }
}
