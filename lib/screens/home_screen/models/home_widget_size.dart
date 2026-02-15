import 'package:flutter/material.dart';

/// 主页小组件尺寸配置基类
abstract class HomeWidgetSize {
  /// 宽度（占用的网格列数）
  final int width;

  /// 高度（占用的网格行数）
  final int height;

  /// 整体缩放偏移（百分比，默认为 1.0）
  final double scale;

  /// 内边距偏移（百分比）
  final double padding;

  /// 间距偏移（百分比）
  final double spacing;

  /// 字体大小偏移（百分比）
  final double fontSize;

  /// 图标大小偏移（百分比）
  final double iconSize;

  /// 线条粗细偏移（百分比）
  final double strokeWidth;

  const HomeWidgetSize({
    required this.width,
    required this.height,
    this.scale = 1.0,
    this.padding = 1.0,
    this.spacing = 1.0,
    this.fontSize = 1.0,
    this.iconSize = 1.0,
    this.strokeWidth = 1.0,
  });

  /// 向后兼容的静态 getter，支持 HomeWidgetSize.small 等访问方式
  static HomeWidgetSize get small => const SmallSize();
  static HomeWidgetSize get medium => const MediumSize();
  static HomeWidgetSize get large => const LargeSize();
  static HomeWidgetSize get large3 => const Large3Size();
  static HomeWidgetSize get wide => const WideSize();
  static HomeWidgetSize get wide2 => const Wide2Size();
  static HomeWidgetSize get wide3 => const Wide3Size();
  static HomeWidgetSize get custom => const CustomSize(width: -1, height: -1);

