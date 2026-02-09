/// 新闻卡片数据模型
/// 用于新闻、资讯、公告等内容展示
class NewsCardData {
  /// 头条新闻
  final FeaturedNewsData featuredNews;

  /// 分类标签
  final String category;

  /// 新闻列表
  final List<NewsItemData> newsItems;

  const NewsCardData({
    required this.featuredNews,
    required this.category,
    required this.newsItems,
  });

  /// 从 JSON 创建
  factory NewsCardData.fromJson(Map<String, dynamic> json) {
    return NewsCardData(
      featuredNews: FeaturedNewsData.fromJson(
        json['featuredNews'] as Map<String, dynamic>? ?? {},
      ),
      category: json['category'] as String? ?? '',
      newsItems: (json['newsItems'] as List<dynamic>?)
              ?.map((e) => NewsItemData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'featuredNews': featuredNews.toJson(),
      'category': category,
      'newsItems': newsItems.map((e) => e.toJson()).toList(),
    };
  }
}

/// 头条新闻数据模型
class FeaturedNewsData {
  /// 图片 URL
  final String imageUrl;

  /// 标题
  final String title;

  /// 图标 codePoint（可选，当没有图片时使用）
  final int? iconCodePoint;

  /// 图标背景颜色（可选，配合 iconCodePoint 使用）
  final int? iconBackgroundColor;

  const FeaturedNewsData({
    required this.imageUrl,
    required this.title,
    this.iconCodePoint,
    this.iconBackgroundColor,
  });

  /// 从 JSON 创建
  factory FeaturedNewsData.fromJson(Map<String, dynamic> json) {
    return FeaturedNewsData(
      imageUrl: json['imageUrl'] as String? ?? '',
      title: json['title'] as String? ?? '',
      iconCodePoint: json['iconCodePoint'] as int?,
      iconBackgroundColor: json['iconBackgroundColor'] as int?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'title': title,
      if (iconCodePoint != null) 'iconCodePoint': iconCodePoint,
      if (iconBackgroundColor != null) 'iconBackgroundColor': iconBackgroundColor,
    };
  }
}

/// 新闻条目数据模型
class NewsItemData {
  /// 标题
  final String title;

  /// 时间（如 "26 hrs ago"）
  final String time;

  /// 缩略图 URL
  final String imageUrl;

  /// 图标 codePoint（可选，当没有图片时使用）
  final int? iconCodePoint;

  /// 图标背景颜色（可选，配合 iconCodePoint 使用）
  final int? iconBackgroundColor;

  const NewsItemData({
    required this.title,
    required this.time,
    required this.imageUrl,
    this.iconCodePoint,
    this.iconBackgroundColor,
  });

  /// 从 JSON 创建
  factory NewsItemData.fromJson(Map<String, dynamic> json) {
    return NewsItemData(
      title: json['title'] as String? ?? '',
      time: json['time'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      iconCodePoint: json['iconCodePoint'] as int?,
      iconBackgroundColor: json['iconBackgroundColor'] as int?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'time': time,
      'imageUrl': imageUrl,
      if (iconCodePoint != null) 'iconCodePoint': iconCodePoint,
      if (iconBackgroundColor != null) 'iconBackgroundColor': iconBackgroundColor,
    };
  }
}
