class CardSize {
  final int width;
  final int height;

  const CardSize({
    required this.width,
    required this.height,
  });

  // 从 Map 创建 CardSize 实例
  factory CardSize.fromMap(Map<String, dynamic> map) {
    return CardSize(
      width: map['width'] as int,
      height: map['height'] as int,
    );
  }

  // 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'width': width,
      'height': height,
    };
  }
}