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
  /// 小组件尺寸
  final HomeWidgetSize size;

  const SocialActivityCardWidget({
    super.key,
    required this.user,
    required this.posts,
    this.inline = false,
    this.size = HomeWidgetSize.medium,
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
      size: size,
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
            offset: Offset(0, (widget.size == HomeWidgetSize.small ? 15 : 20) * (1 - _animation.value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: widget.inline ? double.maxFinite : (widget.size == HomeWidgetSize.small ? 280 : 375),
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
                height: widget.size == HomeWidgetSize.small ? 72 : 96,
                width: double.infinity,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF3F4F9),
              ),
              // 内容区域
              Padding(
                padding: widget.size.getPadding(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 头像（负边距上移）
                    Transform.translate(
                      offset: Offset(0, widget.size == HomeWidgetSize.small ? -36 : -48),
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
                          radius: widget.size == HomeWidgetSize.small ? 36 : 48,
                          backgroundImage: NetworkImage(widget.user.avatarUrl),
                        ),
                      ),
                    ),
                    SizedBox(height: widget.size.getItemSpacing()),
                    // 用户信息
                    _UserHeader(
                      user: widget.user,
                      size: widget.size,
                    ),
                    SizedBox(height: widget.size.getTitleSpacing()),
                    // 动态列表
                    ...widget.posts.asMap().entries.map((entry) {
                      final index = entry.key;
                      final post = entry.value;
                      return _PostItem(
                        post: post,
                        animation: _animation,
                        index: index + 1,
                        size: widget.size,
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
  final HomeWidgetSize size;

  const _UserHeader({
    required this.user,
    required this.size,
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
                  fontSize: size == HomeWidgetSize.small ? 18 : 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  height: 1.2,
                ),
              ),
              SizedBox(height: size.getItemSpacing() / 2),
              Text(
                user.username,
                style: TextStyle(
                  fontSize: size == HomeWidgetSize.small ? 12 : 14,
                  fontWeight: FontWeight.w500,
                  color: primaryColor,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: size.getItemSpacing()),
        Row(
          children: [
            Icon(
              Icons.group_outlined,
              size: size.getIconSize(),
              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
            ),
            SizedBox(width: size.getItemSpacing() / 2),
            SizedBox(
              height: size.getIconSize() - 2,
              child: Text(
                _formatFollowerCount(user.followerCount),
                style: TextStyle(
                  fontSize: size == HomeWidgetSize.small ? 12 : 14,
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
  final HomeWidgetSize size;

  const _PostItem({
    required this.post,
    required this.animation,
    required this.index,
    required this.size,
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
            offset: Offset(0, (size == HomeWidgetSize.small ? 15 : 20) * (1 - itemAnimation.value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: size.getTitleSpacing()),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 话题标签
            Text(
              post.hashtag,
              style: TextStyle(
                fontSize: size == HomeWidgetSize.small ? 13 : 15,
                fontWeight: FontWeight.w600,
                color: primaryColor,
                height: 1.0,
              ),
            ),
            SizedBox(height: size.getItemSpacing()),
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
                          fontSize: size == HomeWidgetSize.small ? 13 : 15,
                          color: isDark
                              ? const Color(0xFFE5E7EB)
                              : const Color(0xFF1F2937),
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: size.getItemSpacing() + 4),
                      // 互动数据
                      Row(
                        children: [
                          _InteractionItem(
                            icon: Icons.chat_bubble_outline,
                            count: post.commentCount,
                            color: primaryColor,
                            animation: itemAnimation,
                            size: size,
                          ),
                          SizedBox(width: size.getTitleSpacing()),
                          _InteractionItem(
                            icon: Icons.restart_alt,
                            count: post.repostCount,
                            color: const Color(0xFF10B981),
                            animation: itemAnimation,
                            iconTransform: 90,
                            size: size,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: size.getTitleSpacing()),
                // 图片
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    post.imageUrl,
                    width: size == HomeWidgetSize.small ? 60 : 80,
                    height: size == HomeWidgetSize.small ? 60 : 80,
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
  final HomeWidgetSize size;

  const _InteractionItem({
    required this.icon,
    required this.count,
    required this.color,
    required this.animation,
    this.iconTransform,
    required this.size,
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
            size: size.getIconSize(),
            color: baseColor,
          ),
        ),
        SizedBox(width: size.getItemSpacing() / 1),
        SizedBox(
          height: size.getIconSize() - 6,
          child: AnimatedFlipCounter(
            value: count * animation.value,
            fractionDigits: count >= 1000 ? 1 : 0,
            textStyle: TextStyle(
              fontSize: size == HomeWidgetSize.small ? 10 : 12,
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
