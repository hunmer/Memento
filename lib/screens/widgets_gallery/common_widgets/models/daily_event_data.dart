import 'dart:convert';

/// 每日事件数据模型
///
/// 用于表示单个日程事件的数据
class DailyEventData {
  final String title;
  final String time;
  final int colorValue;
  final int backgroundColorLightValue;
  final int backgroundColorDarkValue;
  final int textColorLightValue;
  final int textColorDarkValue;
  final int subtextLightValue;
  final int subtextDarkValue;

  const DailyEventData({
    required this.title,
    required this.time,
    required this.colorValue,
    required this.backgroundColorLightValue,
    required this.backgroundColorDarkValue,
    required this.textColorLightValue,
    required this.textColorDarkValue,
    required this.subtextLightValue,
    required this.subtextDarkValue,
  });

  /// 从 JSON 创建
  factory DailyEventData.fromJson(Map<String, dynamic> json) {
    return DailyEventData(
      title: json['title'] as String,
      time: json['time'] as String,
      colorValue: json['colorValue'] as int,
      backgroundColorLightValue: json['backgroundColorLightValue'] as int,
      backgroundColorDarkValue: json['backgroundColorDarkValue'] as int,
      textColorLightValue: json['textColorLightValue'] as int,
      textColorDarkValue: json['textColorDarkValue'] as int,
      subtextLightValue: json['subtextLightValue'] as int,
      subtextDarkValue: json['subtextDarkValue'] as int,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'time': time,
      'colorValue': colorValue,
      'backgroundColorLightValue': backgroundColorLightValue,
      'backgroundColorDarkValue': backgroundColorDarkValue,
      'textColorLightValue': textColorLightValue,
      'textColorDarkValue': textColorDarkValue,
      'subtextLightValue': subtextLightValue,
      'subtextDarkValue': subtextDarkValue,
    };
  }

