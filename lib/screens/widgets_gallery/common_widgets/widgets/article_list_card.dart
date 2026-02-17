import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import '../utils/image_helper.dart';

const Color _defaultGoodsColor = Color.fromARGB(255, 207, 77, 116);

/// 特色文章数据模型
class FeaturedArticleData {
  final String author;
  final String title;
  final String summary;
  final String imageUrl;

  /// 图标 codePoint（可选，当没有图片时使用）
  final int? iconCodePoint;

  /// 图标背景颜色（可选，配合 iconCodePoint 使用）
  final int? iconBackgroundColor;

  const FeaturedArticleData({
    required this.author,
    required this.title,
    required this.summary,
    required this.imageUrl,
    this.iconCodePoint,
    this.iconBackgroundColor,
  });

  /// 从 JSON 创建
  factory FeaturedArticleData.fromJson(Map<String, dynamic> json) {
    return FeaturedArticleData(
      author: json['author'] as String? ?? '',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      iconCodePoint: json['iconCodePoint'] as int?,
      iconBackgroundColor: json['iconBackgroundColor'] as int?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'author': author,
      'title': title,
      'summary': summary,
      'imageUrl': imageUrl,
      if (iconCodePoint != null) 'iconCodePoint': iconCodePoint,
      if (iconBackgroundColor != null)
        'iconBackgroundColor': iconBackgroundColor,
    };
  }
}

/// 普通文章数据模型
class ArticleData {
  final String title;
  final String author;
  final String publication;
  final String imageUrl;

  /// 图标 codePoint（可选，当没有图片时使用）
  final int? iconCodePoint;

  /// 图标背景颜色（可选，配合 iconCodePoint 使用）
  final int? iconBackgroundColor;

  const ArticleData({
    required this.title,
    required this.author,
    required this.publication,
    required this.imageUrl,
    this.iconCodePoint,
    this.iconBackgroundColor,
  });

  /// 从 JSON 创建
  factory ArticleData.fromJson(Map<String, dynamic> json) {
    return ArticleData(
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      publication: json['publication'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      iconCodePoint: json['iconCodePoint'] as int?,
      iconBackgroundColor: json['iconBackgroundColor'] as int?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'publication': publication,
      'imageUrl': imageUrl,
      if (iconCodePoint != null) 'iconCodePoint': iconCodePoint,
      if (iconBackgroundColor != null)
        'iconBackgroundColor': iconBackgroundColor,
    };
  }
}

/// 文章列表卡片小组件
class ArticleListCardWidget extends StatefulWidget {
  final FeaturedArticleData featuredArticle;
  final List<ArticleData> articles;

  /// 小组件尺寸
  final HomeWidgetSize size;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  const ArticleListCardWidget({
    super.key,
    required this.featuredArticle,
    required this.articles,
    this.size = const MediumSize(),
    this.inline = false,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory ArticleListCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final featured =
        props['featuredArticle'] != null
            ? FeaturedArticleData.fromJson(
              props['featuredArticle'] as Map<String, dynamic>,
            )
            : const FeaturedArticleData(
              author: 'Darius Foroux',
              title: 'On the biggest prize in life',
              summary: 'To desire pleasure is to accept pain...',
              imageUrl: '',
            );

    final articlesList =
        (props['articles'] as List<dynamic>?)
            ?.map((e) => ArticleData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return ArticleListCardWidget(
      featuredArticle: featured,
      articles: articlesList,
      size: size,
      inline: props['inline'] as bool? ?? false,
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
        width: widget.inline ? double.maxFinite : null,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            Padding(
              padding: widget.size.getPadding(),
              child: _FeaturedSection(
                data: widget.featuredArticle,
                animation: _animation,
                size: widget.size,
              ),
            ),
            Expanded(
              child: Padding(
                padding: widget.size.getPadding(),
                child: _ArticleListSection(
                  articles: widget.articles,
                  animation: _animation,
                  size: widget.size,
                  isInline: widget.inline,
                ),
              ),
            ),
            SizedBox(height: widget.size.getTitleSpacing()),
          ],
        ),
      ),
    );
  }
}

