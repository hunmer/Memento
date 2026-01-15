import 'package:flutter/material.dart';

/// 主页小组件尺寸枚举
enum HomeWidgetSize {
  /// 1x1 小图标组件
  small(1, 1),

  /// 2x1 横向卡片
  medium(2, 1),

  /// 2x2 大卡片
  large(2, 2),

  /// 2x3 高卡片（宽度2，高度3）
  large3(2, 3),

  /// 4x1 宽屏卡片（占满所有宽度）
  wide(4, 1),

  /// 4x2 全宽卡片（占满所有宽度，高度2）
  wide2(4, 2),

  /// 4x3 全宽卡片（占满所有宽度，高度3）
  wide3(4, 3),

  /// 自定义尺寸（支持任意宽高，通过 customWidth/customHeight 设置）
  custom(-1, -1);

  /// 宽度（占用的网格列数）
  final int width;

  /// 高度（占用的网格行数）
  final int height;

  const HomeWidgetSize(this.width, this.height);

  /// 从宽高转换为枚举
  static HomeWidgetSize fromSize(int width, int height) {
    return HomeWidgetSize.values.firstWhere(
      (size) => size.width == width && size.height == height,
      orElse: () => HomeWidgetSize.large,
    );
  }

  /// 转换为 JSON
  ///
  /// 对于 custom 尺寸，需要传入 [actualWidth] 和 [actualHeight] 参数
  /// 来保存实际的宽高值（因为 custom 的 width/height 固定为 -1）
  Map<String, dynamic> toJson({int? actualWidth, int? actualHeight}) {
    // 如果是 custom 尺寸且提供了实际宽高，保存实际值
    if (this == HomeWidgetSize.custom) {
      return {
        'width': actualWidth ?? width,
        'height': actualHeight ?? height,
      };
    }
    return {
      'width': width,
      'height': height,
    };
  }

  /// 从 JSON 加载
  ///
  /// 自动检测 custom 尺寸：如果宽高不匹配任何预定义尺寸，
  /// 且 JSON 中包含有效的宽高值，则返回 HomeWidgetSize.custom，
  /// 并将实际宽高保存在可选参数中供调用方使用。
  ///
  /// 返回值：如果是 custom 尺寸，返回值可能包含额外的实际宽高信息
  static HomeWidgetSize fromJson(
    Map<String, dynamic> json, {
    int? outActualWidth,
    int? outActualHeight,
  }) {
    final width = json['width'] as int;
    final height = json['height'] as int;

    // 尝试匹配预定义尺寸
    for (final size in HomeWidgetSize.values) {
      if (size.width == width && size.height == height) {
        return size;
      }
    }

    // 不匹配任何预定义尺寸，返回 custom
    // 注意：由于 enum 的限制，这里仍然返回 custom(-1, -1)
    // 调用方应该使用 JSON 中的原始宽高值
    return HomeWidgetSize.custom;
  }

  /// 从 JSON 加载并返回实际宽高
  ///
  /// 这是一个辅助方法，用于从 JSON 中获取尺寸和实际宽高
  /// 返回一个包含 size 和可选实际宽高的 Map
  static Map<String, dynamic> fromJsonWithData(Map<String, dynamic> json) {
    final width = json['width'] as int;
    final height = json['height'] as int;

    // 尝试匹配预定义尺寸
    for (final size in HomeWidgetSize.values) {
      if (size.width == width && size.height == height) {
        return {'size': size};
      }
    }

    // 不匹配任何预定义尺寸，返回 custom 并记录实际宽高
    return {
      'size': HomeWidgetSize.custom,
      'actualWidth': width,
      'actualHeight': height,
    };
  }

  /// 判断当前尺寸是否至少与指定尺寸一样大
  ///
  /// 比较逻辑：宽度 >= other.width 且高度 >= other.height
  ///
  /// 示例：
  /// ```dart
  /// // 普通尺寸比较
  /// HomeWidgetSize.large.isAtLeast(HomeWidgetSize.medium); // true
  /// HomeWidgetSize.small.isAtLeast(HomeWidgetSize.medium); // false
  ///
  /// // custom 尺寸比较（需要传入实际宽高）
  /// HomeWidgetSize.custom.isAtLeast(
  ///   HomeWidgetSize.medium,
  ///   actualWidth: 3,
  ///   actualHeight: 2,
  /// ); // true (3 >= 2 && 2 >= 1)
  /// ```
  bool isAtLeast(
    HomeWidgetSize other, {
    int? actualWidth,
    int? actualHeight,
  }) {
    final thisWidth = this == HomeWidgetSize.custom ? (actualWidth ?? width) : width;
    final thisHeight = this == HomeWidgetSize.custom ? (actualHeight ?? height) : height;
    return thisWidth >= other.width && thisHeight >= other.height;
  }

