import 'package:flutter/material.dart';
import '../models/widget_grid_metrics.dart';

/// InheritedWidget 用于向子组件树传递网格尺寸信息
///
/// 在 [HomeGrid] 中创建，向下传递给 [HomeCard] 和小组件，
/// 供小组件获取实际渲染的像素尺寸。
///
/// 使用示例：
/// ```dart
/// // 在小组件中获取网格信息
/// final metrics = WidgetGridScope.maybeOf(context);
/// if (metrics != null) {
///   final pixelWidth = metrics.getPixelWidth(2); // 2 列宽的小组件
///   final pixelHeight = metrics.getPixelHeight(2); // 2 行高的小组件
/// }
/// ```
class WidgetGridScope extends InheritedWidget {
  /// 当前网格的尺寸信息
  final WidgetGridMetrics metrics;

  const WidgetGridScope({
    super.key,
    required this.metrics,
    required super.child,
  });

  /// 获取最近的 WidgetGridScope
  ///
  /// 如果找不到，返回 null
  static WidgetGridMetrics? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WidgetGridScope>();
    return scope?.metrics;
  }

  /// 获取最近的 WidgetGridScope
  ///
  /// 如果找不到，抛出异常
  static WidgetGridMetrics of(BuildContext context) {
    final metrics = maybeOf(context);
    if (metrics == null) {
      throw FlutterError(
        'WidgetGridScope.of() called with a context that does not contain a WidgetGridScope.\n'
        'No WidgetGridScope ancestor could be found starting from the context that was passed to WidgetGridScope.of().\n'
        'This usually happens when a widget that needs grid metrics is placed outside of HomeGrid.',
      );
    }
    return metrics;
  }

  @override
  bool updateShouldNotify(WidgetGridScope oldWidget) {
    final shouldNotify = metrics != oldWidget.metrics;
    if (shouldNotify) {
      debugPrint('[WidgetGridScope] 🔔 通知子组件更新: '
          'oldCellWidth=${oldWidget.metrics.cellWidth.toStringAsFixed(1)}, '
          'newCellWidth=${metrics.cellWidth.toStringAsFixed(1)}');
    }
    return shouldNotify;
  }
}
