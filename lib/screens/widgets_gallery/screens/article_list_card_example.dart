import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

/// 文章列表卡片示例
class ArticleListCardExample extends StatelessWidget {
  const ArticleListCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('文章列表卡片')),
      body: Container(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
        child: const Center(
          child: ArticleListCardWidget(
            featuredArticle: FeaturedArticleData(
              author: 'Darius Foroux',
              title: 'On the biggest prize in life',
              summary:
                  'To desire pleasure is to accept pain. Because at some point, you become addicted to...',
              imageUrl:
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuBlEyajraqqpBf6RXGVdQEIw0jU4213ckBc7GGF5w7hnca11ioavmtKJO0OGFvL7UBT36uLFu4zaCo5I5Xo2lXKzdeySWvJn6n5zIwC2_3zXbNpeMGdEOBMgDFxUOH1yZdNAOtQQ02iPWyx54bnubRtma_qgdLm9hsKMr4ENTI97B0anJfyuNH8t3-ETJwFu_-NeosA0PoxRgKPHsfDfM6PixiIX1HAhq5BgXH6H6Oyz_AYaahDm8LmS-J1uU0G6m5s5sVIUjvczZL5',
            ),
            articles: [
              ArticleData(
                title: 'Feeling Bored at Work?',
                author: 'Hoang Nguyen',
                publication: 'Prototyper',
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuAoqy2X2o2QPOHJjtGGh-7Gnau_JxA0ibdAumLO2ZRMhMXSPuZMlBKbUHmu6JZEL9MC60T-MMGHvo6C-MCnYgpEecrCflMRZL2tahKsYwm7bUN6syhwlc7Ghoi7reXNWbkR4NPDf6lKFZwMlr158O5ffv-UW3ZDnPhxCDZWFhC7p2ElVFozisz-AaHQIFiWsFjNzAyMxvcoTPge_MtvnAQtIslYbZm0DTb9BE_X7uueMTqquuO1-4k9Dttn0DB9GEdaOOCxPaG1-Sga',
              ),
              ArticleData(
                title: '5 Money Books You Need To Read In...',
                author: 'Jari Roomer',
                publication: 'WealthWise',
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCAbVBNndlUlI8SEj6g-OATjFQJc6uUguM4zWh5lfIh9EpnqBp-kMFehrtoTWP4O_0B-cPoNsrWDlU543GIJfIyDJCejedKXeEjXjUGYRaOd6obWhRVDxY1zLrbDBegV-Q_1WhQ4OoG3FDIiYNuTUoBXvWNIwYFaxPK8jpHaa_Hhi-1eV_WvaEEdXswt8EGrQfG7WLQTFbTLNcXRScTs1Cta3maih7a7oN4E1qQgeLSRIj97bEuGYKR9Tt-gQDae5YLCMeTiFTxE8Pm',
              ),
              ArticleData(
                title: 'Everything macOS has gotten right in the...',
                author: 'Joseph Mavericks',
                publication: 'UX Collective',
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuAhXFkk8fq1S8NOBOoQ_-5sJs4_znnwqyM_QYe2foVzXW94CklEC_77lkGz0KatVEH0RbcHBJRiUjK_P-d15WBtjBrLh2DeJTHyng8lIAdUr2EgVhhy7YvtUVyNqkOiJvUm3XCvz6kBoBh3j7O7x-z8rzxlBf7kIC_AHAFRWTjMdDD8A-3WLnsW_mscu0O5yfaUHBiEWTKwrwTj0tMh9bEEdlAlxzdzfBcIGtkFGGQz-TNILtEMo4YaBRkRrvJAFq-f3-IT6b-bX4TB',
              ),
              ArticleData(
                title: 'Writing for global audiences',
                author: 'Susanna Zaraysky',
                publication: 'Google Design',
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuD6KABFHDvf-OJ91ym-BlBCJyQVOu9huxnIKUqO8Nb83qArhaBdHRLZWt94nmuaqXVP9oIkm7sY6pPYnHfiTXCkR3Knd4HvSuKL4C1yvVVnugUhs-J3hE3SQ4eFYdY9sF2ohcMhKYWCzJXXOVZlzNUhTQ1ic3nxjb9fmcptTNGNt-m_ECB8WyDin6UL1OlyIO9bux7XIaNrdxS_xRMvbWsGG7J3xknpg2ltFkipD7HXbdfqjVQqO_J-gpbDcA1OGSpFkxwDVlukQWq6',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

/// 特色文章区域
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
                        fontSize: 10,
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
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.article,
                              color:
                                  isDark
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade400,
                            ),
                          );
                        },
                      ),
                    ),
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
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.title,
                            style: TextStyle(
                              color:
                                  isDark
                                      ? const Color(0xFFF9FAFB)
                                      : const Color(0xFF111827),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  isDark
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF6B7280),
                              fontSize: 11,
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
}

/// 文章列表区域
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
                        fontSize: 10,
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
        const SizedBox(height: 12),
        ...List.generate(articles.length, (index) {
          return _ArticleListItem(
            data: articles[index],
            animation: animation,
            index: index,
          );
        }),
      ],
    );
  }
}

/// 文章列表项
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
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.article,
                            size: 24,
                            color:
                                isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400,
                          ),
                        );
                      },
                    ),
                  ),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${data.author} in ${data.publication}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                isDark
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF6B7280),
                            fontSize: 11,
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
}
