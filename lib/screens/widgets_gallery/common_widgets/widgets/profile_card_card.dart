import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 个人资料卡片小组件
///
/// 用于展示用户个人信息，包括头像、姓名、简介、关注数等
class ProfileCardWidget extends StatefulWidget {
  /// 背景图片 URL
  final String imageUrl;

  /// 姓名
  final String name;

  /// 是否认证
  final bool isVerified;

  /// 简介
  final String bio;

  /// 粉丝数
  final int followersCount;

  /// 关注数
  final int followingCount;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 组件尺寸
  final HomeWidgetSize size;

  const ProfileCardWidget({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.isVerified,
    required this.bio,
    required this.followersCount,
    required this.followingCount,
    this.inline = false,
    this.size = HomeWidgetSize.medium,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory ProfileCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return ProfileCardWidget(
      imageUrl: props['imageUrl'] as String? ?? '',
      name: props['name'] as String? ?? 'Unknown',
      isVerified: props['isVerified'] as bool? ?? false,
      bio: props['bio'] as String? ?? '',
      followersCount: (props['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (props['followingCount'] as num?)?.toInt() ?? 0,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<ProfileCardWidget> createState() => _ProfileCardWidgetState();
}

class _ProfileCardWidgetState extends State<ProfileCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isFollowing = false;

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

  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.95 + 0.05 * _animation.value,
          child: Opacity(
            opacity: _animation.value,
            child: Container(
              width: widget.inline ? double.maxFinite : double.infinity,
              height: widget.inline ? double.maxFinite : double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // 背景图片
                  Positioned.fill(
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [const Color(0xFF1F2937), const Color(0xFF111827)]
                                  : [const Color(0xFFE5E7EB), const Color(0xFFF3F4F6)],
                            ),
                          ),
                        );
                      },
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
                            Colors.transparent,
                            Colors.transparent,
                            isDark
                                ? Colors.black.withOpacity(0.9)
                                : Colors.white.withOpacity(0.9),
                          ],
                          stops: const [0.0, 0.3, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // 底部渐变叠加
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 150,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDark
                              ? [
                                  Colors.black.withOpacity(0.9),
                                  Colors.black.withOpacity(0.6),
                                  Colors.black.withOpacity(0.95),
                                ]
                              : [
                                  Colors.white.withOpacity(0.8),
                                  Colors.white.withOpacity(0.4),
                                  Colors.white,
                                ],
                        ),
                      ),
                    ),
                  ),
                  // 内容
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Padding(
                      padding: widget.size.getPadding(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 姓名和认证标志
                          _NameSection(
                            name: widget.name,
                            isVerified: widget.isVerified,
                            animation: _animation,
                            size: widget.size,
                          ),
                          SizedBox(height: widget.size.getTitleSpacing()),
                          // 简介
                          _BioSection(
                            bio: widget.bio,
                            animation: _animation,
                            size: widget.size,
                          ),
                          SizedBox(height: widget.size.getItemSpacing()),
                          // 统计和关注按钮
                          _StatsAndFollowSection(
                            followersCount: widget.followersCount,
                            followingCount: widget.followingCount,
                            isFollowing: _isFollowing,
                            onFollowPressed: _toggleFollow,
                            animation: _animation,
                            size: widget.size,
                          ),
                        ],
                      ),
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

/// 姓名和认证标志部分
class _NameSection extends StatelessWidget {
  final String name;
  final bool isVerified;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _NameSection({
    required this.name,
    required this.isVerified,
    required this.animation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final nameAnimation = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
        );

        return Opacity(
          opacity: nameAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - nameAnimation.value)),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.grey.shade900,
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isVerified) ...[
                  SizedBox(width: size.getItemSpacing() * 0.375),
                  Container(
                    padding: EdgeInsets.all(size.getPadding().right * 0.125),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.green.shade900
                          : Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified,
                      size: 14,
                      color: isDark ? Colors.green.shade400 : Colors.green.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 简介部分
class _BioSection extends StatelessWidget {
  final String bio;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _BioSection({
    required this.bio,
    required this.animation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final bioAnimation = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
        );

        return Opacity(
          opacity: bioAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - bioAnimation.value)),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                bio,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 统计和关注按钮部分
class _StatsAndFollowSection extends StatelessWidget {
  final int followersCount;
  final int followingCount;
  final bool isFollowing;
  final VoidCallback onFollowPressed;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _StatsAndFollowSection({
    required this.followersCount,
    required this.followingCount,
    required this.isFollowing,
    required this.onFollowPressed,
    required this.animation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final statsAnimation = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
        );

        return Opacity(
          opacity: statsAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - statsAnimation.value)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 统计数据
                Row(
                  children: [
                    _StatItem(
                      icon: Icons.person_outline,
                      count: followersCount,
                      animation: statsAnimation,
                      isDark: isDark,
                      size: size,
                    ),
                    SizedBox(width: size.getItemSpacing()),
                    _StatItem(
                      icon: Icons.check_box_outline_blank,
                      count: followingCount,
                      animation: statsAnimation,
                      isDark: isDark,
                      size: size,
                    ),
                  ],
                ),
                // 关注按钮
                GestureDetector(
                  onTap: onFollowPressed,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: size.getPadding().right * 0.875,
                      vertical: size.getPadding().bottom * 0.375,
                    ),
                    decoration: BoxDecoration(
                      color: isFollowing
                          ? (isDark ? Colors.grey.shade800 : Colors.white)
                          : (isDark ? Colors.white : Colors.grey.shade900),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          isFollowing ? 'Following' : 'Follow',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isFollowing
                                ? (isDark ? Colors.white : Colors.grey.shade900)
                                : (isDark ? Colors.grey.shade900 : Colors.white),
                          ),
                        ),
                        if (!isFollowing) ...[
                          SizedBox(width: size.getPadding().right * 0.1875),
                          Icon(
                            Icons.add,
                            size: 14,
                            color: isDark ? Colors.grey.shade900 : Colors.white,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 统计项
class _StatItem extends StatelessWidget {
  final IconData icon;
  final int count;
  final Animation<double> animation;
  final bool isDark;
  final HomeWidgetSize size;

  const _StatItem({
    required this.icon,
    required this.count,
    required this.animation,
    required this.isDark,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
        ),
        SizedBox(width: size.getPadding().right * 0.25),
        AnimatedFlipCounter(
          value: count.toDouble() * animation.value,
          fractionDigits: 0,
          duration: const Duration(milliseconds: 600),
          textStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
