import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 特色文章数据模型
class FeaturedArticleData {
  final String author;
  final String title;
  final String summary;
  final String imageUrl;

  const FeaturedArticleData({
    required this.author,
    required this.title,
    required this.summary,
    required this.imageUrl,
  });

  /// 从 JSON 创建
  factory FeaturedArticleData.fromJson(Map<String, dynamic> json) {
    return FeaturedArticleData(
      author: json['author'] as String? ?? '',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'author': author,
      'title': title,
      'summary': summary,
      'imageUrl': imageUrl,
    };
  }
}

/// 普通文章数据模型
class ArticleData {
  final String title;
  final String author;
  final String publication;
  final String imageUrl;

  const ArticleData({
    required this.title,
    required this.author,
    required this.publication,
    required this.imageUrl,
  });

  /// 从 JSON 创建
  factory ArticleData.fromJson(Map<String, dynamic> json) {
    return ArticleData(
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      publication: json['publication'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'publication': publication,
      'imageUrl': imageUrl,
    };
  }
}

/// 文章列表卡片小组件
class ArticleListCardWidget extends StatefulWidget {
  final FeaturedArticleData featuredArticle;
  final List<ArticleData> articles;

  const ArticleListCardWidget({
    super.key,
    required this.featuredArticle,
    required this.articles,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory ArticleListCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final featured = props['featuredArticle'] != null
        ? FeaturedArticleData.fromJson(props['featuredArticle'] as Map<String, dynamic>)
        : const FeaturedArticleData(
            author: 'Darius Foroux',
            title: 'On the biggest prize in life',
            summary: 'To desire pleasure is to accept pain...',
            imageUrl: '',
          );

    final articlesList = (props['articles'] as List<dynamic>?)
            ?.map((e) => ArticleData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return ArticleListCardWidget(
      featuredArticle: featured,
      articles: articlesList,
    );
  }

  @override
  State<ArticleListCardWidget> createState() => _ArticleListCardWidgetState();
}

class _ArticleListCardWidgetState extends State<ArticleListCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: 375,
        height: 600,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _FeaturedSection(
                data: widget.featuredArticle,
                animation: _animation,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ArticleListSection(
                articles: widget.articles,
                animation: _animation,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _FeaturedSection extends StatelessWidget {
  final FeaturedArticleData data;
  final Animation<double> animation;

  const _FeaturedSection({required this.data, required this.animation});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final sectionAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.5, curve: Curves.easeOutCubic),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: sectionAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: sectionAnimation.value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - sectionAnimation.value)),
                child: Row(
                  children: [
                    Icon(Icons.local_fire_department, color: primaryColor, size: 18),
                    const SizedBox(width: 6),
                    Text('POPULAR RIGHT NOW', style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: sectionAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: sectionAnimation.value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - sectionAnimation.value)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        data.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.article, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data.author.toUpperCase(), style: TextStyle(color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(data.title, style: TextStyle(color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827), fontSize: 16, fontWeight: FontWeight.w700, height: 1.2)),
                          const SizedBox(height: 4),
                          Text(data.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280), fontSize: 11, height: 1.3)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ArticleListSection extends StatelessWidget {
  final List<ArticleData> articles;
  final Animation<double> animation;

  const _ArticleListSection({required this.articles, required this.animation});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final headerAnimation = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.15, 0.5, curve: Curves.easeOutCubic),
            );
            return Opacity(
              opacity: headerAnimation.value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - headerAnimation.value)),
                child: Row(
                  children: [
                    Icon(Icons.feed, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280), size: 16),
                    const SizedBox(width: 6),
                    Text('NEW ARTICLES', style: TextStyle(color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        ...List.generate(articles.length, (index) {
          return _ArticleListItem(data: articles[index], animation: animation, index: index);
        }),
      ],
    );
  }
}

class _ArticleListItem extends StatelessWidget {
  final ArticleData data;
  final Animation<double> animation;
  final int index;

  const _ArticleListItem({
    required this.data,
    required this.animation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(0.2 + index * 0.1, 0.6 + index * 0.1, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - itemAnimation.value)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      data.imageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.article, size: 24, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827), fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('${data.author} in ${data.publication}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280), fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
