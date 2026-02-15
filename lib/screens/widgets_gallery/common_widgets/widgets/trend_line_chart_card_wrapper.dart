import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/widgets/trend_line_chart_widget/trend_line_chart_widget.dart';

/// 趋势折线图卡片包装器
///
/// 用于 widgets_gallery 兼容性，提供 fromProps 工厂方法。
/// 实际实现位于 `lib/widgets/trend_line_chart_widget/trend_line_chart_widget.dart`。
class TrendLineChartCardWrapper extends StatelessWidget {
  /// 标题
  final String title;

  /// 图标代码
  final String icon;

  /// 显示的数值
  final double value;

  /// 数据点列表（Map 格式）
  final List<Map<String, dynamic>> dataPoints;

  /// 时间轴标签
  final List<String> timeLabels;

  /// 主色调（整数值）
  final int primaryColor;

  /// 数值颜色（整数值，可选）
  final int? valueColor;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const TrendLineChartCardWrapper({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    required this.dataPoints,
    required this.timeLabels,
    required this.primaryColor,
    this.valueColor,
    this.size = const LargeSize(),
  });

  /// 从 props 创建实例
  factory TrendLineChartCardWrapper.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final dataPointsList = props['dataPoints'] as List?;
    final dataPoints = dataPointsList?.map((item) {
      return Map<String, dynamic>.from(item as Map);
    }).toList() ?? <Map<String, dynamic>>[];

    final timeLabelsList = props['timeLabels'] as List?;
    final timeLabels = timeLabelsList?.map((e) => e as String).toList() ?? <String>[];

    return TrendLineChartCardWrapper(
      title: props['title'] as String? ?? '',
      icon: props['icon'] as String? ?? 'show_chart',
      value: (props['value'] as num?)?.toDouble() ?? 0.0,
      dataPoints: dataPoints,
      timeLabels: timeLabels,
      primaryColor: props['primaryColor'] as int? ?? Colors.pink.value,
      valueColor: props['valueColor'] as int?,
      size: size,
    );
  }

  /// 从图标代码获取 IconData
  IconData _getIconData(String iconCode) {
    switch (iconCode) {
      case 'show_chart':
        return Icons.show_chart;
      case 'timeline':
        return Icons.timeline;
      case 'trending_up':
        return Icons.trending_up;
      case 'thermostat':
        return Icons.thermostat;
      default:
        return Icons.show_chart;
    }
  }

  /// 将 Map 数据点转换为 Offset
  List<Offset> _parseDataPoints() {
    return dataPoints.map((point) {
      final x = (point['x'] as num?)?.toDouble() ?? 0.0;
      final y = (point['y'] as num?)?.toDouble() ?? 0.0;
      return Offset(x, y);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return TrendLineChartWidget(
      title: title,
      icon: _getIconData(icon),
      value: value,
      dataPoints: _parseDataPoints(),
      timeLabels: timeLabels,
      primaryColor: Color(primaryColor),
      valueColor: valueColor != null ? Color(valueColor!) : null,
    );
  }
}
