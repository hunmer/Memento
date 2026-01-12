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

  const FeaturedNewsData({
    required this.imageUrl,
    required this.title,
  });

  /// 从 JSON 创建
  factory FeaturedNewsData.fromJson(Map<String, dynamic> json) {
    return FeaturedNewsData(
      imageUrl: json['imageUrl'] as String? ?? '',
      title: json['title'] as String? ?? '',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'title': title,
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

  const NewsItemData({
    required this.title,
    required this.time,
    required this.imageUrl,
  });

  /// 从 JSON 创建
  factory NewsItemData.fromJson(Map<String, dynamic> json) {
    return NewsItemData(
      title: json['title'] as String? ?? '',
      time: json['time'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'time': time,
      'imageUrl': imageUrl,
    };
  }
}
