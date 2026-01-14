import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import '../models/social_activity_card_data.dart';

/// 社交活动动态卡片小组件
///
/// 显示用户信息和社交动态列表，支持动画效果和互动数据展示
class SocialActivityCardWidget extends StatefulWidget {
  final SocialUser user;
  final List<SocialPost> posts;
  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  const SocialActivityCardWidget({
    super.key,
    required this.user,
    required this.posts,
    this.inline = false,
  });

  /// 从属性映射创建组件
  factory SocialActivityCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final data = props['data'] is SocialActivityCardData
        ? props['data'] as SocialActivityCardData
        : SocialActivityCardData.defaultData;

    return SocialActivityCardWidget(
      user: data.user,
      posts: data.posts,
      inline: props['inline'] as bool? ?? false,
    );
  }

  @override
  State<SocialActivityCardWidget> createState() =>
      _SocialActivityCardWidgetState();
}

class _SocialActivityCardWidgetState extends State<SocialActivityCardWidget>
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
        width: widget.inline ? double.maxFinite : 375,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部背景区域
              Container(
                height: 96,
                width: double.infinity,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF3F4F9),
              ),
              // 内容区域
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 头像（负边距上移）
                    Transform.translate(
                      offset: const Offset(0, -48),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            width: 6,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundImage: NetworkImage(widget.user.avatarUrl),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    // 用户信息
                    _UserHeader(
                      user: widget.user,
                    ),
                    const SizedBox(height: 24),
                    // 动态列表
                    ...widget.posts.asMap().entries.map((entry) {
                      final index = entry.key;
                      final post = entry.value;
                      return _PostItem(
                        post: post,
                        animation: _animation,
                        index: index + 1,
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 用户信息头部
class _UserHeader extends StatelessWidget {
  final SocialUser user;

  const _UserHeader({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user.username,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: primaryColor,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            Icon(
              Icons.group_outlined,
              size: 18,
              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 4),
            SizedBox(
              height: 16,
              child: Text(
                _formatFollowerCount(user.followerCount),
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatFollowerCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k followers';
    }
    return '$count followers';
  }
}

/// 动态列表项
class _PostItem extends StatelessWidget {
  final SocialPost post;
  final Animation<double> animation;
  final int index;

  const _PostItem({
    required this.post,
    required this.animation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        index * 0.15,
        0.6 + index * 0.15,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - itemAnimation.value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 话题标签
            Text(
              post.hashtag,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: primaryColor,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            // 内容和图片
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.content,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? const Color(0xFFE5E7EB)
                              : const Color(0xFF1F2937),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 互动数据
                      Row(
                        children: [
                          _InteractionItem(
                            icon: Icons.chat_bubble_outline,
                            count: post.commentCount,
                            color: primaryColor,
                            animation: itemAnimation,
                          ),
                          const SizedBox(width: 20),
                          _InteractionItem(
                            icon: Icons.restart_alt,
                            count: post.repostCount,
                            color: const Color(0xFF10B981),
                            animation: itemAnimation,
                            iconTransform: 90,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // 图片
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    post.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 互动数据项
class _InteractionItem extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  final Animation<double> animation;
  final double? iconTransform;

  const _InteractionItem({
    required this.icon,
    required this.count,
    required this.color,
    required this.animation,
    this.iconTransform,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

    return Row(
      children: [
        Transform.rotate(
          angle: iconTransform != null ? iconTransform! * 3.14159 / 180 : 0,
          child: Icon(
            icon,
            size: 18,
            color: baseColor,
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          height: 12,
          child: AnimatedFlipCounter(
            value: count * animation.value,
            fractionDigits: count >= 1000 ? 1 : 0,
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: baseColor,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}
