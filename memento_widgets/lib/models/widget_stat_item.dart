/// 小组件统计项
class WidgetStatItem {
  /// 统计项ID
  final String id;

  /// 显示标签
  final String label;

  /// 统计值
  final String value;

  /// 是否高亮
  final bool highlight;

  /// 自定义颜色 (可选)
  final int? colorValue;

  WidgetStatItem({
    required this.id,
    required this.label,
    required this.value,
    this.highlight = false,
    this.colorValue,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'value': value,
    'highlight': highlight,
    if (colorValue != null) 'colorValue': colorValue,
  };

  factory WidgetStatItem.fromJson(Map<String, dynamic> json) {
    return WidgetStatItem(
      id: json['id'] as String,
      label: json['label'] as String,
      value: json['value'] as String,
      highlight: json['highlight'] as bool? ?? false,
      colorValue: json['colorValue'] as int?,
    );
  }
}