  /// 判断当前尺寸是否大于指定尺寸
  ///
  /// 比较逻辑：宽度 > other.width 或高度 > other.height
  bool isLargerThan(
    HomeWidgetSize other, {
    int? actualWidth,
    int? actualHeight,
  }) {
    final thisWidth = this == HomeWidgetSize.custom ? (actualWidth ?? width) : width;
    final thisHeight = this == HomeWidgetSize.custom ? (actualHeight ?? height) : height;
    return thisWidth > other.width || thisHeight > other.height;
  }

  /// 判断当前尺寸是否等于指定尺寸
  bool isEqualTo(
    HomeWidgetSize other, {
    int? actualWidth,
    int? actualHeight,
  }) {
    final thisWidth = this == HomeWidgetSize.custom ? (actualWidth ?? width) : width;
    final thisHeight = this == HomeWidgetSize.custom ? (actualHeight ?? height) : height;
    return thisWidth == other.width && thisHeight == other.height;
  }

  /// 获取内边距
  EdgeInsets getPadding() {
    switch (this) {
      case HomeWidgetSize.small:
        return const EdgeInsets.all(8);
      case HomeWidgetSize.medium:
        return const EdgeInsets.all(12);
      case HomeWidgetSize.large:
      case HomeWidgetSize.large3:
        return const EdgeInsets.all(16);
      case HomeWidgetSize.wide:
        return const EdgeInsets.all(12);
      case HomeWidgetSize.wide2:
      case HomeWidgetSize.wide3:
        return const EdgeInsets.all(16);
      case HomeWidgetSize.custom:
        return const EdgeInsets.all(12);
    }
  }

  /// 获取标题和列表之间的间距
  double getTitleSpacing() {
    switch (this) {
      case HomeWidgetSize.small:
        return 16;
      case HomeWidgetSize.medium:
        return 20;
      case HomeWidgetSize.large:
      case HomeWidgetSize.large3:
        return 24;
      case HomeWidgetSize.wide:
        return 20;
      case HomeWidgetSize.wide2:
      case HomeWidgetSize.wide3:
        return 24;
      case HomeWidgetSize.custom:
        return 20;
    }
  }

  /// 获取高度约束
  BoxConstraints getHeightConstraints() {
    switch (this) {
      case HomeWidgetSize.small:
        return const BoxConstraints(minHeight: 150, maxHeight: 250);
      case HomeWidgetSize.medium:
        return const BoxConstraints(minHeight: 200, maxHeight: 350);
      case HomeWidgetSize.large:
        return const BoxConstraints(minHeight: 250, maxHeight: 450);
      case HomeWidgetSize.large3:
        return const BoxConstraints(minHeight: 350, maxHeight: 600);
      case HomeWidgetSize.wide:
        return const BoxConstraints(minHeight: 200, maxHeight: 350);
      case HomeWidgetSize.wide2:
        return const BoxConstraints(minHeight: 250, maxHeight: 450);
      case HomeWidgetSize.wide3:
        return const BoxConstraints(minHeight: 350, maxHeight: 600);
      case HomeWidgetSize.custom:
        return const BoxConstraints(minHeight: 200, maxHeight: 350);
    }
  }

  /// 获取列表项之间的间距
  double getItemSpacing() {
    switch (this) {
      case HomeWidgetSize.small:
        return 6;
      case HomeWidgetSize.medium:
        return 8;
      case HomeWidgetSize.large:
      case HomeWidgetSize.large3:
        return 12;
      case HomeWidgetSize.wide:
        return 8;
      case HomeWidgetSize.wide2:
      case HomeWidgetSize.wide3:
        return 12;
      case HomeWidgetSize.custom:
        return 8;
    }
  }
}
