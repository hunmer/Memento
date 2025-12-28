/// 主页小组件尺寸枚举
enum HomeWidgetSize {
  /// 1x1 小图标组件
  small(1, 1),

  /// 2x1 横向卡片
  medium(2, 1),

  /// 2x2 大卡片
  large(2, 2),

  /// 4x1 宽屏卡片（占满所有宽度）
  wide(4, 1),

  /// 4x2 全宽卡片（占满所有宽度，高度2）
  wide2(4, 2),

  /// 4x3 全宽卡片（占满所有宽度，高度3）
  wide3(4, 3);

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
  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
  };

  /// 从 JSON 加载
  static HomeWidgetSize fromJson(Map<String, dynamic> json) {
    return fromSize(json['width'] as int, json['height'] as int);
  }
}