  /// 从列表创建
  static List<DailyEventData> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((json) => DailyEventData.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 转换为 JSON 列表
  static List<Map<String, dynamic>> listToJson(List<DailyEventData> data) {
    return data.map((item) => item.toJson()).toList();
  }

  /// 复制并修改
  DailyEventData copyWith({
    String? title,
    String? time,
    int? colorValue,
    int? backgroundColorLightValue,
    int? backgroundColorDarkValue,
    int? textColorLightValue,
    int? textColorDarkValue,
    int? subtextLightValue,
    int? subtextDarkValue,
  }) {
    return DailyEventData(
      title: title ?? this.title,
      time: time ?? this.time,
      colorValue: colorValue ?? this.colorValue,
      backgroundColorLightValue: backgroundColorLightValue ?? this.backgroundColorLightValue,
      backgroundColorDarkValue: backgroundColorDarkValue ?? this.backgroundColorDarkValue,
      textColorLightValue: textColorLightValue ?? this.textColorLightValue,
      textColorDarkValue: textColorDarkValue ?? this.textColorDarkValue,
      subtextLightValue: subtextLightValue ?? this.subtextLightValue,
      subtextDarkValue: subtextDarkValue ?? this.subtextDarkValue,
    );
  }

  /// 创建默认事件数据
  static DailyEventData createDefault({int index = 0}) {
    // 提供几种预设颜色方案
    final schemes = [
      _ColorScheme(
        color: 0xFFE8A546,
        backgroundColorLight: 0xFFFFF9F0,
        backgroundColorDark: 0xFF3d342b,
        textColorLight: 0xFF5D4037,
        textColorDark: 0xFFFFE0B2,
        subtextLight: 0xFF8D6E63,
        subtextDark: 0xFFD7CCC8,
      ),
      _ColorScheme(
        color: 0xFF7ED321,
        backgroundColorLight: 0xFFF0FFF0,
        backgroundColorDark: 0xFF1e3322,
        textColorLight: 0xFF2E7D32,
        textColorDark: 0xFFA5D6A7,
        subtextLight: 0xFF66BB6A,
        subtextDark: 0xFF81C784,
      ),
      _ColorScheme(
        color: 0xFF5C6BC0,
        backgroundColorLight: 0xFFE8EAF6,
        backgroundColorDark: 0xFF1A237E,
        textColorLight: 0xFF283593,
        textColorDark: 0xFF9FA8DA,
        subtextLight: 0xFF5C6BC0,
        subtextDark: 0xFF7986CB,
      ),
    ];

    final scheme = schemes[index % schemes.length];
    return DailyEventData(
      title: index == 0 ? 'Farmers Market' : 'Weekly Prep',
      time: index == 0 ? '9:45-11:00AM' : '11:15-1:00PM',
      colorValue: scheme.color,
      backgroundColorLightValue: scheme.backgroundColorLight,
      backgroundColorDarkValue: scheme.backgroundColorDark,
      textColorLightValue: scheme.textColorLight,
      textColorDarkValue: scheme.textColorDark,
      subtextLightValue: scheme.subtextLight,
      subtextDarkValue: scheme.subtextDark,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DailyEventData &&
        other.title == title &&
        other.time == time &&
        other.colorValue == colorValue &&
        other.backgroundColorLightValue == backgroundColorLightValue &&
        other.backgroundColorDarkValue == backgroundColorDarkValue &&
        other.textColorLightValue == textColorLightValue &&
        other.textColorDarkValue == textColorDarkValue &&
        other.subtextLightValue == subtextLightValue &&
        other.subtextDarkValue == subtextDarkValue;
  }

  @override
  int get hashCode {
    return title.hashCode ^
        time.hashCode ^
        colorValue.hashCode ^
        backgroundColorLightValue.hashCode ^
        backgroundColorDarkValue.hashCode ^
        textColorLightValue.hashCode ^
        textColorDarkValue.hashCode ^
        subtextLightValue.hashCode ^
        subtextDarkValue.hashCode;
  }

  @override
  String toString() {
    return 'DailyEventData(title: $title, time: $time)';
  }
}

/// 颜色方案辅助类
class _ColorScheme {
  final int color;
  final int backgroundColorLight;
  final int backgroundColorDark;
  final int textColorLight;
  final int textColorDark;
  final int subtextLight;
  final int subtextDark;

  const _ColorScheme({
    required this.color,
    required this.backgroundColorLight,
    required this.backgroundColorDark,
    required this.textColorLight,
    required this.textColorDark,
    required this.subtextLight,
    required this.subtextDark,
  });
}

/// 每日事件卡片数据模型
///
/// 用于每日事件卡片的配置和数据序列化
class DailyEventsCardData {
  /// 星期标签
  final String weekday;

  /// 日期（几号）
  final int day;

  /// 事件列表
  final List<DailyEventData> events;

  const DailyEventsCardData({
    required this.weekday,
    required this.day,
    required this.events,
  });

  /// 从 JSON 创建
  factory DailyEventsCardData.fromJson(Map<String, dynamic> json) {
    return DailyEventsCardData(
      weekday: json['weekday'] as String,
      day: json['day'] as int,
      events: DailyEventData.listFromJson(json['events'] as List<dynamic>),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'weekday': weekday,
      'day': day,
      'events': DailyEventData.listToJson(events),
    };
  }

  /// 转换为 JSON 字符串
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// 从 JSON 字符串创建
  factory DailyEventsCardData.fromJsonString(String jsonString) {
    return DailyEventsCardData.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  /// 复制并修改
  DailyEventsCardData copyWith({
    String? weekday,
    int? day,
    List<DailyEventData>? events,
  }) {
    return DailyEventsCardData(
      weekday: weekday ?? this.weekday,
      day: day ?? this.day,
      events: events ?? this.events,
    );
  }

  /// 创建默认数据
  static DailyEventsCardData createDefault() {
    return DailyEventsCardData(
      weekday: 'Monday',
      day: 7,
      events: [
        DailyEventData.createDefault(index: 0),
        DailyEventData.createDefault(index: 1),
      ],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DailyEventsCardData &&
        other.weekday == weekday &&
        other.day == day &&
        _listEquals(other.events, events);
  }

  @override
  int get hashCode {
    return weekday.hashCode ^ day.hashCode ^ events.hashCode;
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
    return 'DailyEventsCardData(weekday: $weekday, day: $day, events: [${events.length}])';
  }
}
