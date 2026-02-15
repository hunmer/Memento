import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 里程碑追踪小组件
class MilestoneCardWidget extends StatefulWidget {
  /// 头像图片 URL
  final String? imageUrl;

  /// 标题
  final String title;

  /// 日期文本
  final String date;

  /// 天数
  final int daysCount;

  /// 大号显示的数值
  final String value;

  /// 数值单位
  final String unit;

  /// 数值后缀
  final String suffix;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const MilestoneCardWidget({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.date,
    required this.daysCount,
    required this.value,
    required this.unit,
    this.suffix = '',
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory MilestoneCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return MilestoneCardWidget(
      imageUrl: props['imageUrl'] as String?,
      title: props['title'] as String? ?? '',
      date: props['date'] as String? ?? '',
      daysCount: props['daysCount'] as int? ?? 0,
      value: props['value'] as String? ?? '0',
      unit: props['unit'] as String? ?? '',
      suffix: props['suffix'] as String? ?? '',
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<MilestoneCardWidget> createState() => _MilestoneCardWidgetState();
}

class _MilestoneCardWidgetState extends State<MilestoneCardWidget>
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

    // 使用主题颜色适配
    final backgroundColor = isDark
        ? const Color(0xFF151517)
        : Theme.of(context).colorScheme.surface;
    final titleColor = isDark
        ? const Color(0xFFD9F99D)
        : Theme.of(context).colorScheme.primary;
    final dateColor = isDark
        ? const Color(0xFF9CA3AF)
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    final valueColor = isDark
        ? const Color(0xFFA5B4FC)
        : Theme.of(context).colorScheme.primary;
    final unitColor = isDark
        ? const Color(0xFF6B7280)
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    final ringColor = isDark
        ? Colors.white10
        : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 260,
              height: widget.inline ? double.maxFinite : 260,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: widget.size.getPadding(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 头像
                  _buildAvatar(ringColor),

                  // 标题和日期
                  _buildTitleAndDate(isDark, titleColor, dateColor),

                  // 大号数值和单位
                  _buildValueAndUnit(isDark, valueColor, unitColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(Color ringColor) {
    final avatarAnimation = CurvedAnimation(
      parent: _animation,
      curve: const Interval(0, 0.5, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: avatarAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: avatarAnimation.value,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: ringColor,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: widget.imageUrl != null
                    ? Image.network(
                        widget.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.person, size: 32),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.person, size: 32),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitleAndDate(bool isDark, Color titleColor, Color dateColor) {
    final textAnimation = CurvedAnimation(
      parent: _animation,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: textAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: textAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - textAnimation.value)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 21.6, // 1.35rem
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: widget.size.getItemSpacing()),
                Row(
                  children: [
                    Text(
                      widget.date,
                      style: TextStyle(
                        fontSize: 12.8, // 0.8rem
                        fontWeight: FontWeight.w500,
                        color: dateColor,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      ' · ',
                      style: TextStyle(
                        fontSize: 12.8,
                        fontWeight: FontWeight.w500,
                        color: dateColor,
                        height: 1.1,
                      ),
                    ),
                    AnimatedFlipCounter(
                      value: widget.daysCount.toDouble() * _animation.value,
                      fractionDigits: 0,
                      suffix: ' days',
                      textStyle: TextStyle(
                        fontSize: 12.8,
                        fontWeight: FontWeight.w500,
                        color: dateColor,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildValueAndUnit(bool isDark, Color valueColor, Color unitColor) {
    final valueAnimation = CurvedAnimation(
      parent: _animation,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: valueAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: valueAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - valueAnimation.value)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.value,
                  style: TextStyle(
                    fontSize: 67.2, // 4.2rem
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                    height: 0.85,
                    letterSpacing: -1.5,
                  ),
                ),
                SizedBox(width: widget.size.getItemSpacing()),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.unit,
                        style: TextStyle(
                          fontSize: 14.4, // 0.9rem
                          fontWeight: FontWeight.w600,
                          color: unitColor,
                          height: 1,
                        ),
                      ),
                      if (widget.suffix.isNotEmpty)
                        Text(
                          widget.suffix,
                          style: TextStyle(
                            fontSize: 14.4,
                            fontWeight: FontWeight.w600,
                            color: unitColor,
                            height: 1,
                          ),
                        ),
                    ],
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
