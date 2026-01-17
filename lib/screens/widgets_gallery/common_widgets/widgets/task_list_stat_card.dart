import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 任务数据模型
class TaskListItem {
  final String title;

  const TaskListItem({
    required this.title,
  });

  factory TaskListItem.fromJson(Map<String, dynamic> json) {
    return TaskListItem(
      title: json['title'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title};
  }
}

/// 任务统计列表小组件
class TaskListStatCardWidget extends StatefulWidget {
  /// 图标
  final IconData icon;

  /// 任务总数
  final int count;

  /// 状态标签（如 "Upcoming"）
  final String statusLabel;

  /// 任务列表
  final List<String> tasks;

  /// 剩余任务数量
  final int remainingCount;

  /// 主色调
  final Color? primaryColor;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 组件尺寸
  final HomeWidgetSize size;

  const TaskListStatCardWidget({
    super.key,
    required this.icon,
    required this.count,
    required this.statusLabel,
    required this.tasks,
    required this.remainingCount,
    this.primaryColor,
    this.inline = false,
    this.size = HomeWidgetSize.medium,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory TaskListStatCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return TaskListStatCardWidget(
      icon: _iconFromString(props['icon'] as String? ?? ''),
      count: props['count'] as int? ?? 0,
      statusLabel: props['statusLabel'] as String? ?? '',
      tasks: (props['tasks'] as List<dynamic>?)?.cast<String>() ?? [],
      remainingCount: props['remainingCount'] as int? ?? 0,
      primaryColor: props['primaryColor'] != null
          ? Color(props['primaryColor'] as int)
          : null,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  static IconData _iconFromString(String iconString) {
    // 简单的图标映射
    switch (iconString) {
      case 'Icons.format_list_bulleted':
        return Icons.format_list_bulleted;
      default:
        return Icons.list;
    }
  }

  @override
  State<TaskListStatCardWidget> createState() => _TaskListStatCardWidgetState();
}

class _TaskListStatCardWidgetState extends State<TaskListStatCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
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
    final primaryColor = widget.primaryColor ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: child,
          ),
        );
      },
      child: Container(
        width: widget.inline ? double.maxFinite : 380,
        constraints: widget.size.getHeightConstraints(),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: widget.size.getPadding(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧：图标和统计
            _buildLeftSection(context, isDark, primaryColor),
            SizedBox(width: widget.size.getTitleSpacing()),
            // 右侧：任务列表
            Expanded(
              child: _buildRightSection(context, isDark, primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  /// 左侧区域
  Widget _buildLeftSection(BuildContext context, bool isDark, Color primaryColor) {
    final iconSize = widget.size.getIconSize();
    final containerSize = iconSize * 2;
    final fontSize = widget.size.getLargeFontSize();

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 图标
        Container(
          width: containerSize,
          height: containerSize,
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: Colors.white,
            size: iconSize,
          ),
        ),

        SizedBox(height: widget.size.getTitleSpacing()),

        // 数量和标签
        Column(
          children: [
            SizedBox(
              height: fontSize + 8,
              child: AnimatedFlipCounter(
                value: widget.count * _fadeAnimation.value,
                textStyle: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                  height: 1.0,
                ),
              ),
            ),
            SizedBox(
              height: 18,
              child: Text(
                widget.statusLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF9CA3AF),
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 右侧区域
  Widget _buildRightSection(BuildContext context, bool isDark, Color primaryColor) {
    final displayTasks = widget.tasks.take(4).toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 任务列表
        ...List.generate(displayTasks.length, (index) {
          return _TaskListItem(
            task: displayTasks[index],
            isLast: index == displayTasks.length - 1,
            animation: _animationController,
            index: index,
            isDark: isDark,
            size: widget.size,
          );
        }),

        // 更多链接
        if (widget.remainingCount > 0)
          Padding(
            padding: EdgeInsets.only(top: widget.size.getItemSpacing()),
            child: _MoreLinkWidget(
              count: widget.remainingCount,
              primaryColor: primaryColor,
              animation: _animationController,
              index: displayTasks.length,
            ),
          ),
      ],
    );
  }
}

/// 任务列表项
class _TaskListItem extends StatelessWidget {
  final String task;
  final bool isLast;
  final Animation<double> animation;
  final int index;
  final bool isDark;
  final HomeWidgetSize size;

  const _TaskListItem({
    required this.task,
    required this.isLast,
    required this.animation,
    required this.index,
    required this.isDark,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        index * 0.12,
        0.5 + index * 0.12,
        curve: Curves.easeOutCubic,
      ),
    );

    final itemSpacing = size.getItemSpacing();

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - itemAnimation.value)),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: index == 0 ? 4 : itemSpacing,
              bottom: itemSpacing,
            ),
            child: Text(
              task,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!isLast)
            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            ),
        ],
      ),
    );
  }
}

/// 更多链接组件
class _MoreLinkWidget extends StatelessWidget {
  final int count;
  final Color primaryColor;
  final Animation<double> animation;
  final int index;

  const _MoreLinkWidget({
    required this.count,
    required this.primaryColor,
    required this.animation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        index * 0.12,
        0.5 + index * 0.12,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - itemAnimation.value)),
            child: child,
          ),
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('还有 $count 项任务'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: Text(
            '+$count more',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: primaryColor,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
