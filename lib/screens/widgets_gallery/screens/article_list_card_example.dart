import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/article_list_card.dart';

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
              summary: 'To desire pleasure is to accept pain. Because at some point, you become addicted to...',
              imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBlEyajraqqpBf6RXGVdQEIw0jU4213ckBc7GGF5w7hnca11ioavmtKJO0OGFvL7UBT36uLFu4zaCo5I5Xo2lXKzdeySWvJn6n5zIwC2_3zXbNpeMGdEOBMgDFxUOH1yZdNAOtQQ02iPWyx54bnubRtma_qgdLm9hsKMr4ENTI97B0anJfyuNH8t3-ETJwFu_-NeosA0PoxRgKPHsfDfM6PixiIX1HAhq5BgXH6H6Oyz_AYaahDm8LmS-J1uU0G6m5s5sVIUjvczZL5',
            ),
            articles: [
              ArticleData(
                title: 'Feeling Bored at Work?',
                author: 'Hoang Nguyen',
                publication: 'Prototyper',
                imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAoqy2X2o2QPOHJjtGGh-7Gnau_JxA0ibdAumLO2ZRMhMXSPuZMlBKbUHmu6JZEL9MC60T-MMGHvo6C-MCnYgpEecrCflMRZL2tahKsYwm7bUN6syhwlc7Ghoi7reXNWbkR4NPDf6lKFZwMlr158O5ffv-UW3ZDnPhxCDZWFhC7p2ElVFozisz-AaHQIFiWsFjNzAyMxvcoTPge_MtvnAQtIslYbZm0DTb9BE_X7uueMTqquuO1-4k9Dttn0DB9GEdaOOCxPaG1-Sga',
              ),
              ArticleData(
                title: '5 Money Books You Need To Read In...',
                author: 'Jari Roomer',
                publication: 'WealthWise',
                imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCAbVBNndlUlI8SEj6g-OATjFQJc6uUguM4zWh5lfIh9EpnqBp-kMFehrtoTWP4O_0B-cPoNsrWDlU543GIJfIyDJCejedKXeEjXjUGYRaOd6obWhRVDxY1zLrbDBegV-Q_1WhQ4OoG3FDIiYNuTUoBXvWNIwYFaxPK8jpHaa_Hhi-1eV_WvaEEdXswt8EGrQfG7WLQTFbTLNcXRScTs1Cta3maih7a7oN4E1qQgeLSRIj97bEuGYKR9Tt-gQDae5YLCMeTiFTxE8Pm',
              ),
              ArticleData(
                title: 'Everything macOS has gotten right in the...',
                author: 'Joseph Mavericks',
                publication: 'UX Collective',
                imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAhXFkk8fq1S8NOBOoQ_-5sJs4_znnwqyM_QYe2foVzXW94CklEC_77lkGz0KatVEH0RbcHBJRiUjK_P-d15WBtjBrLh2DeJTHyng8lIAdUr2EgVhhy7YvtUVyNqkOiJvUm3XCvz6kBoBh3j7O7x-z8rzxlBf7kIC_AHAFRWTjMdDD8A-3WLnsW_mscu0O5yfaUHBiEWTKwrwTj0tMh9bEEdlAlxzdzfBcIGtkFGGQz-TNILtEMo4YaBRkRrvJAFq-f3-IT6b-bX4TB',
              ),
              ArticleData(
                title: 'Writing for global audiences',
                author: 'Susanna Zaraysky',
                publication: 'Google Design',
                imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuD6KABFHDvf-OJ91ym-BlBCJyQVOu9huxnIKUqO8Nb83qArhaBdHRLZWt94nmuaqXVP9oIkm7sY6pPYnHfiTXCkR3Knd4HvSuKL4C1yvVVnugUhs-J3hE3SQ4eFYdY9sF2ohcMhKYWCzJXXOVZlzNUhTQ1ic3nxjb9fmcptTNGNt-m_ECB8WyDin6UL1OlyIO9bux7XIaNrdxS_xRMvbWsGG7J3xknpg2ltFkipD7HXbdfqjVQqO_J-gpbDcA1OGSpFkxwDVlukQWq6',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
