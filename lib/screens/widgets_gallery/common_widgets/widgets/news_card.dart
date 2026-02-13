import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import '../models/news_card_data.dart';
import '../utils/image_helper.dart';

const Color _defaultGoodsColor = Color.fromARGB(255, 207, 77, 116);

/// 新闻卡片小组件
/// 显示头条新闻、分类标签和新闻列表，支持动画效果
class NewsCardWidget extends StatefulWidget {
  /// 头条新闻
  final FeaturedNewsData featuredNews;

  /// 分类标签
  final String category;

  /// 新闻列表
  final List<NewsItemData> newsItems;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 组件尺寸
  final HomeWidgetSize size;

  const NewsCardWidget({
    super.key,
    required this.featuredNews,
    required this.category,
    required this.newsItems,
    this.inline = false,
    this.size = HomeWidgetSize.medium,
  });

  /// 从属性创建（用于动态渲染）
  factory NewsCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final data = NewsCardData.fromJson(props);
    return NewsCardWidget(
      featuredNews: data.featuredNews,
      category: data.category,
      newsItems: data.newsItems,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

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
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
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
    final textMainColor =
        isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final textSubColor =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

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
        width: widget.inline ? 300 : double.maxFinite,
        height: widget.inline ? 300 : double.maxFinite,
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
            Expanded(
              child: _buildNewsListSection(
                context,
                isDark: isDark,
                primaryColor: primaryColor,
                textMainColor: textMainColor,
                textSubColor: textSubColor,
              ),
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
    final hasImage = widget.featuredNews.imageUrl.isNotEmpty;
    final hasIcon = widget.featuredNews.iconCodePoint != null;

    return SizedBox(
      height: 150,
      child: Stack(
        children: [
          // 背景图片或图标
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              child:
                  hasImage
                      ? CommonImageBuilder.buildImage(
                        imageUrl: widget.featuredNews.imageUrl,
                        fit: BoxFit.cover,
                        isDark: isDark,
                      )
                      : hasIcon
                      ? Container(
                        color: Color(
                          widget.featuredNews.iconBackgroundColor ??
                              _defaultGoodsColor.value,
                        ),
                        child: Center(
                          child: Icon(
                            IconData(
                              widget.featuredNews.iconCodePoint!,
                              fontFamily: 'MaterialIcons',
                            ),
                            size: 80,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      )
                      : Container(
                        color:
                            isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                      ),
            ),
          ),
          // 渐变遮罩（只在有图片或图标时显示）
          if (hasImage || hasIcon)
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
            top: widget.size.getPadding().top,
            right: widget.size.getPadding().right,
            child: _buildActionButton(primaryColor),
          ),
          // 标题
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.size.getPadding().left * 2,
              ),
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

  /// 构建新闻项缩略图或图标
  Widget _buildNewsItemThumbnail(NewsItemData item, bool isDark) {
    final hasImage = item.imageUrl.isNotEmpty;
    final hasIcon = item.iconCodePoint != null;

    if (hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CommonImageBuilder.buildImage(
          imageUrl: item.imageUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          isDark: isDark,
        ),
      );
    }

    if (hasIcon) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Color(item.iconBackgroundColor ?? _defaultGoodsColor.value),
        ),
        child: Icon(
          IconData(item.iconCodePoint!, fontFamily: 'MaterialIcons'),
          color: Colors.white,
          size: 28,
        ),
      );
    }

    // 默认占位符
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      ),
      child: Icon(
        Icons.article,
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        size: 28,
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
        child: Icon(Icons.fingerprint_outlined, color: Colors.white, size: 20),
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
      padding: EdgeInsets.fromLTRB(
        widget.size.getPadding().left,
        widget.size.getPadding().top / 2,
        widget.size.getPadding().right,
        widget.size.getPadding().bottom,
      ),
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
          SizedBox(height: widget.size.getTitleSpacing()),
          // 新闻列表（带滚动条）
          Flexible(
            child: Scrollbar(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: widget.newsItems.length,
                itemBuilder: (context, index) {
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
                },
              ),
            ),
          ),
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
            padding: EdgeInsets.only(
              bottom: isLast ? 0 : widget.size.getItemSpacing(),
            ),
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
                      SizedBox(height: widget.size.getItemSpacing() / 2),
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
                SizedBox(width: widget.size.getItemSpacing() * 2),
                // 缩略图或图标
                _buildNewsItemThumbnail(item, isDark),
              ],
            ),
          ),
          if (!isLast)
            Divider(
              height: 1,
              thickness: 1,
              color:
                  isDark
                      ? const Color(0xFF374151).withOpacity(0.5)
                      : const Color(0xFFF3F4F6),
            ),
        ],
      ),
    );
  }
}
