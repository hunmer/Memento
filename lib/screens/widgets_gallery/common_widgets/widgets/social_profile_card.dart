import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 社交资料卡片小组件
class SocialProfileCardWidget extends StatefulWidget {
  /// 头像 URL
  final String avatarUrl;

  /// 用户名
  final String name;

  /// 账号
  final String handle;

  /// 粉丝数
  final int followers;

  /// 帖子数
  final int posts;

  /// 标签
  final String tag;

  /// 内容
  final String content;

  /// 评论数
  final int comments;

  /// 转发数
  final int shares;
  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;
  /// 小组件尺寸
  final HomeWidgetSize size;

  const SocialProfileCardWidget({
    super.key,
    required this.avatarUrl,
    required this.name,
    required this.handle,
    required this.followers,
    required this.posts,
    required this.tag,
    required this.content,
    required this.comments,
    required this.shares,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例
  factory SocialProfileCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return SocialProfileCardWidget(
      avatarUrl: props['avatarUrl'] as String? ?? '',
      name: props['name'] as String? ?? '',
      handle: props['handle'] as String? ?? '',
      followers: (props['followers'] as num?)?.toInt() ?? 0,
      posts: (props['posts'] as num?)?.toInt() ?? 0,
      tag: props['tag'] as String? ?? '',
      content: props['content'] as String? ?? '',
      comments: (props['comments'] as num?)?.toInt() ?? 0,
      shares: (props['shares'] as num?)?.toInt() ?? 0,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<SocialProfileCardWidget> createState() =>
      _SocialProfileCardWidgetState();
}

class _SocialProfileCardWidgetState extends State<SocialProfileCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeInAnimation = CurvedAnimation(
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
    final primaryColor = isDark
        ? const Color(0xFF5078E1)
        : Theme.of(context).colorScheme.primary.withOpacity(0.9);

    return AnimatedBuilder(
      animation: _fadeInAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeInAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _fadeInAnimation.value)),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: widget.size.getPadding(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 顶部：头像和用户信息
                    _buildHeader(isDark, primaryColor),
                    SizedBox(height: widget.size.getItemSpacing()),
                    // 标签
                    _buildTag(primaryColor),
                    SizedBox(height: widget.size.getItemSpacing()),
                    // 内容
                    _buildContent(isDark),
                    SizedBox(height: widget.size.getTitleSpacing()),
                    // 底部：四个统计信息
                    _buildStats(isDark),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark, Color primaryColor) {
    return Row(
      children: [
        ClipOval(
          child: Image.network(
            widget.avatarUrl,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  size: 28,
                  color: primaryColor,
                ),
              );
            },
          ),
        ),
        SizedBox(width: widget.size.getItemSpacing()),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.handle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTag(Color primaryColor) {
    return Text(
      widget.tag,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: primaryColor,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildContent(bool isDark) {
    return Text(
      widget.content,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStats(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          icon: Icons.group,
          value: widget.followers,
          label: 'followers',
          animation: _fadeInAnimation,
          isDark: isDark,
        ),
        _buildStatItem(
          icon: Icons.article,
          value: widget.posts,
          label: 'posts',
          animation: _fadeInAnimation,
          isDark: isDark,
        ),
        _buildStatItem(
          icon: Icons.chat_bubble_outline,
          value: widget.comments,
          label: 'comments',
          animation: _fadeInAnimation,
          isDark: isDark,
        ),
        _buildStatItem(
          icon: Icons.cached,
          value: widget.shares,
          label: 'shares',
          animation: _fadeInAnimation,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required int value,
    required String label,
    required Animation<double> animation,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: widget.size.getIconSize(),
          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
        ),
        SizedBox(height: widget.size.getItemSpacing() / 2),
        AnimatedFlipCounter(
          value: (value >= 1000 ? value * 0.001 : value) * animation.value,
          fractionDigits: value >= 1000 ? 1 : 0,
          prefix: value >= 1000 ? '' : '',
          suffix: value >= 1000 ? 'k' : '',
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.0,
            color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
          ),
        ),
        SizedBox(height: widget.size.getItemSpacing() / 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.0,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}
