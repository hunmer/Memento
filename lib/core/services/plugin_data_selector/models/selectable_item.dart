import 'package:flutter/material.dart';

/// 可选择的数据项
///
/// 用于在选择器中展示的统一数据项模型
class SelectableItem {
  /// 项目唯一标识
  final String id;

  /// 显示标题
  final String title;

  /// 副标题（可选）
  final String? subtitle;

  /// 图标（可选）
  final IconData? icon;

  /// 头像路径（可选）
  final String? avatarPath;

  /// 颜色（可选）
  final Color? color;

  /// 原始数据对象（用于最终返回）
  final dynamic rawData;

  /// 额外的元数据
  final Map<String, dynamic>? metadata;

  /// 是否可选择（某些项可能仅用于展示）
  final bool selectable;

  /// 是否已选中（用于多选模式）
  final bool selected;

  const SelectableItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.icon,
    this.avatarPath,
    this.color,
    this.rawData,
    this.metadata,
    this.selectable = true,
    this.selected = false,
  });

  /// 创建选中状态的副本
  SelectableItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    IconData? icon,
    String? avatarPath,
    Color? color,
    dynamic rawData,
    Map<String, dynamic>? metadata,
    bool? selectable,
    bool? selected,
  }) {
    return SelectableItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      avatarPath: avatarPath ?? this.avatarPath,
      color: color ?? this.color,
      rawData: rawData ?? this.rawData,
      metadata: metadata ?? this.metadata,
      selectable: selectable ?? this.selectable,
      selected: selected ?? this.selected,
    );
  }

  /// 转换为 Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'metadata': metadata,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectableItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
