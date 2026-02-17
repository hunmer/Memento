import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 任务列表卡片小组件
///
/// 显示任务列表、数量统计和图标标识，支持自定义颜色和动画效果
class TaskListCardWidget extends StatefulWidget {
  /// 图标
  final IconData icon;

  /// 图标背景颜色
  final Color iconBackgroundColor;

  /// 任务总数
  final int count;

  /// 计数标签
  final String countLabel;

  /// 任务项列表
  final List<String> items;

  /// 更多任务数量
  final int moreCount;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 组件尺寸
  final HomeWidgetSize size;

  const TaskListCardWidget({
    super.key,
    required this.icon,
    required this.iconBackgroundColor,
    required this.count,
    required this.countLabel,
    required this.items,
    required this.moreCount,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例
  factory TaskListCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final itemsList = props['items'] as List<dynamic>?;
    final items = itemsList?.map((item) => item as String).toList() ?? [];

    // 从 props 中读取 size，如果不存在则使用传入的 size 参数
    HomeWidgetSize widgetSize = size;
    if (props['size'] != null) {
      widgetSize = HomeWidgetSize.fromJson(
        props['size'] as Map<String, dynamic>,
      );
    }

    return TaskListCardWidget(
      icon:
          props['icon'] is String
              ? IconData(
                int.parse(props['icon'] as String),
                fontFamily: 'MaterialIcons',
              )
              : (props['icon'] as IconData? ?? Icons.format_list_bulleted),
      iconBackgroundColor:
          props['iconBackgroundColor'] != null
              ? Color(props['iconBackgroundColor'] as int)
              : const Color(0xFF5A72EA),
      count: props['count'] as int? ?? 0,
      countLabel: props['countLabel'] as String? ?? 'Tasks',
      items: items,
      moreCount: props['moreCount'] as int? ?? 0,
      inline: props['inline'] as bool? ?? false,
      size: widgetSize,
    );
  }

  /// 转换为 props
  Map<String, dynamic> toProps() {
    return {
      'icon': icon.codePoint.toString(),
      'iconBackgroundColor': iconBackgroundColor.value,
      'count': count,
      'countLabel': countLabel,
      'items': items,
      'moreCount': moreCount,
      'inline': inline,
      'size': size.toJson(),
    };
  }

  @override
  State<TaskListCardWidget> createState() => _TaskListCardWidgetState();
}

class _TaskListCardWidgetState extends State<TaskListCardWidget>
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
    final backgroundColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFF3F4F6);
    final textColor =
        isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
    final subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF9CA3AF);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              height: widget.inline ? double.maxFinite : 380,
              width: widget.inline ? double.maxFinite : 380,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: widget.size.getPadding(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左侧：图标和计数
                    _buildLeftSection(
                      context,
                      isDark,
                      textColor,
                      subtitleColor,
                    ),
                    SizedBox(width: widget.size.getTitleSpacing()),
                    // 右侧：任务列表
                    Expanded(
                      child: _buildRightSection(
                        context,
                        isDark,
                        textColor,
                        borderColor,
                      ),
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

  Widget _buildLeftSection(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color subtitleColor,
  ) {
    final iconContainerSize =
        widget.size.getIconSize() * widget.size.iconContainerScale;
    final leftSectionWidth = iconContainerSize + 8;

    return SizedBox(
      width: leftSectionWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图标
          Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              color: widget.iconBackgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.iconBackgroundColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              widget.icon,
              color: Colors.white,
              size: widget.size.getIconSize(),
            ),
          ),
          SizedBox(height: widget.size.getItemSpacing()),
          // 计数
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: widget.size.getLargeFontSize() * 0.9,
                child: AnimatedFlipCounter(
                  value: widget.count.toDouble() * _animation.value,
                  textStyle: TextStyle(
                    fontSize: widget.size.getLargeFontSize() * 0.6,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    height: 1.0,
                  ),
                ),
              ),
              SizedBox(height: widget.size.getItemSpacing()),
              SizedBox(
                height: widget.size.getSubtitleFontSize(),
                child: Text(
                  widget.countLabel,
                  style: TextStyle(
                    fontSize: widget.size.getSubtitleFontSize(),
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRightSection(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color borderColor,
  ) {
    // 空状态：当没有任务项时显示提示
    if (widget.items.isEmpty) {
      return _buildEmptyState(context, textColor);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 任务列表
        Flexible(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < widget.items.length; i++) ...[
                  if (i > 0)
                    Container(
                      height: 1,
                      margin: EdgeInsets.symmetric(
                        vertical: widget.size.getItemSpacing(),
                      ),
                      color: borderColor,
                    ),
                  _TaskItemWidget(
                    title: widget.items[i],
                    animation: _animation,
                    index: i,
                    textColor: textColor,
                    size: widget.size,
                  ),
                ],
                SizedBox(height: widget.size.getItemSpacing()),
                // 更多任务链接
                _MoreLinkWidget(
                  count: widget.moreCount,
                  animation: _animation,
                  index: widget.items.length,
                  color: widget.iconBackgroundColor,
                  size: widget.size,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建空状态提示
  Widget _buildEmptyState(BuildContext context, Color textColor) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // 计算延迟动画值
        const intervalStart = 0.3;
        const intervalEnd = 0.8;
        final value = _animation.value;
        final delayedValue =
            value <= intervalStart
                ? 0.0
                : value >= intervalEnd
                ? 1.0
                : Curves.easeOutCubic.transform(
                  (value - intervalStart) / (intervalEnd - intervalStart),
                );

        return Opacity(
          opacity: delayedValue,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - delayedValue)),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: widget.size.getItemSpacing() * 2,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 32,
                      color: textColor.withOpacity(0.3),
                    ),
                    SizedBox(height: widget.size.getItemSpacing()),
                    Text(
                      '暂无已完成项目',
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
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

/// 任务项组件
class _TaskItemWidget extends StatelessWidget {
  final String title;
  final Animation<double> animation;
  final int index;
  final Color textColor;
  final HomeWidgetSize size;

  const _TaskItemWidget({
    required this.title,
    required this.animation,
    required this.index,
    required this.textColor,
    required this.size,
  });

  // 计算延迟动画值
  double _getDelayedAnimationValue(double value) {
    final intervalStart = index * 0.1;
    final intervalEnd = (0.4 + index * 0.1).clamp(0.0, 1.0);

    if (value <= intervalStart) return 0.0;
    if (value >= intervalEnd) return 1.0;

    final t = (value - intervalStart) / (intervalEnd - intervalStart);
    return Curves.easeOutCubic.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final delayedValue = _getDelayedAnimationValue(animation.value);
        return Opacity(
          opacity: delayedValue,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - delayedValue)),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: size.getItemSpacing()),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: size.getSubtitleFontSize(),
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 更多任务链接组件
class _MoreLinkWidget extends StatelessWidget {
  final int count;
  final Animation<double> animation;
  final int index;
  final Color color;
  final HomeWidgetSize size;

  const _MoreLinkWidget({
    required this.count,
    required this.animation,
    required this.index,
    required this.color,
    required this.size,
  });

  // 计算延迟动画值
  double _getDelayedAnimationValue(double value) {
    final intervalStart = index * 0.1;
    final intervalEnd = (0.4 + index * 0.1).clamp(0.0, 1.0);

    if (value <= intervalStart) return 0.0;
    if (value >= intervalEnd) return 1.0;

    final t = (value - intervalStart) / (intervalEnd - intervalStart);
    return Curves.easeOutCubic.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final delayedValue = _getDelayedAnimationValue(animation.value);
        return Opacity(
          opacity: delayedValue,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - delayedValue)),
            child: Padding(
              padding: EdgeInsets.only(top: size.getItemSpacing()),
              child: Text(
                '+$count more',
                style: TextStyle(
                  fontSize: size.getSubtitleFontSize(),
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
