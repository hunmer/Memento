import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

/// 社交资料卡片示例
class SocialProfileCardExample extends StatelessWidget {
  const SocialProfileCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('社交资料卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFF6B7280),
        child: const Center(
          child: SocialProfileCardWidget(
            avatarUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuDQBpvx8sVdqYMemqByF96wLVYDtKW2gysxp-DEVKMyV3MGBTO-SsYubZDkdx5YssNyEMNJt6kvNtVYwQcVPx5B_mWC8_-MjNgJneO5473aTTjd1qXZfgDNP6VeWyC_C84X-Bp7lNiLH1tILc1wpNs41UWjaBbQDyDvaPqVEPVQelJXoG5ULoGdueUtFJNSli1Ld1TpetG4-BdTLbjtKH0Zfusp7suNwuqNbbeI2QIExxTTHzhIq474K8TdUTKrDO3Pe01o91TWNw',
            name: 'Sammy Lawson',
            handle: '@CoRay',
            followers: 3600,
            posts: 248,
            tag: '#technology',
            content: "It's incredible to see art, creativity and technology come together celebration",
            comments: 3600,
            shares: 12000,
          ),
        ),
      ),
    );
  }
}

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
  });

  @override
  State<SocialProfileCardWidget> createState() => _SocialProfileCardWidgetState();
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
              width: 400,
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 顶部：头像和用户信息
                    Row(
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
                        const SizedBox(width: 12),
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
                                  color:
                                      isDark
                                          ? const Color(0xFFF9FAFB)
                                          : const Color(0xFF111827),
                                ),
                              ),
                              Text(
                                widget.handle,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                  color:
                                      isDark
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 标签
                    Text(
                      widget.tag,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 内容
                    Text(
                      widget.content,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        color:
                            isDark
                                ? const Color(0xFFD1D5DB)
                                : const Color(0xFF4B5563),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    // 底部：四个统计信息对称对齐
                    Row(
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
        ),
        const SizedBox(height: 4),
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
        const SizedBox(height: 2),
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
