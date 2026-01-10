import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

/// 社交活动动态卡片示例
class SocialActivityCardExample extends StatelessWidget {
  const SocialActivityCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('社交活动动态卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: SocialActivityCardWidget(
            user: SocialUser(
              name: 'Sammy Lawson',
              username: '@CoRay',
              avatarUrl:
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDzpJQv6FKOjR43geXnHpsz8Npw1GNObnjUa4a3rMQMhzgh_Ve97KVQFW2t3lmVLLpxubY1Ij4YjjtZja3z1gx65I9Z-nhCYBZ9BvLuskC7U8Sw_3XzG0JPVacFep_ILPA18Xzs4yfFMKnCahkfdVUbs02DabzlfaajQAqdlz2HpOOA8RSmsUDDVuvexDm3FSCTBEWNnmqrT3WUQcz0HFRaIGdRRirVYatc5fUOPzltq8H7dNLxkzrbMheMDzFe-Ljb4_HjIBos9A',
              followerCount: 3600,
            ),
            posts: [
              SocialPost(
                hashtag: '#iphone',
                content: 'It\'s incredible to see art, creativity and technology come together in celebration',
                commentCount: 3600,
                repostCount: 12000,
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDv-L2GqLDB3xFsxjxb-FZwDal1ZHLI_iIfHb2QF0ikj7mDKw_uXQBE0SDqqd8v_UTM-S3b_TfJP9xvcHVXstPR6dA00hqTl4QXeEzf0w0kkoq6pPgX9wJ-Jyw4TScj-Jxhk4Ztcw8TGBKqEHPm-BkbGvU4YRkJ015N3PSkDQCPbl1Z7sXAFlGv_OCdtMJteF3FeWWI8HgKWhM9oy8E-CGBCfmjdJ6Q1JyYzXk_QkRe7Ml1mIGACbUjWOcUlFhKh6oeuMSF4vYS4Q',
              ),
              SocialPost(
                hashtag: '#technology',
                content: 'The most powerful technology empowers everyone',
                commentCount: 4900,
                repostCount: 14000,
                imageUrl:
                    'https://lh3.googleusercontent.com/ida-public/AB6AXuACh19veuHbJJdX79BnZ9ZaBiWnr328sjaUQBL9kSyEcXsvq55v66Dh3qEtWkU1nt6DDmrlTyUg7lQPv9D7dswYcBBEs3JCZn1g0EunLyU0ORUz0yZMOSrsCDJOC9E42OEC_0Ti8L5Ig8lPhgdONolkEb5LCqstFHzsberQnrbMNofpMYxRM2mWwG-9v9y7z7JgT81yAuLt5Tb-SAK1NfMCCOS8VM2bMaHaKluQDJz2_uFHWptoqG66NxwrX7rpca3Z6XxyMvLlYA',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 社交用户数据模型
class SocialUser {
  final String name;
  final String username;
  final String avatarUrl;
  final int followerCount;

  const SocialUser({
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.followerCount,
  });
}

/// 社交动态数据模型
class SocialPost {
  final String hashtag;
  final String content;
  final int commentCount;
  final int repostCount;
  final String imageUrl;

  const SocialPost({
    required this.hashtag,
    required this.content,
    required this.commentCount,
    required this.repostCount,
    required this.imageUrl,
  });
}

/// 社交活动动态小组件
class SocialActivityCardWidget extends StatefulWidget {
  final SocialUser user;
  final List<SocialPost> posts;

  const SocialActivityCardWidget({
    super.key,
    required this.user,
    required this.posts,
  });

  @override
  State<SocialActivityCardWidget> createState() => _SocialActivityCardWidgetState();
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
        width: 375,
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                  color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
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
                          color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1F2937),
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
    final baseColor = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

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
