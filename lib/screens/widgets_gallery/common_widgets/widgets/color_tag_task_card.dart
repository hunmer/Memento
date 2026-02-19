import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import '../models/color_tag_task_card_data.dart';

/// 彩色标签任务列表卡片小组件
/// 用于显示带彩色标签的任务列表，支持动画效果
class ColorTagTaskCardWidget extends StatefulWidget {
  /// 卡片数据
  final ColorTagTaskCardData data;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const ColorTagTaskCardWidget({
    super.key,
    required this.data,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例
  factory ColorTagTaskCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return ColorTagTaskCardWidget(
      data: ColorTagTaskCardData.fromJson(props),
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<ColorTagTaskCardWidget> createState() => _ColorTagTaskCardWidgetState();
}

class _ColorTagTaskCardWidgetState extends State<ColorTagTaskCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late Animation<double> _countAnimation;

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
    _countAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
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
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final secondaryTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF);
    final primaryColor = Theme.of(context).colorScheme.primary;

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
        width: widget.inline ? double.maxFinite : 320,
        height: widget.inline ? double.maxFinite : 320,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: widget.size.getPadding(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题区域
              _buildHeader(textColor, secondaryTextColor, primaryColor),
              SizedBox(height: widget.size.getTitleSpacing()),
              // 任务列表
              Flexible(
                child: _buildTaskList(),
              ),
              // 底部更多按钮
              if (widget.data.moreCount > 0) _buildMoreButton(primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    Color textColor,
    Color secondaryTextColor,
    Color primaryColor,
  ) {
    final valueFontSize = widget.size.getLargeFontSize();
    final labelFontSize = widget.size.getSubtitleFontSize();
    final spacing = widget.size.getSmallSpacing();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _countAnimation,
          builder: (context, child) {
            return AnimatedFlipCounter(
              value: widget.data.taskCount.toDouble() * _countAnimation.value,
              textStyle: TextStyle(
                color: textColor,
                fontSize: valueFontSize,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
            );
          },
        ),
        SizedBox(height: spacing),
        Text(
          widget.data.label,
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: labelFontSize,
            fontWeight: FontWeight.w500,
            height: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < widget.data.tasks.length; i++) ...[
            if (i > 0) SizedBox(height: widget.size.getItemSpacing()),
            _ColorTagTaskItemWidget(
              task: widget.data.tasks[i],
              animation: _animation,
              index: i,
              size: widget.size,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoreButton(Color primaryColor) {
    final fontSize = widget.size.getSubtitleFontSize();

    return Padding(
      padding: EdgeInsets.only(top: widget.size.getSmallSpacing()),
      child: GestureDetector(
        onTap: () {},
        child: Text(
          '+${widget.data.moreCount} more',
          style: TextStyle(
            color: primaryColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// 彩色标签任务项组件
class _ColorTagTaskItemWidget extends StatelessWidget {
  final ColorTagTaskItem task;
  final Animation<double> animation;
  final int index;
  final HomeWidgetSize size;

  const _ColorTagTaskItemWidget({
    required this.task,
    required this.animation,
    required this.index,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);

    final indicatorHeight = size.getLegendIndicatorHeight();
    final indicatorWidth = size.getLegendIndicatorWidth() * 0.2;
    final spacing = size.getSmallSpacing() * 3;
    final titleFontSize = size.getSubtitleFontSize();
    final tagFontSize = size.getLegendFontSize();

    // 确保最后一个元素的 end 不超过 1.0
    final step = 0.05;
    final start = index * step;
    final end = (0.6 + index * step).clamp(0.0, 1.0);
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        start,
        end,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - itemAnimation.value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {},
        child: Row(
          children: [
            // 彩色竖条标签
            Container(
              width: indicatorWidth,
              height: indicatorHeight,
              decoration: BoxDecoration(
                color: Color(task.color),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: spacing),
            // 任务标题（时间）
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  color: textColor,
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 右侧标签（活动名称）
            if (task.tag.isNotEmpty)
              Text(
                task.tag,
                style: TextStyle(
                  color: textColor,
                  fontSize: tagFontSize,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}
