import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 节点统计卡片小组件
///
/// 显示节点统计信息（总数、待办、进行中、已完成）
class NodeStatsCardWidget extends StatefulWidget {
  /// 节点总数
  final int totalNodes;

  /// 待办节点数
  final int todoNodes;

  /// 进行中节点数
  final int doingNodes;

  /// 已完成节点数
  final int doneNodes;

  /// 完成率
  final double completedRate;

  /// 是否为内联模式
  final bool inline;

  /// 组件尺寸
  final HomeWidgetSize size;

  const NodeStatsCardWidget({
    super.key,
    required this.totalNodes,
    required this.todoNodes,
    required this.doingNodes,
    required this.doneNodes,
    required this.completedRate,
    this.inline = false,
    this.size = const LargeSize(),
  });

  /// 从 props 创建实例
  factory NodeStatsCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    // 从 props 中读取 size，如果不存在则使用传入的 size 参数
    HomeWidgetSize widgetSize = size;
    if (props['size'] != null) {
      widgetSize = HomeWidgetSize.fromJson(
        props['size'] as Map<String, dynamic>,
      );
    }

    return NodeStatsCardWidget(
      totalNodes: props['totalNodes'] as int? ?? 0,
      todoNodes: props['todoNodes'] as int? ?? 0,
      doingNodes: props['doingNodes'] as int? ?? 0,
      doneNodes: props['doneNodes'] as int? ?? 0,
      completedRate: (props['completedRate'] as num?)?.toDouble() ?? 0.0,
      inline: props['inline'] as bool? ?? false,
      size: widgetSize,
    );
  }

  @override
  State<NodeStatsCardWidget> createState() => _NodeStatsCardWidgetState();
}

class _NodeStatsCardWidgetState extends State<NodeStatsCardWidget>
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
        padding: EdgeInsets.all(widget.size.getItemSpacing()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Padding(
              padding: EdgeInsets.only(bottom: widget.size.getItemSpacing() * 0.5),
              child: Text(
                '节点统计',
                style: TextStyle(
                  fontSize: widget.size.getSubtitleFontSize(),
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            // 统计卡片网格
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 2.0,
                mainAxisSpacing: widget.size.getItemSpacing() * 0.5,
                crossAxisSpacing: widget.size.getItemSpacing() * 0.5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStatCard(
                    context,
                    label: '总节点',
                    value: widget.totalNodes,
                    color: Colors.blue,
                    textColor: textColor,
                  ),
                  _buildStatCard(
                    context,
                    label: '待办',
                    value: widget.todoNodes,
                    color: Colors.orange,
                    textColor: textColor,
                  ),
                  _buildStatCard(
                    context,
                    label: '进行中',
                    value: widget.doingNodes,
                    color: Colors.cyan,
                    textColor: textColor,
                  ),
                  _buildStatCard(
                    context,
                    label: '已完成',
                    value: widget.doneNodes,
                    color: Colors.green,
                    textColor: textColor,
                  ),
                ],
              ),
            ),
            SizedBox(height: widget.size.getItemSpacing() * 0.5),
            // 完成率进度条
            Row(
              children: [
                Expanded(
                  child: Text(
                    '完成率',
                    style: TextStyle(
                      fontSize: widget.size.getSubtitleFontSize() * 0.8,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                ),
                SizedBox(width: widget.size.getItemSpacing() * 0.5),
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final rate = widget.completedRate * _animation.value;
                    return Text(
                      '${rate.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: widget.size.getSubtitleFontSize(),
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: widget.size.getItemSpacing() * 0.3),
            LinearProgressIndicator(
              value: widget.completedRate / 100,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
              minHeight: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    {
    required String label,
    required int value,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(widget.size.getItemSpacing()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: widget.size.getSubtitleFontSize() * 0.8,
              color: textColor.withOpacity(0.6),
            ),
          ),
          SizedBox(height: widget.size.getItemSpacing() * 0.3),
          AnimatedFlipCounter(
            value: value.toDouble() * _animation.value,
            textStyle: TextStyle(
              fontSize: widget.size.getLargeFontSize() * 0.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
