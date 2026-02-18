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

  /// 图标容器大小倍数（相对于图标大小）
  final double iconContainerScale;

  /// 圆形进度条粗细倍数（相对于基础 strokeWidth）
  final double progressStrokeScale;

  const HomeWidgetSize({
    required this.width,
    required this.height,
    this.scale = 1.0,
    this.padding = 1.0,
    this.spacing = 1.0,
    this.fontSize = 1.0,
    this.iconSize = 1.0,
    this.strokeWidth = 1.0,
    this.iconContainerScale = 1.5,
    this.progressStrokeScale = 0.4,
  });

  /// 相等性比较：基于 width 和 height
  bool isEqualToSize(HomeWidgetSize other) {
    return width == other.width && height == other.height;
  }

  /// 向后兼容的静态 getter，支持 const SmallSize() 等访问方式
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
    // 如果没有匹配的预设尺寸，返回 CustomSize
    return CustomSize(width: width, height: height);
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

  /// 获取条形图列表容器高度
  double getRankedBarListHeight() {
    double baseHeight;
    if (this is SmallSize) {
      baseHeight = 150;
    } else if (this is MediumSize || this is WideSize) {
      baseHeight = 200;
    } else if (this is LargeSize || this is Wide2Size) {
      baseHeight = 300;
    } else {
      // Large3, Wide3
      baseHeight = 400;
    }
    return baseHeight * scale;
  }

  /// 获取单个条形图条目高度
  double getRankedBarItemHeight() {
    double baseHeight;
    if (this is SmallSize) {
      baseHeight = 32;
    } else if (this is MediumSize || this is WideSize) {
      baseHeight = 40;
    } else if (this is LargeSize || this is Wide2Size) {
      baseHeight = 48;
    } else {
      // Large3, Wide3
      baseHeight = 56;
    }
    return baseHeight * scale;
  }

  /// 获取条形图最大宽度（基础值，会根据 value 动态调整）
  double getRankedBarMaxWidth() {
    double baseWidth;
    if (this is SmallSize) {
      baseWidth = 200;
    } else if (this is MediumSize || this is WideSize) {
      baseWidth = 280;
    } else if (this is LargeSize || this is Wide2Size) {
      baseWidth = 360;
    } else {
      // Large3, Wide3
      baseWidth = 440;
    }
    return baseWidth * scale;
  }

  /// 获取热力图高度
  double getHeatmapHeight() {
    double baseHeight;
    if (this is SmallSize) {
      baseHeight = 60;
    } else if (this is MediumSize || this is WideSize) {
      baseHeight = 100;
    } else if (this is LargeSize || this is Wide2Size) {
      baseHeight = 140;
    } else {
      // Large3, Wide3
      baseHeight = 180;
    }
    return baseHeight * scale;
  }

  /// 获取图表宽度
  double getWidthForChart() {
    double baseWidth;
    if (this is SmallSize) {
      baseWidth = 120;
    } else if (this is MediumSize) {
      baseWidth = 240;
    } else if (this is LargeSize) {
      baseWidth = 280;
    } else if (this is WideSize) {
      baseWidth = 600;
    } else if (this is Wide2Size) {
      baseWidth = 700;
    } else {
      // Large3, Wide3
      baseWidth = 280;
    }
    return baseWidth * scale;
  }

  /// 获取图表高度
  double getHeightForChart() {
    double baseHeight;
    if (this is SmallSize) {
      baseHeight = 100;
    } else if (this is MediumSize) {
      baseHeight = 150;
    } else if (this is LargeSize) {
      baseHeight = 200;
    } else if (this is WideSize) {
      baseHeight = 150;
    } else if (this is Wide2Size) {
      baseHeight = 250;
    } else {
      // Large3, Wide3
      baseHeight = 200;
    }
    return baseHeight * scale;
  }

  /// 获取特色图片/缩略图尺寸（用于卡片封面）
  double getFeaturedImageSize() {
    double baseSize;
    if (this is SmallSize) {
      baseSize = 60;
    } else if (this is MediumSize || this is WideSize) {
      baseSize = 80;
    } else if (this is LargeSize || this is Wide2Size) {
      baseSize = 100;
    } else {
      // Large3, Wide3
      baseSize = 120;
    }
    return baseSize * scale;
  }

  /// 获取列表项缩略图尺寸
  double getThumbnailImageSize() {
    double baseSize;
    if (this is SmallSize) {
      baseSize = 36;
    } else if (this is MediumSize || this is WideSize) {
      baseSize = 48;
    } else if (this is LargeSize || this is Wide2Size) {
      baseSize = 56;
    } else {
      // Large3, Wide3
      baseSize = 64;
    }
    return baseSize * scale;
  }

  /// 获取特色图片图标尺寸
  double getFeaturedIconSize() {
    double baseSize;
    if (this is SmallSize) {
      baseSize = 28;
    } else if (this is MediumSize || this is WideSize) {
      baseSize = 40;
    } else if (this is LargeSize || this is Wide2Size) {
      baseSize = 48;
    } else {
      // Large3, Wide3
      baseSize = 56;
    }
    return baseSize * iconSize;
  }

  /// 获取列表项图标尺寸
  double getThumbnailIconSize() {
    double baseSize;
    if (this is SmallSize) {
      baseSize = 18;
    } else if (this is MediumSize || this is WideSize) {
      baseSize = 24;
    } else if (this is LargeSize || this is Wide2Size) {
      baseSize = 28;
    } else {
      // Large3, Wide3
      baseSize = 32;
    }
    return baseSize * iconSize;
  }

  /// 获取文章列表区域高度
  double getArticleListHeight() {
    double baseHeight;
    if (this is SmallSize) {
      baseHeight = 200;
    } else if (this is MediumSize) {
      baseHeight = 250;
    } else if (this is WideSize) {
      baseHeight = 280;
    } else if (this is LargeSize) {
      baseHeight = 320;
    } else if (this is Wide2Size) {
      baseHeight = 360;
    } else {
      // Large3, Wide3
      baseHeight = 450;
    }
    return baseHeight * scale;
  }
}

