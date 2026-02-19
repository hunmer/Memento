import 'package:flutter/material.dart';

/// 小组件尺寸类别枚举
///
/// 基于 min(width, height) 判断组件的基础尺寸级别：
/// - mini: 1x1, 1x2, 2x1 等（最小边为 1）
/// - small: 2x2, 2x3, 3x2 等（最小边为 2）
/// - medium: 3x3, 3x4, 4x3 等（最小边为 3）
/// - large: 4x4, 4x5, 5x4 等（最小边为 4）
/// - xlarge: 更大
enum SizeCategory {
  /// 最小尺寸 - 最小边为 1（如 1x1, 1x2, 2x1）
  mini,

  /// 小尺寸 - 最小边为 2（如 2x2, 2x3, 3x2, 4x1）
  small,

  /// 中等尺寸 - 最小边为 3（如 3x3, 3x4, 4x3）
  medium,

  /// 大尺寸 - 最小边为 4（如 4x4, 4x5, 5x4）
  large,

  /// 超大尺寸 - 最小边 ≥5
  xlarge,
}

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

  // ===== 语义化辅助方法 =====

  /// 是否为宽型组件（宽度 > 高度）
  ///
  /// 用于判断是否使用水平布局
  bool get isWide => width > height;

  /// 是否为高型组件（高度 > 宽度）
  ///
  /// 用于判断是否使用垂直布局
  bool get isTall => height > width;

  /// 是否为正方形组件（宽度 == 高度）
  ///
  /// 如 1x1, 2x2, 3x3 等
  bool get isSquare => width == height;

  /// 获取尺寸类别
  ///
  /// 基于 min(width, height) 判断基础尺寸级别：
  /// - mini: 最小边为 1（1x1, 1x2, 2x1 等）
  /// - small: 最小边为 2（2x2, 2x3, 3x2, 4x1, 4x2 等）
  /// - medium: 最小边为 3（3x3, 3x4, 4x3 等）
  /// - large: 最小边为 4（4x4, 4x5, 5x4 等）
  /// - xlarge: 最小边 ≥5
  SizeCategory get category {
    final minSide = width < height ? width : height;
    switch (minSide) {
      case 1:
        return SizeCategory.mini;
      case 2:
        return SizeCategory.small;
      case 3:
        return SizeCategory.medium;
      case 4:
        return SizeCategory.large;
      default:
        return SizeCategory.xlarge;
    }
  }

  /// 计算相对于网格总列数的宽度比例（0.0 - 1.0）
  ///
  /// 用于判断组件在当前网格配置下占据多少水平空间
  /// 例如：在 4 列网格中，width=2 的组件占比 0.5
  double getWidthRatio(int gridCrossAxisCount) {
    return (width / gridCrossAxisCount).clamp(0.0, 1.0);
  }

  /// 计算相对于网格总行数的高度比例（0.0 - 1.0）
  ///
  /// [gridMainAxisCount] 网格的主轴（垂直）方向的总行数
  double getHeightRatio(int gridMainAxisCount) {
    if (gridMainAxisCount <= 0) return 1.0;
    return (height / gridMainAxisCount).clamp(0.0, 1.0);
  }

  /// 判断是否占满整行
  ///
  /// 当组件宽度 >= 网格列数时返回 true
  bool isFullWidth(int gridCrossAxisCount) {
    return width >= gridCrossAxisCount;
  }

  /// 判断是否为"图标型"小组件
  ///
  /// 通常用于 1x1 的小型组件，只显示图标或简单信息
  bool get isIconSized => width == 1 && height == 1;

  /// 判断是否为"卡片型"小组件
  ///
  /// 通常用于 2x1 或更大的组件，可以显示更多内容
  bool get isCardSized => width >= 2 || height >= 2;

  /// 获取宽高比
  ///
  /// 用于判断内容应该水平排列还是垂直排列
  double get aspectRatio => height == 0 ? 1.0 : width / height;

  // ===== 基于 category 的尺寸方法 =====

  /// 获取内边距
  ///
  /// 基于 [category] 自动调整
  EdgeInsets getPadding() {
    final basePadding = switch (category) {
      SizeCategory.mini => 8.0,
      SizeCategory.small => 12.0,
      SizeCategory.medium => 14.0,
      SizeCategory.large => 16.0,
      SizeCategory.xlarge => 18.0,
    };
    return EdgeInsets.all(basePadding * padding);
  }

  /// 获取标题和列表之间的间距
  double getTitleSpacing() {
    final baseSpacing = switch (category) {
      SizeCategory.mini => 12.0,
      SizeCategory.small => 16.0,
      SizeCategory.medium => 20.0,
      SizeCategory.large => 24.0,
      SizeCategory.xlarge => 28.0,
    };
    return baseSpacing * spacing;
  }

  /// 获取高度约束
  BoxConstraints getHeightConstraints() {
    final (minHeight, maxHeight) = switch (category) {
      SizeCategory.mini => (80.0, 150.0),
      SizeCategory.small => (150.0, 280.0),
      SizeCategory.medium => (220.0, 380.0),
      SizeCategory.large => (300.0, 500.0),
      SizeCategory.xlarge => (400.0, 650.0),
    };
    return BoxConstraints(
      minHeight: minHeight * scale,
      maxHeight: maxHeight * scale,
    );
  }

  /// 获取列表项之间的间距
  double getItemSpacing() {
    final baseSpacing = switch (category) {
      SizeCategory.mini => 4.0,
      SizeCategory.small => 6.0,
      SizeCategory.medium => 8.0,
      SizeCategory.large => 10.0,
      SizeCategory.xlarge => 12.0,
    };
    return baseSpacing * spacing;
  }

  /// 获取图标大小
  double getIconSize() {
    final baseSize = switch (category) {
      SizeCategory.mini => 16.0,
      SizeCategory.small => 20.0,
      SizeCategory.medium => 24.0,
      SizeCategory.large => 28.0,
      SizeCategory.xlarge => 32.0,
    };
    return baseSize * iconSize;
  }

  /// 获取大字体大小
  double getLargeFontSize() {
    final baseSize = switch (category) {
      SizeCategory.mini => 24.0,
      SizeCategory.small => 32.0,
      SizeCategory.medium => 40.0,
      SizeCategory.large => 48.0,
      SizeCategory.xlarge => 56.0,
    };
    return baseSize * fontSize;
  }

  /// 获取标题字体大小
  double getTitleFontSize() {
    final baseSize = switch (category) {
      SizeCategory.mini => 14.0,
      SizeCategory.small => 16.0,
      SizeCategory.medium => 20.0,
      SizeCategory.large => 24.0,
      SizeCategory.xlarge => 28.0,
    };
    return baseSize * fontSize;
  }

  /// 获取副标题字体大小
  double getSubtitleFontSize() {
    final baseSize = switch (category) {
      SizeCategory.mini => 10.0,
      SizeCategory.small => 12.0,
      SizeCategory.medium => 14.0,
      SizeCategory.large => 16.0,
      SizeCategory.xlarge => 18.0,
    };
    return baseSize * fontSize;
  }

  /// 获取小间距（用于紧密元素之间）
  double getSmallSpacing() {
    final baseSpacing = switch (category) {
      SizeCategory.mini => 2.0,
      SizeCategory.small => 3.0,
      SizeCategory.medium => 4.0,
      SizeCategory.large => 5.0,
      SizeCategory.xlarge => 6.0,
    };
    return baseSpacing * spacing;
  }

  /// 获取图例指示器宽度
  double getLegendIndicatorWidth() {
    final baseSize = switch (category) {
      SizeCategory.mini => 12.0,
      SizeCategory.small => 16.0,
      SizeCategory.medium => 20.0,
      SizeCategory.large => 24.0,
      SizeCategory.xlarge => 28.0,
    };
    return baseSize * scale;
  }

  /// 获取图例指示器高度
  double getLegendIndicatorHeight() {
    final baseSize = switch (category) {
      SizeCategory.mini => 6.0,
      SizeCategory.small => 8.0,
      SizeCategory.medium => 10.0,
      SizeCategory.large => 12.0,
      SizeCategory.xlarge => 14.0,
    };
    return baseSize * scale;
  }

  /// 获取图例字体大小
  double getLegendFontSize() {
    final baseSize = switch (category) {
      SizeCategory.mini => 8.0,
      SizeCategory.small => 10.0,
      SizeCategory.medium => 12.0,
      SizeCategory.large => 14.0,
      SizeCategory.xlarge => 16.0,
    };
    return baseSize * fontSize;
  }

  /// 获取柱状图柱子宽度
  double getBarWidth() {
    final baseSize = switch (category) {
      SizeCategory.mini => 8.0,
      SizeCategory.small => 12.0,
      SizeCategory.medium => 16.0,
      SizeCategory.large => 20.0,
      SizeCategory.xlarge => 24.0,
    };
    return baseSize * scale;
  }

  /// 获取柱子之间的间距
  double getBarSpacing() {
    final baseSpacing = switch (category) {
      SizeCategory.mini => 0.3,
      SizeCategory.small => 0.5,
      SizeCategory.medium => 1.0,
      SizeCategory.large => 1.5,
      SizeCategory.xlarge => 2.0,
    };
    return baseSpacing * spacing;
  }

  /// 获取进度条线条粗细
  double getStrokeWidth() {
    final baseWidth = switch (category) {
      SizeCategory.mini => 4.0,
      SizeCategory.small => 6.0,
      SizeCategory.medium => 8.0,
      SizeCategory.large => 10.0,
      SizeCategory.xlarge => 12.0,
    };
    return baseWidth * strokeWidth;
  }

  /// 获取条形图列表容器高度
  double getRankedBarListHeight() {
    final baseHeight = switch (category) {
      SizeCategory.mini => 80.0,
      SizeCategory.small => 150.0,
      SizeCategory.medium => 220.0,
      SizeCategory.large => 300.0,
      SizeCategory.xlarge => 400.0,
    };
    return baseHeight * scale;
  }

  /// 获取单个条形图条目高度
  double getRankedBarItemHeight() {
    final baseHeight = switch (category) {
      SizeCategory.mini => 24.0,
      SizeCategory.small => 32.0,
      SizeCategory.medium => 40.0,
      SizeCategory.large => 48.0,
      SizeCategory.xlarge => 56.0,
    };
    return baseHeight * scale;
  }

  /// 获取条形图最大宽度（基础值，会根据 value 动态调整）
  double getRankedBarMaxWidth() {
    final baseWidth = switch (category) {
      SizeCategory.mini => 120.0,
      SizeCategory.small => 200.0,
      SizeCategory.medium => 280.0,
      SizeCategory.large => 360.0,
      SizeCategory.xlarge => 440.0,
    };
    return baseWidth * scale;
  }

  /// 获取热力图高度
  double getHeatmapHeight() {
    final baseHeight = switch (category) {
      SizeCategory.mini => 40.0,
      SizeCategory.small => 60.0,
      SizeCategory.medium => 100.0,
      SizeCategory.large => 140.0,
      SizeCategory.xlarge => 180.0,
    };
    return baseHeight * scale;
  }

  /// 获取图表宽度（基于实际布局需求）
  double getWidthForChart() {
    final baseWidth = switch (category) {
      SizeCategory.mini => 100.0,
      SizeCategory.small => 180.0,
      SizeCategory.medium => 260.0,
      SizeCategory.large => 340.0,
      SizeCategory.xlarge => 420.0,
    };
    return baseWidth * scale;
  }

  /// 获取图表高度
  double getHeightForChart() {
    final baseHeight = switch (category) {
      SizeCategory.mini => 60.0,
      SizeCategory.small => 100.0,
      SizeCategory.medium => 150.0,
      SizeCategory.large => 200.0,
      SizeCategory.xlarge => 250.0,
    };
    return baseHeight * scale;
  }

  /// 获取特色图片/缩略图尺寸（用于卡片封面）
  double getFeaturedImageSize() {
    final baseSize = switch (category) {
      SizeCategory.mini => 40.0,
      SizeCategory.small => 60.0,
      SizeCategory.medium => 80.0,
      SizeCategory.large => 100.0,
      SizeCategory.xlarge => 120.0,
    };
    return baseSize * scale;
  }

  /// 获取列表项缩略图尺寸
  double getThumbnailImageSize() {
    final baseSize = switch (category) {
      SizeCategory.mini => 24.0,
      SizeCategory.small => 36.0,
      SizeCategory.medium => 48.0,
      SizeCategory.large => 56.0,
      SizeCategory.xlarge => 64.0,
    };
    return baseSize * scale;
  }

  /// 获取特色图片图标尺寸
  double getFeaturedIconSize() {
    final baseSize = switch (category) {
      SizeCategory.mini => 20.0,
      SizeCategory.small => 28.0,
      SizeCategory.medium => 40.0,
      SizeCategory.large => 48.0,
      SizeCategory.xlarge => 56.0,
    };
    return baseSize * iconSize;
  }

  /// 获取列表项图标尺寸
  double getThumbnailIconSize() {
    final baseSize = switch (category) {
      SizeCategory.mini => 14.0,
      SizeCategory.small => 18.0,
      SizeCategory.medium => 24.0,
      SizeCategory.large => 28.0,
      SizeCategory.xlarge => 32.0,
    };
    return baseSize * iconSize;
  }

  /// 获取文章列表区域高度
  double getArticleListHeight() {
    final baseHeight = switch (category) {
      SizeCategory.mini => 120.0,
      SizeCategory.small => 200.0,
      SizeCategory.medium => 280.0,
      SizeCategory.large => 360.0,
      SizeCategory.xlarge => 450.0,
    };
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
