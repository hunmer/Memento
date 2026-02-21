import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 待办节点列表小组件
///
/// 显示所有待办节点列表
class TodoNodesListWidget extends StatefulWidget {
  /// 待办数量
  final int todoCount;

  /// 待办节点项列表
  final List<TodoNodeItemData> items;

  /// 更多任务数量
  final int moreCount;

  /// 是否为内联模式
  final bool inline;

  /// 组件尺寸
  final HomeWidgetSize size;

  const TodoNodesListWidget({
    super.key,
    required this.todoCount,
    required this.items,
    required this.moreCount,
    this.inline = false,
    this.size = const LargeSize(),
  });

  /// 从 props 创建实例
  factory TodoNodesListWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final itemsList = props['items'] as List<dynamic>?;
    final items = itemsList?.map((item) {
          final data = item as Map<String, dynamic>;
          return TodoNodeItemData(
            id: data['id'] as String? ?? '',
            notebookId: data['notebookId'] as String? ?? '',
            notebookTitle: data['notebookTitle'] as String? ?? '',
            nodeId: data['nodeId'] as String? ?? '',
            title: data['title'] as String? ?? '',
            path: data['path'] as String? ?? '',
            color: data['color'] != null ? Color(data['color'] as int) : null,
          );
        }).toList() ?? [];

    // 从 props 中读取 size，如果不存在则使用传入的 size 参数
    HomeWidgetSize widgetSize = size;
    if (props['size'] != null) {
      widgetSize = HomeWidgetSize.fromJson(
        props['size'] as Map<String, dynamic>,
      );
    }

    return TodoNodesListWidget(
      todoCount: props['todoCount'] as int? ?? 0,
      items: items,
      moreCount: props['moreCount'] as int? ?? 0,
      inline: props['inline'] as bool? ?? false,
      size: widgetSize,
    );
  }

  @override
  State<TodoNodesListWidget> createState() => _TodoNodesListWidgetState();
}

class _TodoNodesListWidgetState extends State<TodoNodesListWidget>
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFF3F4F6);

    return Container(
      height: widget.inline ? double.maxFinite : null,
      width: widget.inline ? double.maxFinite : null,
      constraints: widget.size.getHeightConstraints(),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: widget.size.getPadding(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: widget.size.getIconSize(),
                  color: Colors.orange,
                ),
                SizedBox(width: widget.size.getItemSpacing()),
                Text(
                  '待办节点',
                  style: TextStyle(
                    fontSize: widget.size.getSubtitleFontSize(),
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                AnimatedFlipCounter(
                  value: widget.todoCount.toDouble() * _animation.value,
                  textStyle: TextStyle(
                    fontSize: widget.size.getSubtitleFontSize(),
                    fontWeight: FontWeight.w700,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: widget.size.getItemSpacing()),
            // 待办节点列表
            Expanded(
              child: ListView.separated(
                itemCount: widget.items.length + (widget.moreCount > 0 ? 1 : 0),
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: theme.dividerColor.withOpacity(0.3),
                ),
                itemBuilder: (context, index) {
                  if (index < widget.items.length) {
                    final todoNode = widget.items[index];
                    return _TodoNodeItemWidget(
                      todoNode: todoNode,
                      index: index,
                      animation: _animation,
                      size: widget.size,
                      textColor: textColor,
                    );
                  } else {
                    // 更多链接
                    return _MoreLinkWidget(
                      count: widget.moreCount,
                      animation: _animation,
                      index: widget.items.length,
                      color: Colors.orange,
                      size: widget.size,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoNodeItemWidget extends StatelessWidget {
  final TodoNodeItemData todoNode;
  final int index;
  final Animation<double> animation;
  final HomeWidgetSize size;
  final Color textColor;

  const _TodoNodeItemWidget({
    required this.todoNode,
    required this.index,
    required this.animation,
    required this.size,
    required this.textColor,
  });

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
              child: Row(
                children: [
                  // 颜色竖条
                  Container(
                    width: 3,
                    height: size.getSubtitleFontSize() * 1.2,
                    decoration: BoxDecoration(
                      color: todoNode.color ?? Colors.grey,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  SizedBox(width: size.getItemSpacing()),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todoNode.title,
                          style: TextStyle(
                            fontSize: size.getSubtitleFontSize(),
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: size.getItemSpacing() * 0.3),
                        Text(
                          todoNode.path,
                          style: TextStyle(
                            fontSize: size.getSubtitleFontSize() * 0.75,
                            color: textColor.withOpacity(0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

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
              child: Center(
                child: Text(
                  '+$count 更多',
                  style: TextStyle(
                    fontSize: size.getSubtitleFontSize(),
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 待办节点项数据
class TodoNodeItemData {
  final String id;
  final String notebookId;
  final String notebookTitle;
  final String nodeId;
  final String title;
  final String path;
  final Color? color;

  const TodoNodeItemData({
    required this.id,
    required this.notebookId,
    required this.notebookTitle,
    required this.nodeId,
    required this.title,
    required this.path,
    this.color,
  });
}
