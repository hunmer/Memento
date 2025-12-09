import 'package:flutter/material.dart';
import 'color_config.dart';

/// 小组件配置容器
///
/// 包含颜色配置列表、背景透明度和扩展配置，
/// 提供颜色访问、更新和序列化方法。
class WidgetConfig {
  /// 颜色配置列表
  final List<ColorConfig> colors;

  /// 背景透明度 (0.0 - 1.0)
  final double opacity;

  /// 扩展配置（用于存储自定义数据）
  final Map<String, dynamic> extra;

  const WidgetConfig({
    required this.colors,
    this.opacity = 1.0,
    this.extra = const {},
  });

  /// 创建空配置
  factory WidgetConfig.empty() {
    return const WidgetConfig(
      colors: [],
      opacity: 1.0,
      extra: {},
    );
  }

  /// 获取指定 key 的颜色
  Color? getColor(String key) {
    try {
      return colors.firstWhere((c) => c.key == key).currentValue;
    } catch (_) {
      return null;
    }
  }

  /// 获取指定 key 的颜色配置
  ColorConfig? getColorConfig(String key) {
    try {
      return colors.firstWhere((c) => c.key == key);
    } catch (_) {
      return null;
    }
  }

  /// 更新指定 key 的颜色
  WidgetConfig updateColor(String key, Color color) {
    final updatedColors = colors.map((c) {
      if (c.key == key) {
        return c.copyWith(currentValue: color);
      }
      return c;
    }).toList();

    return WidgetConfig(
      colors: updatedColors,
      opacity: opacity,
      extra: extra,
    );
  }

  /// 重置所有颜色为默认值
  WidgetConfig resetColors() {
    final resetColors = colors.map((c) => c.reset()).toList();
    return WidgetConfig(
      colors: resetColors,
      opacity: opacity,
      extra: extra,
    );
  }

  /// 创建副本并更新属性
  WidgetConfig copyWith({
    List<ColorConfig>? colors,
    double? opacity,
    Map<String, dynamic>? extra,
  }) {
    return WidgetConfig(
      colors: colors ?? this.colors,
      opacity: opacity ?? this.opacity,
      extra: extra ?? this.extra,
    );
  }

  /// 获取扩展配置中的值
  T? getExtra<T>(String key) {
    return extra[key] as T?;
  }

  /// 更新扩展配置中的值
  WidgetConfig setExtra(String key, dynamic value) {
    final newExtra = Map<String, dynamic>.from(extra);
    newExtra[key] = value;
    return copyWith(extra: newExtra);
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'colors': colors.map((c) => c.toJson()).toList(),
      'opacity': opacity,
      'extra': extra,
    };
  }

  /// 从 JSON 反序列化
  factory WidgetConfig.fromJson(Map<String, dynamic> json) {
    return WidgetConfig(
      colors: (json['colors'] as List<dynamic>?)
              ?.map((c) => ColorConfig.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      extra: Map<String, dynamic>.from(json['extra'] as Map? ?? {}),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WidgetConfig) return false;

    if (colors.length != other.colors.length) return false;
    for (int i = 0; i < colors.length; i++) {
      if (colors[i] != other.colors[i]) return false;
    }

    return opacity == other.opacity;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(colors),
      opacity,
    );
  }
}
