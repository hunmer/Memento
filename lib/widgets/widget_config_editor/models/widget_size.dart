import 'package:flutter/material.dart';

/// 小组件尺寸枚举
///
/// 用于定义 Android 桌面小组件的尺寸规格，
/// 并提供预览区域尺寸计算方法。
enum WidgetSize {
  /// 1x1 - 单个图标+标题
  small(1, 1),

  /// 2x1 - 横向卡片
  medium(2, 1),

  /// 2x2 - 大卡片
  large(2, 2),

  /// 4x2 - 超大横向卡片 (用于月视图等复杂小组件)
  extraLarge(4, 2),

  /// 4x4 - 超大正方形卡片 (用于复杂视图小组件)
  huge(4, 4);

  final int width;
  final int height;

  const WidgetSize(this.width, this.height);

  /// 计算预览区域宽度
  ///
  /// 基于屏幕宽度动态计算，假设桌面为 4 列网格
  double getPreviewWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 48 = 左右 padding, 48 = 4个间距 (3 * 16)
    final cellSize = (screenWidth - 48 - 48) / 4;
    return cellSize * width + (width - 1) * 16;
  }

  /// 计算预览区域高度
  ///
  /// 基于屏幕宽度动态计算，保持正方形比例
  double getPreviewHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cellSize = (screenWidth - 48 - 48) / 4;
    return cellSize * height + (height - 1) * 16;
  }

  /// 获取尺寸描述
  String get label {
    switch (this) {
      case WidgetSize.small:
        return '1x1';
      case WidgetSize.medium:
        return '2x1';
      case WidgetSize.large:
        return '2x2';
      case WidgetSize.extraLarge:
        return '4x2';
      case WidgetSize.huge:
        return '4x4';
    }
  }
}
