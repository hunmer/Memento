import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 任务进度卡片小组件
class TaskProgressCardWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final int completedTasks;
  final int totalTasks;
  final List<String> pendingTasks;

  /// 进度标签（默认"进度"）
  final String progressLabel;

  /// 待办列表标签（默认"待办"）
  final String pendingLabel;

  /// 最大显示待办数量（null表示显示全部）
  final int? maxPendingTasks;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const TaskProgressCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.completedTasks,
    required this.totalTasks,
    this.pendingTasks = const [],
    this.progressLabel = '进度',
    this.pendingLabel = '待办',
    this.maxPendingTasks,
    this.inline = false,
    this.size = HomeWidgetSize.medium,
  });

  /// 从 props 创建实例
  factory TaskProgressCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return TaskProgressCardWidget(
      title: props['title'] as String? ?? '',
      subtitle: props['subtitle'] as String? ?? '',
      completedTasks: props['completedTasks'] as int? ?? 0,
      totalTasks: props['totalTasks'] as int? ?? 0,
      pendingTasks: (props['pendingTasks'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      progressLabel: props['progressLabel'] as String? ?? '进度',
      pendingLabel: props['pendingLabel'] as String? ?? '待办',
      maxPendingTasks: props['maxPendingTasks'] as int?,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<TaskProgressCardWidget> createState() =>
      _TaskProgressCardWidgetState();
}

class _TaskProgressCardWidgetState extends State<TaskProgressCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
    final backgroundColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.grey.shade900;
    final secondaryTextColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;
    final dividerColor = isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);
    final progressTrackColor = isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            padding: widget.size.getPadding(),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题部分
                _buildHeaderSection(textColor, secondaryTextColor),

                SizedBox(height: widget.size.getTitleSpacing()),

                // 进度条部分
                _buildProgressSection(progressTrackColor),

                if (widget.pendingTasks.isNotEmpty) ...[
                  SizedBox(height: widget.size.getTitleSpacing()),
                  // 待办任务列表
                  _buildPendingTasksSection(secondaryTextColor, dividerColor),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(Color textColor, Color secondaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            fontSize: widget.size.getTitleFontSize(),
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (widget.subtitle.isNotEmpty)
          Text(
            widget.subtitle,
            style: TextStyle(
              fontSize: widget.size.getLegendFontSize(),
              fontWeight: FontWeight.w500,
              color: secondaryTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildProgressSection(Color progressTrackColor) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final progress =
        widget.totalTasks > 0 ? widget.completedTasks / widget.totalTasks : 0;
    final legendFontSize = widget.size.getLegendFontSize();
    final iconSize = widget.size.getIconSize() * 0.6;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.format_list_bulleted,
                  size: iconSize,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.5),
                ),
                SizedBox(width: widget.size.getSmallSpacing()),
                Text(
                  widget.progressLabel,
                  style: TextStyle(
                    fontSize: legendFontSize,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                SizedBox(
                  width: legendFontSize * 2,
                  height: legendFontSize * 1.3,
                  child: AnimatedFlipCounter(
                    value: widget.completedTasks.toDouble() * _animation.value,
                    fractionDigits: 0,
                    textStyle: TextStyle(
                      fontSize: legendFontSize,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
                  ),
                ),
                Text(' / ', style: TextStyle(fontSize: legendFontSize)),
                SizedBox(
                  width: legendFontSize * 2,
                  height: legendFontSize * 1.3,
                  child: AnimatedFlipCounter(
                    value: widget.totalTasks.toDouble(),
                    fractionDigits: 0,
                    textStyle: TextStyle(
                      fontSize: legendFontSize,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: widget.size.getItemSpacing()),
        Container(
          height: widget.size.getLegendIndicatorHeight(),
          decoration: BoxDecoration(
            color: progressTrackColor,
            borderRadius: BorderRadius.circular(widget.size.getLegendIndicatorHeight() / 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.size.getLegendIndicatorHeight() / 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress * _animation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(widget.size.getLegendIndicatorHeight() / 2),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingTasksSection(
    Color secondaryTextColor,
    Color dividerColor,
  ) {
    final tasks = widget.maxPendingTasks == null
        ? widget.pendingTasks
        : widget.pendingTasks.take(widget.maxPendingTasks!).toList();
    final legendFontSize = widget.size.getLegendFontSize();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: widget.size.getSmallSpacing()),
          child: Text(
            widget.pendingLabel,
            style: TextStyle(
              fontSize: legendFontSize,
              fontWeight: FontWeight.w500,
              color: secondaryTextColor,
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: legendFontSize * 7),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < tasks.length; i++) ...[
                  if (i > 0) Divider(color: dividerColor, height: 1),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: widget.size.getSmallSpacing()),
                    child: Text(
                      tasks[i],
                      style: TextStyle(
                        fontSize: legendFontSize,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
