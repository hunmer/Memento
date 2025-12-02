/// 习惯周视图小组件配置模型
class HabitsWeeklyWidgetConfig {
  final int widgetId;
  final List<String> selectedHabitIds; // 选中的习惯ID列表
  final String backgroundColor; // 颜色用String存储
  final String accentColor;
  final double opacity;
  final int weekOffset; // 周偏移量(0=当前周)

  const HabitsWeeklyWidgetConfig({
    required this.widgetId,
    required this.selectedHabitIds,
    required this.backgroundColor,
    required this.accentColor,
    required this.opacity,
    required this.weekOffset,
  });

  Map<String, dynamic> toMap() {
    return {
      'widgetId': widgetId,
      'selectedHabitIds': selectedHabitIds,
      'backgroundColor': backgroundColor,
      'accentColor': accentColor,
      'opacity': opacity,
      'weekOffset': weekOffset,
    };
  }

  factory HabitsWeeklyWidgetConfig.fromMap(Map<String, dynamic> map) {
    return HabitsWeeklyWidgetConfig(
      widgetId: map['widgetId'] as int,
      selectedHabitIds: List<String>.from(map['selectedHabitIds'] as List),
      backgroundColor: map['backgroundColor'] as String,
      accentColor: map['accentColor'] as String,
      opacity: (map['opacity'] as num).toDouble(),
      weekOffset: map['weekOffset'] as int? ?? 0,
    );
  }

  HabitsWeeklyWidgetConfig copyWith({
    int? widgetId,
    List<String>? selectedHabitIds,
    String? backgroundColor,
    String? accentColor,
    double? opacity,
    int? weekOffset,
  }) {
    return HabitsWeeklyWidgetConfig(
      widgetId: widgetId ?? this.widgetId,
      selectedHabitIds: selectedHabitIds ?? this.selectedHabitIds,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      accentColor: accentColor ?? this.accentColor,
      opacity: opacity ?? this.opacity,
      weekOffset: weekOffset ?? this.weekOffset,
    );
  }
}