  /// 从宽高转换为尺寸实例
  static HomeWidgetSize fromSize(int width, int height) {
    return _allSizes.firstWhere(
      (size) => size.width == width && size.height == height,
      orElse: () => const LargeSize(),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {'width': width, 'height': height};
  }

  /// 从 JSON 加载
  static HomeWidgetSize fromJson(Map<String, dynamic> json) {
    final width = json['width'] as int;
    final height = json['height'] as int;

    for (final size in _allSizes) {
      if (size.width == width && size.height == height) {
        return size;
      }
    }
    return const LargeSize();
  }

  /// 判断当前尺寸是否至少与指定尺寸一样大
  bool isAtLeast(HomeWidgetSize other) {
    return width >= other.width && height >= other.height;
  }

  /// 判断当前尺寸是否大于指定尺寸
  bool isLargerThan(HomeWidgetSize other) {
    return width > other.width || height > other.height;
  }

  /// 判断当前尺寸是否等于指定尺寸
  bool isEqualTo(HomeWidgetSize other) {
    return width == other.width && height == other.height;
  }

  /// 获取内边距
  EdgeInsets getPadding() {
    double basePadding;
    if (this is SmallSize) {
      basePadding = 8;
    } else if (this is MediumSize) {
      basePadding = 12;
    } else if (this is WideSize) {
      basePadding = 12;
    } else {
      // Large, Large3, Wide2, Wide3
      basePadding = 16;
    }
    return EdgeInsets.all(basePadding * padding);
  }

  /// 获取标题和列表之间的间距
  double getTitleSpacing() {
    double baseSpacing;
    if (this is SmallSize) {
      baseSpacing = 16;
    } else if (this is MediumSize || this is WideSize) {
      baseSpacing = 20;
    } else {
      // Large, Large3, Wide2, Wide3
      baseSpacing = 24;
    }
    return baseSpacing * spacing;
  }

  /// 获取高度约束
  BoxConstraints getHeightConstraints() {
    double minHeight, maxHeight;
    if (this is SmallSize) {
      minHeight = 150;
      maxHeight = 250;
    } else if (this is MediumSize || this is WideSize) {
      minHeight = 200;
      maxHeight = 350;
    } else if (this is LargeSize || this is Wide2Size) {
      minHeight = 250;
      maxHeight = 450;
    } else {
      // Large3, Wide3
      minHeight = 350;
      maxHeight = 600;
    }
    return BoxConstraints(
      minHeight: minHeight * scale,
      maxHeight: maxHeight * scale,
    );
  }

  /// 获取列表项之间的间距
  double getItemSpacing() {
    double baseSpacing;
    if (this is SmallSize) {
      baseSpacing = 6;
    } else if (this is MediumSize || this is WideSize) {
      baseSpacing = 8;
    } else {
      // Large, Large3, Wide2, Wide3
      baseSpacing = 12;
    }
    return baseSpacing * spacing;
  }

  /// 获取图标大小
  double getIconSize() {
    double baseSize;
    if (this is SmallSize) {
      baseSize = 18;
    } else if (this is MediumSize || this is WideSize) {
      baseSize = 24;
    } else {
      // Large, Large3, Wide2, Wide3
      baseSize = 28;
    }
    return baseSize * iconSize;
  }

  /// 获取大字体大小
  double getLargeFontSize() {
    double baseSize;
    if (this is SmallSize) {
      baseSize = 36;
    } else if (this is MediumSize || this is WideSize) {
      baseSize = 48;
    } else {
      // Large, Large3, Wide2, Wide3
      baseSize = 56;
    }
    return baseSize * fontSize;
  }

  /// 获取标题字体大小
  double getTitleFontSize() {
    double baseSize;
    if (this is SmallSize) {
      baseSize = 16;
    } else if (this is MediumSize || this is WideSize) {
      baseSize = 24;
    } else {
      // Large, Large3, Wide2, Wide3
      baseSize = 28;
    }
    return baseSize * fontSize;
  }

  /// 获取副标题字体大小
  double getSubtitleFontSize() {
    double baseSize;
    if (this is SmallSize) {
      baseSize = 12;
    } else if (this is MediumSize || this is WideSize) {
      baseSize = 14;
    } else {
      // Large, Large3, Wide2, Wide3
      baseSize = 16;
    }
    return baseSize * fontSize;
  }

  /// 获取小间距（用于紧密元素之间）
  double getSmallSpacing() {
    double baseSpacing;
    if (this is SmallSize) {
      baseSpacing = 2;
    } else if (this is MediumSize || this is WideSize) {
      baseSpacing = 4;
    } else {
      // Large, Large3, Wide2, Wide3
      baseSpacing = 6;
    }
    return baseSpacing * spacing;
  }

  /// 获取图例指示器宽度
  double getLegendIndicatorWidth() {
    double baseSize;
    if (this is SmallSize) {
      baseSize = 16;
    } else if (this is MediumSize || this is WideSize) {
      baseSize = 24;
    } else {
      // Large, Large3, Wide2, Wide3
      baseSize = 32;
    }
    return baseSize * scale;
  }

  /// 获取图例指示器高度
  double getLegendIndicatorHeight() {
    double baseSize;
    if (this is SmallSize) {
      baseSize = 8;
    } else if (this is MediumSize || this is WideSize) {
      baseSize = 12;
    } else {
      // Large, Large3, Wide2, Wide3
      baseSize = 16;
    }
    return baseSize * scale;
  }

  /// 获取图例字体大小
  double getLegendFontSize() {
    double baseSize;
    if (this is SmallSize) {
      baseSize = 10;
    } else if (this is MediumSize || this is WideSize) {
      baseSize = 12;
    } else {
      // Large, Large3, Wide2, Wide3
      baseSize = 14;
    }
    return baseSize * fontSize;
  }

  /// 获取柱状图柱子宽度
  double getBarWidth() {
    double baseSize;
    if (this is SmallSize) {
      baseSize = 12;
    } else if (this is MediumSize || this is WideSize) {
      baseSize = 16;
    } else {
      // Large, Large3, Wide2, Wide3
      baseSize = 20;
    }
    return baseSize * scale;
  }

  /// 获取柱子之间的间距
  double getBarSpacing() {
    double baseSpacing;
    if (this is SmallSize) {
      baseSpacing = 0.5;
    } else if (this is MediumSize || this is WideSize) {
      baseSpacing = 1.0;
    } else {
      // Large, Large3, Wide2, Wide3
      baseSpacing = 1.5;
    }
    return baseSpacing * spacing;
  }

  /// 获取进度条线条粗细
  double getStrokeWidth() {
    double baseWidth;
    if (this is SmallSize) {
      baseWidth = 6.0;
    } else if (this is MediumSize || this is WideSize) {
      baseWidth = 8.0;
    } else {
      // Large, Large3, Wide2, Wide3
      baseWidth = 10.0;
    }
    return baseWidth * strokeWidth;
  }
}

/// 1x1 小图标组件
class SmallSize extends HomeWidgetSize {
  const SmallSize({
    double scale = 1.0,
    double padding = 1.0,
    double spacing = 1.0,
    double fontSize = 1.0,
    double iconSize = 1.0,
    double strokeWidth = 1.0,
  }) : super(
          width: 1,
          height: 1,
          scale: scale,
          padding: padding,
          spacing: spacing,
          fontSize: fontSize,
          iconSize: iconSize,
          strokeWidth: strokeWidth,
        );
}

/// 2x1 横向卡片
class MediumSize extends HomeWidgetSize {
  const MediumSize({
    double scale = 1.0,
    double padding = 1.0,
    double spacing = 1.0,
    double fontSize = 1.0,
    double iconSize = 1.0,
    double strokeWidth = 1.0,
  }) : super(
          width: 2,
          height: 1,
          scale: scale,
          padding: padding,
          spacing: spacing,
          fontSize: fontSize,
          iconSize: iconSize,
          strokeWidth: strokeWidth,
        );
}

/// 2x2 大卡片
class LargeSize extends HomeWidgetSize {
  const LargeSize({
    double scale = 1.0,
    double padding = 1.0,
    double spacing = 1.0,
    double fontSize = 1.0,
    double iconSize = 1.0,
    double strokeWidth = 1.0,
  }) : super(
          width: 2,
          height: 2,
          scale: scale,
          padding: padding,
          spacing: spacing,
          fontSize: fontSize,
          iconSize: iconSize,
          strokeWidth: strokeWidth,
        );
}

/// 2x3 高卡片（宽度2，高度3）
class Large3Size extends HomeWidgetSize {
  const Large3Size({
    double scale = 1.0,
    double padding = 1.0,
    double spacing = 1.0,
    double fontSize = 1.0,
    double iconSize = 1.0,
    double strokeWidth = 1.0,
  }) : super(
          width: 2,
          height: 3,
          scale: scale,
          padding: padding,
          spacing: spacing,
          fontSize: fontSize,
          iconSize: iconSize,
          strokeWidth: strokeWidth,
        );
}

/// 4x1 宽屏卡片（占满所有宽度）
class WideSize extends HomeWidgetSize {
  const WideSize({
    double scale = 1.0,
    double padding = 1.0,
    double spacing = 1.0,
    double fontSize = 1.0,
    double iconSize = 1.0,
    double strokeWidth = 1.0,
  }) : super(
          width: 4,
          height: 1,
          scale: scale,
          padding: padding,
          spacing: spacing,
          fontSize: fontSize,
          iconSize: iconSize,
          strokeWidth: strokeWidth,
        );
}

/// 4x2 全宽卡片（占满所有宽度，高度2）
class Wide2Size extends HomeWidgetSize {
  const Wide2Size({
    double scale = 1.0,
    double padding = 1.0,
    double spacing = 1.0,
    double fontSize = 1.0,
    double iconSize = 1.0,
    double strokeWidth = 1.0,
  }) : super(
          width: 4,
          height: 2,
          scale: scale,
          padding: padding,
          spacing: spacing,
          fontSize: fontSize,
          iconSize: iconSize,
          strokeWidth: strokeWidth,
        );
}

/// 4x3 全宽卡片（占满所有宽度，高度3）
class Wide3Size extends HomeWidgetSize {
  const Wide3Size({
    double scale = 1.0,
    double padding = 1.0,
    double spacing = 1.0,
    double fontSize = 1.0,
    double iconSize = 1.0,
    double strokeWidth = 1.0,
  }) : super(
          width: 4,
          height: 3,
          scale: scale,
          padding: padding,
          spacing: spacing,
          fontSize: fontSize,
          iconSize: iconSize,
          strokeWidth: strokeWidth,
        );
}

/// 自定义尺寸（支持任意宽高）
class CustomSize extends HomeWidgetSize {
  const CustomSize({
    required int width,
    required int height,
    double scale = 1.0,
    double padding = 1.0,
    double spacing = 1.0,
    double fontSize = 1.0,
    double iconSize = 1.0,
    double strokeWidth = 1.0,
  }) : super(
          width: width,
          height: height,
          scale: scale,
          padding: padding,
          spacing: spacing,
          fontSize: fontSize,
          iconSize: iconSize,
          strokeWidth: strokeWidth,
        );
}

/// 所有尺寸的默认实例列表
final List<HomeWidgetSize> _allSizes = const [
  SmallSize(),
  MediumSize(),
  LargeSize(),
  Large3Size(),
  WideSize(),
  Wide2Size(),
  Wide3Size(),
];
