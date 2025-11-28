class OverlayWindowDimensions {
  const OverlayWindowDimensions._();

  /// Overlay窗口折叠时的默认宽度
  static const int collapsedWidth = 200;

  /// Overlay窗口折叠时的默认高度
  static const int collapsedHeight = 200;

  /// 折叠窗口对应的双精度值（用于布局计算）
  static const double collapsedWidthDouble = 200.0;

  /// 折叠窗口对应的双精度值（用于布局计算）
  static const double collapsedHeightDouble = 200.0;

  /// 展开选项时额外的安全边距
  static const double outerPadding = 24.0;

  /// 展开状态下最小的窗口尺寸（避免子悬浮球挤在一起）
  static const double minExpandedSize = 360.0;
}
