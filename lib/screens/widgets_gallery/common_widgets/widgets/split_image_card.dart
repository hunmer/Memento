import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 图片分割卡片小组件
///
/// 左右分屏布局的卡片组件，左侧展示图片，右侧展示信息。
/// 适用于房地产卡片、活动卡片、产品展示等场景。
class SplitImageCardWidget extends StatefulWidget {
  /// 左侧图片 URL
  final String imageUrl;

  /// 顶部图标
  final IconData? topIcon;

  /// 顶部文字
  final String topText;

  /// 主标题
  final String title;

  /// 底部图标
  final IconData? bottomIcon;

  /// 底部文字
  final String bottomText;

  /// 顶部图标代码（用于序列化）
  final int? topIconCode;

  /// 底部图标代码（用于序列化）
  final int? bottomIconCode;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const SplitImageCardWidget({
    super.key,
    required this.imageUrl,
    this.topIcon,
    required this.topText,
    required this.title,
    this.bottomIcon,
    required this.bottomText,
    this.topIconCode,
    this.bottomIconCode,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例
  factory SplitImageCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return SplitImageCardWidget(
      imageUrl: props['imageUrl'] as String? ?? '',
      topText: props['topText'] as String? ?? '',
      title: props['title'] as String? ?? '',
      bottomText: props['bottomText'] as String? ?? '',
      topIcon:
          props['topIconCode'] != null
              ? IconData(
                props['topIconCode'] as int,
                fontFamily: 'MaterialIcons',
              )
              : null,
      bottomIcon:
          props['bottomIconCode'] != null
              ? IconData(
                props['bottomIconCode'] as int,
                fontFamily: 'MaterialIcons',
              )
              : null,
      topIconCode: props['topIconCode'] as int?,
      bottomIconCode: props['bottomIconCode'] as int?,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

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
        width: widget.inline ? double.maxFinite : 380,
        height: widget.inline ? double.maxFinite : 240,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF27272A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: widget.size is SmallSize
              ? Column(
                  children: [
                    // 上方图片
                    Expanded(
                      child: _AnimatedImageWidget(
                        imageUrl: widget.imageUrl,
                        animation: _animation,
                        size: widget.size,
                      ),
                    ),
                    // 下方信息
                    Expanded(
                      child: Padding(
                        padding: widget.size.getPadding(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 顶部信息
                            if (widget.topIcon != null)
                              _InfoRowWidget(
                                icon: widget.topIcon!,
                                text: widget.topText,
                                animation: _animation,
                                index: 0,
                                size: widget.size,
                              ),
                            // 中间标题
                            _TitleWidget(
                              title: widget.title,
                              animation: _animation,
                              index: widget.topIcon != null ? 1 : 0,
                              size: widget.size,
                            ),
                            // 底部信息
                            if (widget.bottomIcon != null)
                              _InfoRowWidget(
                                icon: widget.bottomIcon!,
                                text: widget.bottomText,
                                animation: _animation,
                                index: widget.bottomIcon != null ? 2 : 1,
                                size: widget.size,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    // 左侧图片
                    Expanded(
                      child: _AnimatedImageWidget(
                        imageUrl: widget.imageUrl,
                        animation: _animation,
                        size: widget.size,
                      ),
                    ),
                    // 右侧信息
                    Expanded(
                      child: Padding(
                        padding: widget.size.getPadding(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 顶部信息
                            if (widget.topIcon != null)
                              _InfoRowWidget(
                                icon: widget.topIcon!,
                                text: widget.topText,
                                animation: _animation,
                                index: 0,
                                size: widget.size,
                              ),
                            // 中间标题
                            _TitleWidget(
                              title: widget.title,
                              animation: _animation,
                              index: widget.topIcon != null ? 1 : 0,
                              size: widget.size,
                            ),
                            // 底部信息
                            if (widget.bottomIcon != null)
                              _InfoRowWidget(
                                icon: widget.bottomIcon!,
                                text: widget.bottomText,
                                animation: _animation,
                                index: widget.bottomIcon != null ? 2 : 1,
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
  }
}

/// 带动画的图片组件
class _AnimatedImageWidget extends StatelessWidget {
  final String imageUrl;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _AnimatedImageWidget({
    required this.imageUrl,
    required this.animation,
    required this.size,
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
        return Opacity(opacity: imageAnimation.value, child: child);
      },
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: Icon(
              Icons.broken_image,
              size: size.getLargeFontSize() * 0.85,
            ),
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
  final HomeWidgetSize size;

  const _InfoRowWidget({
    required this.icon,
    required this.text,
    required this.animation,
    required this.index,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        0.15 + index * 0.15,
        (0.6 + index * 0.15).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Opacity(opacity: itemAnimation.value, child: child);
      },
      child: Row(
        children: [
          Icon(
            icon,
            size: size.getIconSize() * 0.67,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
          ),
          SizedBox(width: size.getItemSpacing() * 0.5),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: size.getLargeFontSize() * 0.23,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
  final HomeWidgetSize size;

  const _TitleWidget({
    required this.title,
    required this.animation,
    required this.index,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        0.15 + index * 0.15,
        (0.6 + index * 0.15).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return Expanded(
      child: AnimatedBuilder(
        animation: itemAnimation,
        builder: (context, child) {
          return Opacity(opacity: itemAnimation.value, child: child);
        },
        child: Center(
          child: SingleChildScrollView(
            child: Text(
              title,
              style: TextStyle(
                fontSize: size.getLargeFontSize() * 0.375,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: isDark ? Colors.white : Colors.grey.shade900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