/// 1x1 小图标组件
class SmallSize extends HomeWidgetSize {
  const SmallSize({
    super.scale,
    super.padding,
    super.spacing,
    super.fontSize,
    super.iconSize,
    super.strokeWidth,
    super.iconContainerScale,
    super.progressStrokeScale,
  }) : super(width: 1, height: 1);
}

/// 2x1 横向卡片
class MediumSize extends HomeWidgetSize {
  const MediumSize({
    super.scale,
    super.padding,
    super.spacing,
    super.fontSize,
    super.iconSize,
    super.strokeWidth,
    super.iconContainerScale,
    super.progressStrokeScale,
  }) : super(width: 2, height: 1);
}

/// 2x2 大卡片
class LargeSize extends HomeWidgetSize {
  const LargeSize({
    super.scale,
    super.padding,
    super.spacing,
    super.fontSize,
    super.iconSize,
    super.strokeWidth,
    super.iconContainerScale,
    super.progressStrokeScale,
  }) : super(width: 2, height: 2);
}

/// 2x3 高卡片（宽度2，高度3）
class Large3Size extends HomeWidgetSize {
  const Large3Size({
    super.scale,
    super.padding,
    super.spacing,
    super.fontSize,
    super.iconSize,
    super.strokeWidth,
    super.iconContainerScale,
    super.progressStrokeScale,
  }) : super(width: 2, height: 3);
}

/// 4x1 宽屏卡片（占满所有宽度）
class WideSize extends HomeWidgetSize {
  const WideSize({
    super.scale,
    super.padding,
    super.spacing,
    super.fontSize,
    super.iconSize,
    super.strokeWidth,
    super.iconContainerScale,
    super.progressStrokeScale,
  }) : super(width: 4, height: 1);
}

/// 4x2 全宽卡片（占满所有宽度，高度2）
class Wide2Size extends HomeWidgetSize {
  const Wide2Size({
    super.scale,
    super.padding,
    super.spacing,
    super.fontSize,
    super.iconSize,
    super.strokeWidth,
    super.iconContainerScale,
    super.progressStrokeScale,
  }) : super(width: 4, height: 2);
}

/// 4x3 全宽卡片（占满所有宽度，高度3）
class Wide3Size extends HomeWidgetSize {
  const Wide3Size({
    super.scale,
    super.padding,
    super.spacing,
    super.fontSize,
    super.iconSize,
    super.strokeWidth,
    super.iconContainerScale,
    super.progressStrokeScale,
  }) : super(width: 4, height: 3);
}

/// 自定义尺寸（支持任意宽高）
class CustomSize extends HomeWidgetSize {
  const CustomSize({
    required super.width,
    required super.height,
    super.scale,
    super.padding,
    super.spacing,
    super.fontSize,
    super.iconSize,
    super.strokeWidth,
    super.iconContainerScale,
    super.progressStrokeScale,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomSize &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(width, height);
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
