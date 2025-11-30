import 'widget_stat_item.dart';

/// 插件小组件数据模型
class PluginWidgetData {
  /// 插件ID
  final String pluginId;

  /// 插件名称
  final String pluginName;

  /// 图标 codePoint
  final int iconCodePoint;

  /// 主题色值
  final int colorValue;

  /// 统计项列表
  final List<WidgetStatItem> stats;

  /// 最后更新时间
  final DateTime lastUpdated;

  PluginWidgetData({
    required this.pluginId,
    required this.pluginName,
    required this.iconCodePoint,
    required this.colorValue,
    required this.stats,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'pluginId': pluginId,
    'pluginName': pluginName,
    'iconCodePoint': iconCodePoint,
    'colorValue': colorValue,
    'stats': stats.map((s) => s.toJson()).toList(),
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory PluginWidgetData.fromJson(Map<String, dynamic> json) {
    return PluginWidgetData(
      pluginId: json['pluginId'] as String,
      pluginName: json['pluginName'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
      colorValue: json['colorValue'] as int,
      stats: (json['stats'] as List)
          .map((s) => WidgetStatItem.fromJson(s as Map<String, dynamic>))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
}
