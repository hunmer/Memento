import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

/// 个人资料卡片示例
class ProfileCardWidgetExample extends StatelessWidget {
  const ProfileCardWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('个人资料卡片')),
      body: Container(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
        child: const Center(
          child: ProfileCardWidget(
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuAQa5mwNY07R4lgli2Pgrxz3J9D6F6Plz6c9LGFNt4BYe9qp7wGfu6OnEFI-UAnneZ-qsWObIYUU_LVIN9_RypXCavX3hG7YUVTVgYgYhQiHXBBfy_W5EtO3oCjLBQ2eNlXRXxiKMEcC_tGq7UHLix8Zm7_Zawt0dvlp6ouuGhSkraBr9hjl6hKfAC5CL8rTgObw-xh-DnmtLVs5Msvp8N6dZgasjTEMmwR8or2JI6MCsXD0i43ZVNUATo21RHx95nyAFAf5zJuuDyg',
            name: 'Sophie Bennett',
            isVerified: true,
            bio: 'Product Designer who focuses on simplicity & usability.',
            followersCount: 312,
            followingCount: 48,
          ),
        ),
      ),
    );
  }
}

/// 个人资料卡片小组件
class ProfileCardWidget extends StatefulWidget {
  final String imageUrl;
  final String name;
  final bool isVerified;
  final String bio;
  final int followersCount;
  final int followingCount;

  const ProfileCardWidget({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.isVerified,
    required this.bio,
    required this.followersCount,
    required this.followingCount,
  });

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
              width: 360,
              height: 600,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(48),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
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
                    height: 250,
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
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 姓名和认证标志
                          _NameSection(
                            name: widget.name,
                            isVerified: widget.isVerified,
                            animation: _animation,
                          ),
                          const SizedBox(height: 8),
                          // 简介
                          _BioSection(
                            bio: widget.bio,
                            animation: _animation,
                          ),
                          const SizedBox(height: 32),
                          // 统计和关注按钮
                          _StatsAndFollowSection(
                            followersCount: widget.followersCount,
                            followingCount: widget.followingCount,
                            isFollowing: _isFollowing,
                            onFollowPressed: _toggleFollow,
                            animation: _animation,
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

  const _NameSection({
    required this.name,
    required this.isVerified,
    required this.animation,
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
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                    letterSpacing: -0.5,
                  ),
                ),
                if (isVerified) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.green.shade900
                          : Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified,
                      size: 18,
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

  const _BioSection({
    required this.bio,
    required this.animation,
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
              width: 220,
              child: Text(
                bio,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  height: 1.4,
                ),
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

  const _StatsAndFollowSection({
    required this.followersCount,
    required this.followingCount,
    required this.isFollowing,
    required this.onFollowPressed,
    required this.animation,
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
                    ),
                    const SizedBox(width: 24),
                    _StatItem(
                      icon: Icons.check_box_outline_blank,
                      count: followingCount,
                      animation: statsAnimation,
                      isDark: isDark,
                    ),
                  ],
                ),
                // 关注按钮
                GestureDetector(
                  onTap: onFollowPressed,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isFollowing
                          ? (isDark ? Colors.grey.shade800 : Colors.white)
                          : (isDark ? Colors.white : Colors.grey.shade900),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          isFollowing ? 'Following' : 'Follow',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isFollowing
                                ? (isDark ? Colors.white : Colors.grey.shade900)
                                : (isDark ? Colors.grey.shade900 : Colors.white),
                          ),
                        ),
                        if (!isFollowing) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.add,
                            size: 18,
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

  const _StatItem({
    required this.icon,
    required this.count,
    required this.animation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
        ),
        const SizedBox(width: 6),
        AnimatedFlipCounter(
          value: count.toDouble() * animation.value,
          fractionDigits: 0,
          duration: const Duration(milliseconds: 600),
          textStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
