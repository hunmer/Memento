/// 彩色快捷方式网格数据模型
/// 用于显示快捷方式网格的数据
class ColorfulShortcutsGridData {
  /// 快捷方式项列表
  final List<ShortcutItemData> shortcuts;

  /// 列数（默认为2）
  final int columns;

  /// 项目高度（默认为100）
  final double itemHeight;

  /// 间距（默认为14）
  final double spacing;

  /// 边框圆角（默认为40）
  final double borderRadius;

  const ColorfulShortcutsGridData({
    required this.shortcuts,
    this.columns = 2,
    this.itemHeight = 100,
    this.spacing = 14,
    this.borderRadius = 40,
  });

  /// 从 JSON 创建
  factory ColorfulShortcutsGridData.fromJson(Map<String, dynamic> json) {
    return ColorfulShortcutsGridData(
      shortcuts: (json['shortcuts'] as List<dynamic>?)
              ?.map((e) => ShortcutItemData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      columns: json['columns'] as int? ?? 2,
      itemHeight: (json['itemHeight'] as num?)?.toDouble() ?? 100.0,
      spacing: (json['spacing'] as num?)?.toDouble() ?? 14.0,
      borderRadius: (json['borderRadius'] as num?)?.toDouble() ?? 40.0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'shortcuts': shortcuts.map((e) => e.toJson()).toList(),
      'columns': columns,
      'itemHeight': itemHeight,
      'spacing': spacing,
      'borderRadius': borderRadius,
    };
  }
}

/// 快捷方式项数据模型
class ShortcutItemData {
  /// 图标名称（使用 Material Icons 名称）
  final String iconName;

  /// 标签文本
  final String label;

  /// 背景颜色（ARGB 格式，如 0xFFFF5E63）
  final int color;

  /// 图标变换矩阵（可选，用于特殊图标变换）
  final List<double>? iconTransform;

  const ShortcutItemData({
    required this.iconName,
    required this.label,
    required this.color,
    this.iconTransform,
  });

  /// 从 JSON 创建
  factory ShortcutItemData.fromJson(Map<String, dynamic> json) {
    final transformList = json['iconTransform'] as List<dynamic>?;
    return ShortcutItemData(
      iconName: json['iconName'] as String? ?? 'star',
      label: json['label'] as String? ?? '',
      color: json['color'] as int? ?? 0xFF000000,
      iconTransform: transformList?.map((e) => (e as num).toDouble()).toList(),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'iconName': iconName,
      'label': label,
      'color': color,
      'iconTransform': iconTransform,
    };
  }
}
