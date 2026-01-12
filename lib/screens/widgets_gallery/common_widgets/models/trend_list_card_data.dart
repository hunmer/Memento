/// 趋势列表卡片数据模型
/// 用于股票、指数、价格等带有趋势变化的列表数据
class TrendListCardData {
  /// 卡片标题
  final String title;

  /// 卡片图标
  final String iconName;

  /// 趋势项列表
  final List<TrendItemData> items;

  const TrendListCardData({
    required this.title,
    required this.iconName,
    required this.items,
  });

  /// 从 JSON 创建
  factory TrendListCardData.fromJson(Map<String, dynamic> json) {
    return TrendListCardData(
      title: json['title'] as String? ?? '',
      iconName: json['iconName'] as String? ?? 'trending_up',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => TrendItemData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'iconName': iconName,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

/// 趋势项数据模型
class TrendItemData {
  /// 符号/名称（如股票代码、指数名称）
  final String symbol;

  /// 当前数值
  final double value;

  /// 变化百分比
  final double percentChange;

  /// 变化数值
  final double valueChange;

  /// 是否为正向变化（上涨）
  final bool isPositive;

  const TrendItemData({
    required this.symbol,
    required this.value,
    required this.percentChange,
    required this.valueChange,
    required this.isPositive,
  });

  /// 从 JSON 创建
  factory TrendItemData.fromJson(Map<String, dynamic> json) {
    return TrendItemData(
      symbol: json['symbol'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      percentChange: (json['percentChange'] as num?)?.toDouble() ?? 0.0,
      valueChange: (json['valueChange'] as num?)?.toDouble() ?? 0.0,
      isPositive: json['isPositive'] as bool? ?? true,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'value': value,
      'percentChange': percentChange,
      'valueChange': valueChange,
      'isPositive': isPositive,
    };
  }
}