class _FeaturedSection extends StatelessWidget {
  final FeaturedArticleData data;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _FeaturedSection({
    required this.data,
    required this.animation,
    required this.size,
  });

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
                    Icon(
                      Icons.local_fire_department,
                      color: primaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'POPULAR RIGHT NOW',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: size.getLegendFontSize() - 2,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        SizedBox(height: size.getItemSpacing()),
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
                    _buildFeaturedImageOrIcon(data, isDark),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.author.toUpperCase(),
                            style: TextStyle(
                              color:
                                  isDark
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF6B7280),
                              fontSize: size.getLegendFontSize() - 2,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: size.getSmallSpacing()),
                          Text(
                            data.title,
                            style: TextStyle(
                              color:
                                  isDark
                                      ? const Color(0xFFF9FAFB)
                                      : const Color(0xFF111827),
                              fontSize: size.getTitleFontSize(),
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: size.getSmallSpacing()),
                          Text(
                            data.summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  isDark
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF6B7280),
                              fontSize: size.getLegendFontSize(),
                              height: 1.3,
                            ),
                          ),
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

  /// 构建特色文章的图片或图标
  Widget _buildFeaturedImageOrIcon(FeaturedArticleData data, bool isDark) {
    final hasImage = data.imageUrl.isNotEmpty;
    final hasIcon = data.iconCodePoint != null;
    final imageSize = size.getFeaturedImageSize();
    final iconSize = size.getFeaturedIconSize();

    if (hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CommonImageBuilder.buildImage(
          imageUrl: data.imageUrl,
          width: imageSize,
          height: imageSize,
          fit: BoxFit.cover,
          defaultIcon: Icons.article,
          isDark: isDark,
        ),
      );
    }

    if (hasIcon) {
      return Container(
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Color(data.iconBackgroundColor ?? _defaultGoodsColor.value),
        ),
        child: Icon(
          IconData(data.iconCodePoint!, fontFamily: 'MaterialIcons'),
          color: Colors.white,
          size: iconSize,
        ),
      );
    }

    // 默认占位符
    return Container(
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      ),
      child: Icon(
        Icons.article,
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        size: iconSize,
      ),
    );
  }
}

class _ArticleListSection extends StatelessWidget {
  final List<ArticleData> articles;
  final Animation<double> animation;
  final HomeWidgetSize size;
  final bool isInline;

  const _ArticleListSection({
    required this.articles,
    required this.animation,
    required this.size,
    this.isInline = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
                    Icon(
                      Icons.feed,
                      color:
                          isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'NEW ARTICLES',
                      style: TextStyle(
                        color:
                            isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                        fontSize: size.getLegendFontSize() - 2,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        SizedBox(height: size.getItemSpacing()),
        Expanded(
          child:
              isInline
                  ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(articles.length, (index) {
                      return _ArticleListItem(
                        data: articles[index],
                        animation: animation,
                        index: index,
                        size: size,
                      );
                    }),
                  )
                  : Scrollbar(
                    thickness: 4,
                    radius: const Radius.circular(2),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(articles.length, (index) {
                          return _ArticleListItem(
                            data: articles[index],
                            animation: animation,
                            index: index,
                            size: size,
                          );
                        }),
                      ),
                    ),
                  ),
        ),
      ],
    );
  }
}

class _ArticleListItem extends StatelessWidget {
  final ArticleData data;
  final Animation<double> animation;
  final int index;
  final HomeWidgetSize size;

  const _ArticleListItem({
    required this.data,
    required this.animation,
    required this.index,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        0.2 + index * 0.1,
        0.6 + index * 0.1,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - itemAnimation.value)),
            child: Padding(
              padding: EdgeInsets.only(bottom: size.getItemSpacing()),
              child: Row(
                children: [
                  _buildArticleImageOrIcon(data, isDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                isDark
                                    ? const Color(0xFFF9FAFB)
                                    : const Color(0xFF111827),
                            fontSize: size.getSubtitleFontSize(),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: size.getSmallSpacing()),
                        Text(
                          '${data.author} in ${data.publication}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                isDark
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF6B7280),
                            fontSize: size.getLegendFontSize(),
                          ),
                        ),
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

  /// 构建文章列表项的图片或图标
  Widget _buildArticleImageOrIcon(ArticleData data, bool isDark) {
    final hasImage = data.imageUrl.isNotEmpty;
    final hasIcon = data.iconCodePoint != null;
    final imageSize = size.getThumbnailImageSize();
    final iconSize = size.getThumbnailIconSize();

    if (hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CommonImageBuilder.buildImage(
          imageUrl: data.imageUrl,
          width: imageSize,
          height: imageSize,
          fit: BoxFit.cover,
          defaultIcon: Icons.article,
          isDark: isDark,
        ),
      );
    }

    if (hasIcon) {
      return Container(
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Color(data.iconBackgroundColor ?? _defaultGoodsColor.value),
        ),
        child: Icon(
          IconData(data.iconCodePoint!, fontFamily: 'MaterialIcons'),
          color: Colors.white,
          size: iconSize,
        ),
      );
    }

    // 默认占位符
    return Container(
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      ),
      child: Icon(
        Icons.article,
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        size: iconSize,
      ),
    );
  }
}
