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
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左侧：头像和信息
                    _LeftSection(
                      avatarUrl: widget.avatarUrl,
                      name: widget.name,
                      handle: widget.handle,
                      followers: widget.followers,
                      primaryColor: primaryColor,
                      animation: _fadeInAnimation,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 20),
                    // 右侧：标签、内容、互动
                    _RightSection(
                      tag: widget.tag,
                      content: widget.content,
                      comments: widget.comments,
                      shares: widget.shares,
                      primaryColor: primaryColor,
                      animation: _fadeInAnimation,
                      isDark: isDark,
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
}

/// 左侧区域：头像、用户信息、粉丝数
class _LeftSection extends StatelessWidget {
  final String avatarUrl;
  final String name;
  final String handle;
  final int followers;
  final Color primaryColor;
  final Animation<double> animation;
  final bool isDark;

  const _LeftSection({
    required this.avatarUrl,
    required this.name,
    required this.handle,
    required this.followers,
    required this.primaryColor,
    required this.animation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像
          ClipOval(
            child: Image.network(
              avatarUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 32,
                    color: primaryColor,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // 用户名和账号
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                handle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const Spacer(),
          // 粉丝数
          _buildFollowerCounter(),
        ],
      ),
    );
  }

  Widget _buildFollowerCounter() {
    return Row(
      children: [
        Icon(
          Icons.group,
          size: 16,
          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 55,
          height: 16,
          child: AnimatedFlipCounter(
            value: followers * animation.value,
            fractionDigits: 0,
            prefix: followers >= 1000 ? '' : '',
            suffix: followers >= 1000 ? 'k' : '',
            valueScaler: followers >= 1000 ? 0.001 : 1,
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.0,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
        ),
        const SizedBox(width: 2),
        Text(
          'followers',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.0,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

/// 右侧区域：标签、内容、互动数据
class _RightSection extends StatelessWidget {
  final String tag;
  final String content;
  final int comments;
  final int shares;
  final Color primaryColor;
  final Animation<double> animation;
  final bool isDark;

  const _RightSection({
    required this.tag,
    required this.content,
    required this.comments,
    required this.shares,
    required this.primaryColor,
    required this.animation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final commentsAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    );
    final sharesAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
    );

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          // 标签
          GestureDetector(
            onTap: () {},
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // 内容
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          // 互动数据
          Row(
            children: [
              _buildInteractionItem(
                icon: Icons.chat_bubble_outline,
                value: comments,
                valueAnimation: commentsAnimation,
              ),
              const SizedBox(width: 24),
              _buildInteractionItem(
                icon: Icons.cached,
                value: shares,
                valueAnimation: sharesAnimation,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionItem({
    required IconData icon,
    required int value,
    required Animation<double> valueAnimation,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 45,
          height: 14,
          child: AnimatedFlipCounter(
            value: value * valueAnimation.value,
            fractionDigits: 0,
            prefix: value >= 1000 ? '' : '',
            suffix: value >= 1000 ? 'k' : '',
            valueScaler: value >= 1000 ? 0.001 : 1,
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.0,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }
}
