import 'package:flutter/material.dart';

/// 颜色配置项
///
/// 用于定义小组件中的单个颜色配置，包含配置键、显示标签、默认值和当前值。
class ColorConfig {
  /// 配置键（如 'primary', 'accent'）
  final String key;

  /// 显示标签（用户可见的名称）
  final String label;

  /// 默认颜色值
  final Color defaultValue;

  /// 当前选中的颜色值
  final Color currentValue;

  const ColorConfig({
    required this.key,
    required this.label,
    required this.defaultValue,
    required this.currentValue,
  });

  /// 创建副本并更新当前颜色
  ColorConfig copyWith({Color? currentValue}) {
    return ColorConfig(
      key: key,
      label: label,
      defaultValue: defaultValue,
      currentValue: currentValue ?? this.currentValue,
    );
  }

  /// 重置为默认颜色
  ColorConfig reset() {
    return ColorConfig(
      key: key,
      label: label,
      defaultValue: defaultValue,
      currentValue: defaultValue,
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'defaultValue': defaultValue.value,
      'currentValue': currentValue.value,
    };
  }

  /// 从 JSON 反序列化
  factory ColorConfig.fromJson(Map<String, dynamic> json) {
    return ColorConfig(
      key: json['key'] as String,
      label: json['label'] as String,
      defaultValue: Color(json['defaultValue'] as int),
      currentValue: Color(json['currentValue'] as int),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ColorConfig &&
        other.key == key &&
        other.label == label &&
        other.defaultValue == defaultValue &&
        other.currentValue == currentValue;
  }

  @override
  int get hashCode {
    return Object.hash(key, label, defaultValue, currentValue);
  }
}
