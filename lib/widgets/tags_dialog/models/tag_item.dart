import 'package:flutter/material.dart';

/// 标签数据模型
class TagItem {
  /// 标签名称
  final String name;

  /// 标签图标
  final IconData icon;

  /// 标签颜色（可选）
  final Color? color;

  /// 标签分组
  final String group;

  /// 标签注释
  final String? comment;

  /// 添加时间
  final DateTime createdAt;

  /// 最后使用时间
  final DateTime? lastUsedAt;

  const TagItem({
    required this.name,
    this.icon = Icons.label,
    this.color,
    required this.group,
    this.comment,
    required this.createdAt,
    this.lastUsedAt,
  });

  /// 从 Map 创建 TagItem
  factory TagItem.fromMap(Map<String, dynamic> map) {
    return TagItem(
      name: map['name'] as String,
      icon: _getIconFromString(map['icon'] as String?),
      color: _getColorFromValue(map['color'] as int?),
      group: map['group'] as String? ?? 'default',
      comment: map['comment'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastUsedAt: map['lastUsedAt'] != null
          ? DateTime.parse(map['lastUsedAt'] as String)
          : null,
    );
  }

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': _getStringFromIcon(icon),
      'color': color?.value,
      'group': group,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };
  }

  /// 创建副本
  TagItem copyWith({
    String? name,
    IconData? icon,
    Color? color,
    String? group,
    String? comment,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return TagItem(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      group: group ?? this.group,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  /// 更新最后使用时间
  TagItem updateLastUsed() {
    return TagItem(
      name: name,
      icon: icon,
      color: color,
      group: group,
      comment: comment,
      createdAt: createdAt,
      lastUsedAt: DateTime.now(),
    );
  }

  /// 从字符串获取图标
  static IconData _getIconFromString(String? iconString) {
    if (iconString == null || iconString.isEmpty) {
      return Icons.label;
    }
    try {
      // 从 codePoint 解析图标
      final codePoint = int.tryParse(iconString);
      if (codePoint != null) {
        return IconData(codePoint, fontFamily: 'MaterialIcons');
      }
      return Icons.label;
    } catch (e) {
      return Icons.label;
    }
  }

  /// 从图标获取字符串
  static String _getStringFromIcon(IconData icon) {
    return icon.codePoint.toString();
  }

  /// 从整数值获取颜色
  static Color? _getColorFromValue(int? value) {
    if (value == null) return null;
    return Color(value);
  }
}

/// 标签组
class TagGroupWithTags {
  /// 分组名称
  final String name;

  /// 标签列表
  final List<TagItem> tags;

  const TagGroupWithTags({
    required this.name,
    this.tags = const [],
  });

  /// 从 Map 创建
  factory TagGroupWithTags.fromMap(Map<String, dynamic> map) {
    final name = map['name'] as String;
    final tagsList = map['tags'] as List<dynamic>? ?? [];

    return TagGroupWithTags(
      name: name,
      tags: tagsList.map((tag) {
        // 兼容旧格式：如果是字符串，转换为 TagItem
        if (tag is String) {
          return TagItem(
            name: tag,
            group: name,
            createdAt: DateTime.now(),
          );
        }
        // 新格式：从 Map 创建
        return TagItem.fromMap(tag as Map<String, dynamic>);
      }).toList(),
    );
  }

  /// 从简单的字符串列表创建（兼容旧版 TagGroup）
  factory TagGroupWithTags.fromStringList({
    required String name,
    required List<String> tags,
  }) {
    return TagGroupWithTags(
      name: name,
      tags: tags.map((tagName) => TagItem(
        name: tagName,
        group: name,
        createdAt: DateTime.now(),
      )).toList(),
    );
  }

  /// 从旧版 TagGroup 创建（兼容性方法）
  factory TagGroupWithTags.fromLegacyTagGroup(
    dynamic legacyGroup, {
    DateTime? defaultCreatedAt,
  }) {
    // 如果已经是 TagGroupWithTags，直接返回
    if (legacyGroup is TagGroupWithTags) {
      return legacyGroup;
    }

    // 处理旧的 TagGroup 格式
    final groupName = legacyGroup is Map
        ? (legacyGroup['name'] as String? ?? 'default')
        : (legacyGroup.name as String? ?? 'default');

    final tags = legacyGroup is Map
        ? (legacyGroup['tags'] as List<dynamic>? ?? [])
        : (legacyGroup.tags as List<dynamic>? ?? []);

    return TagGroupWithTags(
      name: groupName,
      tags: tags.map((tag) {
        if (tag is String) {
          return TagItem(
            name: tag,
            group: groupName,
            createdAt: defaultCreatedAt ?? DateTime.now(),
          );
        } else if (tag is Map) {
          return TagItem.fromMap(tag as Map<String, dynamic>);
        }
        return TagItem(
          name: tag.toString(),
          group: groupName,
          createdAt: defaultCreatedAt ?? DateTime.now(),
        );
      }).toList(),
    );
  }

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'tags': tags.map((e) => e.toMap()).toList(),
    };
  }

  /// 创建副本
  TagGroupWithTags copyWith({
    String? name,
    List<TagItem>? tags,
  }) {
    return TagGroupWithTags(
      name: name ?? this.name,
      tags: tags ?? List.from(this.tags),
    );
  }
}
