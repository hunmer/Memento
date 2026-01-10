import 'package:flutter/material.dart';

/// 图片分割卡片示例
class SplitImageCardExample extends StatelessWidget {
  const SplitImageCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('图片分割卡片')),
      body: Container(
        color: isDark ? const Color(0xFF5B5CE6) : const Color(0xFFF3F4F6),
        child: const Center(
          child: SplitImageCardWidget(
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCIUN5u7_vXAmPtmC1n8CohO3eS0nZOPxCdcvHkmt1gIycehc3bA86brIYWSrJTWE6Wix61_MBSRyWe1uhT0fDO3PsKCQ3_BWhVESA4KhsovB-7V2yyRmartUzJ7Y-4imptSg_sOYJby5zQl_Nh7CLA6YSu-JvkZlW3V0aF1_x4aq5RKTHGwdFl9qEfHNSpTlpcmytGbAH2zOMnzAPVbgRmf4i8ef0MhxwxconBvFNmKy3QE5BzUvw5s8EDAwiCwlO_MrtTXCrvyA',
            topIcon: Icons.schedule,
                topText: '14:00',
            title: 'A Georgian Masterpiece in the Heart',
            bottomIcon: Icons.calendar_today,
            bottomText: '01 Feb 2020',
          ),
        ),
      ),
    );
  }
}

/// 图片分割卡片小组件
///
/// 左右分屏布局的卡片组件，左侧展示图片，右侧展示信息。
/// 适用于房地产卡片、活动卡片、产品展示等场景。
class SplitImageCardWidget extends StatefulWidget {
  /// 左侧图片 URL
  final String imageUrl;

  /// 顶部图标
  final IconData topIcon;

  /// 顶部文字
  final String topText;

  /// 主标题
  final String title;

  /// 底部图标
  final IconData bottomIcon;

  /// 底部文字
  final String bottomText;

  const SplitImageCardWidget({
    super.key,
    required this.imageUrl,
    required this.topIcon,
    required this.topText,
    required this.title,
    required this.bottomIcon,
    required this.bottomText,
  });

  @override
  State<SplitImageCardWidget> createState() => _SplitImageCardWidgetState();
}

class _SplitImageCardWidgetState extends State<SplitImageCardWidget>
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
        width: 380,
        height: 240,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF27272A) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Row(
            children: [
              // 左侧图片
              Expanded(
                child: _AnimatedImageWidget(
                  imageUrl: widget.imageUrl,
                  animation: _animation,
                ),
              ),
              // 右侧信息
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 顶部信息
                      _InfoRowWidget(
                        icon: widget.topIcon,
                        text: widget.topText,
                        animation: _animation,
                        index: 0,
                      ),
                      // 中间标题
                      _TitleWidget(
                        title: widget.title,
                        animation: _animation,
                        index: 1,
                      ),
                      // 底部信息
                      _InfoRowWidget(
                        icon: widget.bottomIcon,
                        text: widget.bottomText,
                        animation: _animation,
                        index: 2,
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
  }
}

/// 带动画的图片组件
class _AnimatedImageWidget extends StatelessWidget {
  final String imageUrl;
  final Animation<double> animation;

  const _AnimatedImageWidget({
    required this.imageUrl,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final imageAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: imageAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: imageAnimation.value,
          child: child,
        );
      },
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.broken_image, size: 48),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      ),
    );
  }
}

/// 信息行组件（图标 + 文字）
class _InfoRowWidget extends StatelessWidget {
  final IconData icon;
  final String text;
  final Animation<double> animation;
  final int index;

  const _InfoRowWidget({
    required this.icon,
    required this.text,
    required this.animation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        0.15 + index * 0.15,
        0.6 + index * 0.15,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: child,
        );
      },
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

/// 标题组件
class _TitleWidget extends StatelessWidget {
  final String title;
  final Animation<double> animation;
  final int index;

  const _TitleWidget({
    required this.title,
    required this.animation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        0.15 + index * 0.15,
        0.6 + index * 0.15,
        curve: Curves.easeOutCubic,
      ),
    );

    return Expanded(
      child: AnimatedBuilder(
        animation: itemAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: itemAnimation.value,
            child: child,
          );
        },
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: isDark ? Colors.white : Colors.grey.shade900,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
