import 'package:flutter/material.dart';

/// 网格尺寸信息，用于计算小组件的实际像素尺寸
///
/// 该类由 [HomeGrid] 计算，通过 [WidgetGridScope] 传递给子组件树，
/// 供小组件获取实际渲染的像素尺寸。
class WidgetGridMetrics {
  /// 网格总宽度（像素）
  final double gridWidth;

  /// 单个单元格的宽度（像素）
  final double cellWidth;

  /// 单个单元格的高度（像素，基于 1:1 宽高比计算）
  final double cellHeight;

  /// 网格列数
  final int crossAxisCount;

  /// 网格行间距
  final double mainAxisSpacing;

  /// 网格列间距
  final double crossAxisSpacing;

  /// 内边距
  final EdgeInsets padding;

  const WidgetGridMetrics({
    required this.gridWidth,
    required this.cellWidth,
    required this.cellHeight,
    required this.crossAxisCount,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
    required this.padding,
  });

  /// 根据网格占比计算实际像素宽度
  ///
  /// [crossAxisCellCount] 小组件占用的网格列数
  ///
  /// 返回包含间距的实际像素宽度
  double getPixelWidth(int crossAxisCellCount) {
    if (crossAxisCellCount <= 0) return 0;
    final totalSpacing = (crossAxisCellCount - 1) * crossAxisSpacing;
    return crossAxisCellCount * cellWidth + totalSpacing;
  }

  /// 根据网格占比计算实际像素高度
  ///
  /// [mainAxisCellCount] 小组件占用的网格行数
  ///
  /// 返回包含间距的实际像素高度
  double getPixelHeight(int mainAxisCellCount) {
    if (mainAxisCellCount <= 0) return 0;
    final totalSpacing = (mainAxisCellCount - 1) * mainAxisSpacing;
    return mainAxisCellCount * cellHeight + totalSpacing;
  }

  /// 获取网格的可用宽度（去除内边距）
  double get availableWidth => gridWidth - padding.left - padding.right;

  /// 获取网格的可用高度（去除内边距）
  ///
  /// 注意：高度通常由内容决定，这里仅返回一个理论值
  double get availableHeight {
    // 由于网格高度通常是无限的（可滚动），这里返回一个估算值
    // 实际使用时应该基于 constraints
    return double.infinity;
  }

  /// 计算 HomeWidgetSize 对应的像素宽度
  ///
  /// [gridWidth] 网格宽度占比
  double getPixelWidthForGridCount(int gridWidth) {
    return getPixelWidth(gridWidth);
  }

  /// 计算 HomeWidgetSize 对应的像素高度
  ///
  /// [gridHeight] 网格高度占比
  double getPixelHeightForGridCount(int gridHeight) {
    return getPixelHeight(gridHeight);
  }

  @override
  String toString() {
    return 'WidgetGridMetrics(gridWidth: $gridWidth, cellWidth: $cellWidth, '
        'cellHeight: $cellHeight, crossAxisCount: $crossAxisCount, '
        'mainAxisSpacing: $mainAxisSpacing, crossAxisSpacing: $crossAxisSpacing)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WidgetGridMetrics &&
        other.gridWidth == gridWidth &&
        other.cellWidth == cellWidth &&
        other.cellHeight == cellHeight &&
        other.crossAxisCount == crossAxisCount &&
        other.mainAxisSpacing == mainAxisSpacing &&
        other.crossAxisSpacing == crossAxisSpacing &&
        other.padding == padding;
  }

  @override
  int get hashCode {
    return Object.hash(
      gridWidth,
      cellWidth,
      cellHeight,
      crossAxisCount,
      mainAxisSpacing,
      crossAxisSpacing,
      padding,
    );
  }
}
