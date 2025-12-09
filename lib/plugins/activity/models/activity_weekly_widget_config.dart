import 'package:flutter/material.dart';

/// 周视图小组件配置模型
///
/// 用于存储小组件的个性化配置，包括颜色、透明度和周偏移量
class ActivityWeeklyWidgetConfig {
  final int widgetId;
  final Color backgroundColor;
  final Color accentColor;
  final double opacity;
  final int currentWeekOffset; // 0=本周，-1=上周，1=下周

  ActivityWeeklyWidgetConfig({
    required this.widgetId,
    required this.backgroundColor,
    required this.accentColor,
    this.opacity = 0.95,
    this.currentWeekOffset = 0,
  });

  /// 序列化为JSON（颜色转为字符串存储）
  Map<String, dynamic> toJson() {
    return {
      'widgetId': widgetId,
      'backgroundColor': backgroundColor.value.toString(),
      'accentColor': accentColor.value.toString(),
      'opacity': opacity,
      'currentWeekOffset': currentWeekOffset,
    };
  }

  /// 从JSON反序列化
  factory ActivityWeeklyWidgetConfig.fromJson(Map<String, dynamic> json) {
    Color? parseColor(dynamic colorStr) {
      if (colorStr == null) return null;
      try {
        final colorValue = colorStr.toString().toLongOrNull()?.toInt();
        return colorValue != null ? Color(colorValue) : null;
      } catch (e) {
        debugPrint('解析颜色失败: $e');
        return null;
      }
    }

    return ActivityWeeklyWidgetConfig(
      widgetId: json['widgetId'] as int,
      backgroundColor: parseColor(json['backgroundColor']) ?? const Color(0xFFEFF7F0),
      accentColor: parseColor(json['accentColor']) ?? const Color(0xFF607afb),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.95,
      currentWeekOffset: json['currentWeekOffset'] as int? ?? 0,
    );
  }

  /// 复制对象并允许修改部分字段
  ActivityWeeklyWidgetConfig copyWith({
    int? widgetId,
    Color? backgroundColor,
    Color? accentColor,
    double? opacity,
    int? currentWeekOffset,
  }) {
    return ActivityWeeklyWidgetConfig(
      widgetId: widgetId ?? this.widgetId,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      accentColor: accentColor ?? this.accentColor,
      opacity: opacity ?? this.opacity,
      currentWeekOffset: currentWeekOffset ?? this.currentWeekOffset,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ActivityWeeklyWidgetConfig &&
        other.widgetId == widgetId &&
        other.backgroundColor.value == backgroundColor.value &&
        other.accentColor.value == accentColor.value &&
        other.opacity == opacity &&
        other.currentWeekOffset == currentWeekOffset;
  }

  @override
  int get hashCode {
    return widgetId.hashCode ^
        backgroundColor.value.hashCode ^
        accentColor.value.hashCode ^
        opacity.hashCode ^
        currentWeekOffset.hashCode;
  }
}

/// String转long的扩展方法
extension StringToLong on String {
  int? toLongOrNull() {
    try {
      return int.parse(this);
    } catch (e) {
      return null;
    }
  }
}
