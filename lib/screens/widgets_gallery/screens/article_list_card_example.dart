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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('小尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 200,
                    child: ArticleListCardWidget(
                      featuredArticle: FeaturedArticleData(
                        author: 'Darius Foroux',
                        title: 'On the biggest prize in life',
                        summary: 'To desire pleasure is to accept pain...',
                        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBlEyajraqqpBf6RXGVdQEIw0jU4213ckBc7GGF5w7hnca11ioavmtKJO0OGFvL7UBT36uLFu4zaCo5I5Xo2lXKzdeySWvJn6n5zIwC2_3zXbNpeMGdEOBMgDFxUOH1yZdNAOtQQ02iPWyx54bnubRtma_qgdLm9hsKMr4ENTI97B0anJfyuNH8t3-ETJwFu_-NeosA0PoxRgKPHsfDfM6PixiIX1HAhq5BgXH6H6Oyz_AYaahDm8LmS-J1uU0G6m5s5sVIUjvczZL5',
                      ),
                      articles: const [],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 250,
                    height: 300,
                    child: ArticleListCardWidget(
                      featuredArticle: FeaturedArticleData(
                        author: 'Darius Foroux',
                        title: 'On the biggest prize in life',
                        summary: 'To desire pleasure is to accept pain...',
                        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBlEyajraqqpBf6RXGVdQEIw0jU4213ckBc7GGF5w7hnca11ioavmtKJO0OGFvL7UBT36uLFu4zaCo5I5Xo2lXKzdeySWvJn6n5zIwC2_3zXbNpeMGdEOBMgDFxUOH1yZdNAOtQQ02iPWyx54bnubRtma_qgdLm9hsKMr4ENTI97B0anJfyuNH8t3-ETJwFu_-NeosA0PoxRgKPHsfDfM6PixiIX1HAhq5BgXH6H6Oyz_AYaahDm8LmS-J1uU0G6m5s5sVIUjvczZL5',
                      ),
                      articles: [
                        ArticleData(
                          title: 'Feeling Bored at Work?',
                          author: 'Hoang Nguyen',
                          publication: 'Prototyper',
                          imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAoqy2X2o2QPOHJjtGGh-7Gnau_JxA0ibdAumLO2ZRMhMXSPuZMlBKbUHmu6JZEL9MC60T-MMGHvo6C-MCnYgpEecrCflMRZL2tahKsYwm7bUN6syhwlc7Ghoi7reXNWbkR4NPDf6lKFZwMlr158O5ffv-UW3ZDnPhxCDZWFhC7p2ElVFozisz-AaHQIFiWsFjNzAyMxvcoTPge_MtvnAQtIslYbZm0DTb9BE_X7uueMTqquuO1-4k9Dttn0DB9GEdaOOCxPaG1-Sga',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 300,
                  child: ArticleListCardWidget(
                    featuredArticle: FeaturedArticleData(
                      author: 'Darius Foroux',
                      title: 'On the biggest prize in life',
                      summary: 'To desire pleasure is to accept pain...',
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
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 350,
                    height: 400,
                    child: ArticleListCardWidget(
                      featuredArticle: FeaturedArticleData(
                        author: 'Darius Foroux',
                        title: 'On the biggest prize in life',
                        summary: 'To desire pleasure is to accept pain. Because at some point, you become addicted to...',
                        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBlEyajraqqpBf6RXGVdQEIw0jU4213ckBc7GGF5w7hnca11ioavmtKJO0OGFvL7UBT36uLFu4zaCo5I5Xo2lXKzdeySWvJn6n5zIwC2_3zXbNpeMGdEOBMgDFxUOH1yZdNAOtQQ02iPWyx54bnubRtma_qgdLm9hsKMr4ENTI97B0anJfyuNH8t3-ETJwFu_-NeosA0PoxRgKPHsfDfM6PixiIX1HAhq5BgXH6H6Oyz_AYaahDm8LmS-J1uU0G6m5s5sVIUjvczZL5',
                      ),
                      articles: const [
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 400,
                  child: ArticleListCardWidget(
                    featuredArticle: FeaturedArticleData(
                      author: 'Darius Foroux',
                      title: 'On the biggest prize in life',
                      summary: 'To desire pleasure is to accept pain. Because at some point, you become addicted to living a disciplined life.',
                      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBlEyajraqqpBf6RXGVdQEIw0jU4213ckBc7GGF5w7hnca11ioavmtKJO0OGFvL7UBT36uLFu4zaCo5I5Xo2lXKzdeySWvJn6n5zIwC2_3zXbNpeMGdEOBMgDFxUOH1yZdNAOtQQ02iPWyx54bnubRtma_qgdLm9hsKMr4ENTI97B0anJfyuNH8t3-ETJwFu_-NeosA0PoxRgKPHsfDfM6PixiIX1HAhq5BgXH6H6Oyz_AYaahDm8LmS-J1uU0G6m5s5sVIUjvczZL5',
                    ),
                    articles: const [
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
                        title: 'How to Build a Morning Routine',
                        author: 'Sarah Johnson',
                        publication: 'Productivity',
                        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAoqy2X2o2QPOHJjtGGh-7Gnau_JxA0ibdAumLO2ZRMhMXSPuZMlBKbUHmu6JZEL9MC60T-MMGHvo6C-MCnYgpEecrCflMRZL2tahKsYwm7bUN6syhwlc7Ghoi7reXNWbkR4NPDf6lKFZwMlr158O5ffv-UW3ZDnPhxCDZWFhC7p2ElVFozisz-AaHQIFiWsFjNzAyMxvcoTPge_MtvnAQtIslYbZm0DTb9BE_X7uueMTqquuO1-4k9Dttn0DB9GEdaOOCxPaG1-Sga',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      ),
    );
  }
}
