import 'package:flutter/material.dart';

/// 新闻卡片示例
class NewsCardExample extends StatelessWidget {
  const NewsCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('新闻卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: NewsCardWidget(
            featuredNews: FeaturedNewsData(
              imageUrl:
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDv5gxvSgmJi-EJnx1jpWIpatry-RBKJyPObZyjHGF4-dpstaoze49i8tJFHbm3FOGPd2LNfrxsIt6W5g4qO1YfXAYs6ZVYy2GA78hSeLg1pAm2khF7Z5hO5NCICS2kSwHjgA5diQ8bCI6-IdSKXJxszm4VL2Fq4uCx3rbOzM_OYO_AO6sFN2ew-KJaE3U3xyYbqX-7Z5P7ippdNtDWdpZDfWXETGhR087NeReVoMb6Xf8_Zf-uQ2kXVzCAKZ4wkiflAg-3sYRMbQ',
              title: 'Hacker Leaks From Netflix Show Threatens Networks',
            ),
            category: 'Latest news',
            newsItems: [
              NewsItemData(
                title: 'Cody Brown Has a Broad Vision for Virtual Reality',
                time: '26 hrs ago',
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuA4bhNi8gKGFeCyMYb8-ry8Uf4QLPszrY1ZXtnxdE_kGEUm_kXgutv3zEtoLws1ch65y_Uxq1IJYl4TBe2X4Fg20L8Kma7rJ0VUS5k0fux5ECK4wP8GJC34ODtVLdrtWhus4VDRInJN8NzrM-AcOHHaCEt50tQfwMSD6tQEPaWvaE8ww-EXx1FBYAaU3NLK7UeXg8zblqPPV64qXL_WJnCwMx3WlPTOcZ2nb1wGKl6CUvYaisxupGZyn1QPr2wJvZEh-2KCGgXd1Q',
              ),
              NewsItemData(
                title: 'Visa Applications Pour In by Truckload Before Door',
                time: '29 hrs ago',
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuA_MHiN7St5tuKKxJmnX2fWLFiH1TnKauia8M8rChdMABchAWsC9DhfrFNMP7a1zvbVM6ypKB2R6-ZHnOxWEzHXVxH3uoqNnoAUVNVUQ4SjroiaZuEi6Mj_eQcmBWxtxxRCdgPUW0zzfkNPyNDVqkqSGQ780Yhn-i7xnL1S7ulNFupLPi1fw0f24cgKW92Vo-EanJvPI4nFSsL4PR7K8I2Z6IcdtDssZHs0MLLA6bxTZ5g-gDkg4lpv7cURh3hUI0gnivnNmAoLnA',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 头条新闻数据模型
class FeaturedNewsData {
  final String imageUrl;
  final String title;

  const FeaturedNewsData({
    required this.imageUrl,
    required this.title,
  });
}

/// 新闻条目数据模型
class NewsItemData {
  final String title;
  final String time;
  final String imageUrl;

  const NewsItemData({
    required this.title,
    required this.time,
    required this.imageUrl,
  });
}

/// 新闻卡片小组件
class NewsCardWidget extends StatefulWidget {
  /// 头条新闻
  final FeaturedNewsData featuredNews;

  /// 分类标签
  final String category;

  /// 新闻列表
  final List<NewsItemData> newsItems;

  const NewsCardWidget({
    super.key,
    required this.featuredNews,
    required this.category,
    required this.newsItems,
  });

  @override
  State<NewsCardWidget> createState() => _NewsCardWidgetState();
}

class _NewsCardWidgetState extends State<NewsCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
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
    final backgroundColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final primaryColor = const Color(0xFFFBC05B);
    final textMainColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final textSubColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: child,
          ),
        );
      },
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头条新闻图片区域
            _buildFeaturedNewsSection(
              context,
              isDark: isDark,
              primaryColor: primaryColor,
              textMainColor: textMainColor,
            ),
            // 新闻列表区域
            _buildNewsListSection(
              context,
              isDark: isDark,
              primaryColor: primaryColor,
              textMainColor: textMainColor,
              textSubColor: textSubColor,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建头条新闻区域
  Widget _buildFeaturedNewsSection(
    BuildContext context, {
    required bool isDark,
    required Color primaryColor,
    required Color textMainColor,
  }) {
    return SizedBox(
      height: 256,
      child: Stack(
        children: [
          // 背景图片
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              child: Image.network(
                widget.featuredNews.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  );
                },
              ),
            ),
          ),
          // 渐变遮罩
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark
                        ? const Color(0xFF1F2937).withOpacity(0)
                        : Colors.white.withOpacity(0),
                    isDark
                        ? const Color(0xFF1F2937).withOpacity(0.6)
                        : Colors.white.withOpacity(0.6),
                    isDark ? const Color(0xFF1F2937) : Colors.white,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // 右上角装饰按钮
          Positioned(
            top: 16,
            right: 16,
            child: _buildActionButton(primaryColor),
          ),
          // 标题
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                widget.featuredNews.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textMainColor,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建装饰按钮
  Widget _buildActionButton(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(
          Icons.fingerprint_outlined,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  /// 构建新闻列表区域
  Widget _buildNewsListSection(
    BuildContext context, {
    required bool isDark,
    required Color primaryColor,
    required Color textMainColor,
    required Color textSubColor,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分类标签
          Text(
            widget.category,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              letterSpacing: 1.0,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // 新闻列表
          ...List.generate(widget.newsItems.length, (index) {
            final item = widget.newsItems[index];
            return _buildNewsItem(
              context,
              item: item,
              isLast: index == widget.newsItems.length - 1,
              isDark: isDark,
              textMainColor: textMainColor,
              textSubColor: textSubColor,
              index: index,
            );
          }),
        ],
      ),
    );
  }

  /// 构建单条新闻
  Widget _buildNewsItem(
    BuildContext context, {
    required NewsItemData item,
    required bool isLast,
    required bool isDark,
    required Color textMainColor,
    required Color textSubColor,
    required int index,
  }) {
    final itemAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        0.15 + index * 0.1,
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
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Row(
              children: [
                // 文本内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textMainColor,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.time,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textSubColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // 缩略图
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 56,
                        height: 56,
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (!isLast)
            Divider(
              height: 1,
              thickness: 1,
              color: isDark
                  ? const Color(0xFF374151).withOpacity(0.5)
                  : const Color(0xFFF3F4F6),
            ),
        ],
      ),
    );
  }
}
