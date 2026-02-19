import 'package:flutter/material.dart';
import 'home_widget_size.dart';
import '../widgets/widget_grid_scope.dart';

/// HomeWidgetSize 的扩展方法，提供便捷的像素尺寸访问
///
/// 使用示例：
/// ```dart
/// // 在小组件中使用
/// final size = config['widgetSize'] as HomeWidgetSize;
/// final pixelSize = size.pixelSizeOf(context);
///
/// return SizedBox(
///   width: pixelSize.width,
///   height: pixelSize.height,
///   child: MyContent(),
/// );
/// ```
extension HomeWidgetSizeExtension on HomeWidgetSize {
  /// 从 BuildContext 获取网格信息并计算像素宽度
  ///
  /// 如果无法获取网格信息（例如在 HomeGrid 外部使用），
  /// 则返回估算值
  double pixelWidthOf(BuildContext context) {
    final metrics = WidgetGridScope.maybeOf(context);
    return getPixelWidth(metrics);
  }

  /// 从 BuildContext 获取网格信息并计算像素高度
  ///
  /// 如果无法获取网格信息（例如在 HomeGrid 外部使用），
  /// 则返回估算值
  double pixelHeightOf(BuildContext context) {
    final metrics = WidgetGridScope.maybeOf(context);
    return getPixelHeight(metrics);
  }

  /// 从 BuildContext 获取网格信息并计算像素尺寸
  ///
  /// 返回包含宽度和高度的 Size 对象
  ///
  /// 如果无法获取网格信息（例如在 HomeGrid 外部使用），
  /// 则返回估算值
  Size pixelSizeOf(BuildContext context) {
    final metrics = WidgetGridScope.maybeOf(context);
    return getPixelSize(metrics);
  }

  /// 检查当前上下文中是否有网格尺寸信息
  ///
  /// 返回 true 表示当前在 HomeGrid 内部，可以获取准确的像素尺寸
  /// 返回 false 表示在 HomeGrid 外部，pixelSizeOf 将返回估算值
  bool hasGridMetrics(BuildContext context) {
    return WidgetGridScope.maybeOf(context) != null;
  }
}
