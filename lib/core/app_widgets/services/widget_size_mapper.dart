import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/core/app_widgets/models/ios_widget_config.dart';

/// iOS 小组件尺寸映射服务
///
/// 提供 HomeWidgetSize 和 IOSWidgetSize 之间的双向映射
class WidgetSizeMapper {
  // 私有构造函数，防止实例化
  WidgetSizeMapper._();

  /// HomeWidgetSize 到 IOSWidgetSize 的映射
  ///
  /// 映射规则：
  /// - SmallSize (1x1) -> iOS small
  /// - MediumSize (2x1) -> iOS wide (systemMedium)
  /// - LargeSize (2x2), Large3Size (2x3) -> iOS large
  /// - WideSize (4x1), Wide2Size (4x2), Wide3Size (4x3) -> iOS wide 或 large
  static IOSWidgetSize homeToIOS(HomeWidgetSize size) {
    // 1x1 映射到 small
    if (size.width == 1 && size.height == 1) {
      return IOSWidgetSize.small;
    }

    // 2x2 或更大正方形映射到 large
    if (size.width >= 2 && size.height >= 2 && size.isSquare) {
      return IOSWidgetSize.large;
    }

    // 宽型组件 (宽度 > 高度)
    if (size.isWide) {
      // 4x1 或 4x2 映射到 wide
      if (size.width >= 4) {
        return IOSWidgetSize.wide;
      }
      // 2x1 映射到 wide
      return IOSWidgetSize.wide;
    }

    // 高型组件 (高度 > 宽度)
    if (size.isTall) {
      return IOSWidgetSize.large;
    }

    // 默认返回 small
    return IOSWidgetSize.small;
  }

  /// IOSWidgetSize 到 HomeWidgetSize 的映射
  ///
  /// 返回适合 iOS 小组件尺寸的 HomeWidgetSize
  static HomeWidgetSize iosToHome(IOSWidgetSize size) {
    return switch (size) {
      IOSWidgetSize.small => const SmallSize(),
      IOSWidgetSize.wide => const WideSize(),
      IOSWidgetSize.large => const LargeSize(),
    };
  }

  /// 获取 iOS 小组件支持的 HomeWidgetSize 列表
  ///
  /// 用于在配置页面过滤可用的尺寸选项
  static List<HomeWidgetSize> getSupportedHomeWidgetSizes(
    IOSWidgetSize iosSize,
    List<HomeWidgetSize> availableSizes,
  ) {
    final targetSize = iosToHome(iosSize);

    // 查找与目标尺寸匹配或更大的组件
    return availableSizes.where((size) {
      return _isSizeCompatible(size, targetSize);
    }).toList();
  }

  /// 检查尺寸是否兼容
  static bool _isSizeCompatible(HomeWidgetSize size, HomeWidgetSize target) {
    // 精确匹配
    if (size.width == target.width && size.height == target.height) {
      return true;
    }

    // iOS small 只接受 1x1
    if (target.width == 1 && target.height == 1) {
      return size.width == 1 && size.height == 1;
    }

    // iOS wide 接受 2x1, 4x1, 4x2
    if (target.width == 4 && target.height == 1) {
      return (size.width >= 2 && size.height == 1) ||
          (size.width >= 4 && size.height == 2);
    }

    // iOS large 接受 2x2 或更大的正方形/高型
    if (target.width == 2 && target.height == 2) {
      return size.width >= 2 && size.height >= 2;
    }

    return false;
  }

  /// 获取 iOS 小组件的推荐渲染尺寸（像素）
  ///
  /// 基于 iPhone 14 Pro @3x 的像素密度
  static Size getRenderPixelSize(IOSWidgetSize size, {double pixelRatio = 3.0}) {
    return switch (size) {
      IOSWidgetSize.small => Size(170 * pixelRatio, 170 * pixelRatio),
      IOSWidgetSize.wide => Size(364 * pixelRatio, 170 * pixelRatio),
      IOSWidgetSize.large => Size(364 * pixelRatio, 382 * pixelRatio),
    };
  }

  /// 获取 iOS 小组件的逻辑尺寸（点）
  static Size getLogicalSize(IOSWidgetSize size) {
    return switch (size) {
      IOSWidgetSize.small => const Size(170, 170),
      IOSWidgetSize.wide => const Size(364, 170),
      IOSWidgetSize.large => const Size(364, 382),
    };
  }

  /// 检查 HomeWidget 是否支持指定的 iOS 尺寸
  static bool isIOSSizeSupported(
    List<HomeWidgetSize> supportedSizes,
    IOSWidgetSize iosSize,
  ) {
    final targetHomeSize = iosToHome(iosSize);

    for (final size in supportedSizes) {
      if (_isSizeCompatible(size, targetHomeSize)) {
        return true;
      }
    }

    return false;
  }

  /// 获取可用的 iOS 尺寸列表
  ///
  /// 基于 HomeWidget 支持的尺寸返回可用的 iOS 尺寸
  static List<IOSWidgetSize> getAvailableIOSSizes(
    List<HomeWidgetSize> supportedSizes,
  ) {
    final result = <IOSWidgetSize>[];

    for (final iosSize in IOSWidgetSize.values) {
      if (isIOSSizeSupported(supportedSizes, iosSize)) {
        result.add(iosSize);
      }
    }

    // 如果没有匹配的，默认支持 small
    if (result.isEmpty) {
      result.add(IOSWidgetSize.small);
    }

    return result;
  }
}

/// HomeWidget 尺寸相关工具扩展
extension HomeWidgetSizeIOSExtension on HomeWidgetSize {
  /// 获取图标大小
  double getIOSIconSize() {
    return getIconSize();
  }

  /// 获取标题字体大小
  double getIOSTitleFontSize() {
    return getTitleFontSize();
  }
}
