import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 统计项数据
class StatItemData {
  final String id;          // 唯一标识
  final String label;       // 显示标签
  final String value;       // 显示数值
  final bool highlight;     // 是否高亮显示
  final Color? color;       // 自定义颜色

  const StatItemData({
    required this.id,
    required this.label,
    required this.value,
    this.highlight = false,
    this.color,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'value': value,
    'highlight': highlight,
    'color': color?.value,
  };

  factory StatItemData.fromJson(Map<String, dynamic> json) {
    return StatItemData(
      id: json['id'] as String,
      label: json['label'] as String,
      value: json['value'] as String,
      highlight: json['highlight'] as bool? ?? false,
      color: json['color'] != null ? Color(json['color'] as int) : null,
    );
  }
}

/// 小组件显示风格
enum PluginWidgetDisplayStyle {
  oneColumn,  // 一列文字
  twoColumns, // 两列文字
}

/// 插件小组件配置
class PluginWidgetConfig {
  /// 显示风格
  PluginWidgetDisplayStyle displayStyle;

  /// 要显示的统计项（用户可选择）
  List<String> selectedItemIds;

  /// 背景图片路径
  String? backgroundImagePath;

  /// 图标颜色（覆盖插件默认颜色）
  Color? iconColor;

  /// 背景颜色（无背景图片时生效）
  Color? backgroundColor;

  PluginWidgetConfig({
    this.displayStyle = PluginWidgetDisplayStyle.twoColumns,
    List<String>? selectedItemIds,
    this.backgroundImagePath,
    this.iconColor,
    this.backgroundColor,
  }) : selectedItemIds = selectedItemIds ?? [];

  Map<String, dynamic> toJson() => {
    'displayStyle': displayStyle.index,
    'selectedItemIds': selectedItemIds,
    'backgroundImagePath': backgroundImagePath,
    'iconColor': iconColor?.value,
    'backgroundColor': backgroundColor?.value,
  };

  factory PluginWidgetConfig.fromJson(Map<String, dynamic> json) {
    return PluginWidgetConfig(
      displayStyle: PluginWidgetDisplayStyle.values[
        json['displayStyle'] as int? ?? 1
      ],
      selectedItemIds: (json['selectedItemIds'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList(),
      backgroundImagePath: json['backgroundImagePath'] as String?,
      iconColor: json['iconColor'] != null
        ? Color(json['iconColor'] as int)
        : null,
      backgroundColor: json['backgroundColor'] != null
        ? Color(json['backgroundColor'] as int)
        : null,
    );
  }

  PluginWidgetConfig copyWith({
    PluginWidgetDisplayStyle? displayStyle,
    List<String>? selectedItemIds,
    String? backgroundImagePath,
    Color? iconColor,
    Color? backgroundColor,
    bool clearBackgroundImage = false,
    bool clearIconColor = false,
    bool clearBackgroundColor = false,
  }) {
    return PluginWidgetConfig(
      displayStyle: displayStyle ?? this.displayStyle,
      selectedItemIds: selectedItemIds ?? this.selectedItemIds,
      backgroundImagePath: clearBackgroundImage
        ? null
        : backgroundImagePath ?? this.backgroundImagePath,
      iconColor: clearIconColor
        ? null
        : iconColor ?? this.iconColor,
      backgroundColor: clearBackgroundColor
        ? null
        : backgroundColor ?? this.backgroundColor,
    );
  }
}
