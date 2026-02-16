import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 今日活动统计饼状图小组件
///
/// 使用饼状图展示今日活动统计，按标签统计时长
class ActivityTodayPieChartCardWidget extends StatefulWidget {
  /// 标签到时长的映射（标签名 -> 时长分钟数）
  final Map<String, int> tagStats;

  /// 总时长（分钟）
  final int totalDuration;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const ActivityTodayPieChartCardWidget({
    super.key,
    required this.tagStats,
    required this.totalDuration,
    this.size = const Large3Size(),
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory ActivityTodayPieChartCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    // 解析标签统计数据
    final tagStatsMap = <String, int>{};
    if (props['tagStats'] is Map<String, dynamic>) {
      final stats = props['tagStats'] as Map<String, dynamic>;
      stats.forEach((key, value) {
        tagStatsMap[key] = value as int? ?? 0;
      });
    }

    return ActivityTodayPieChartCardWidget(
      tagStats: tagStatsMap,
      totalDuration: props['totalDuration'] as int? ?? 0,
      size: size,
    );
  }

  @override
  State<ActivityTodayPieChartCardWidget> createState() =>
      _ActivityTodayPieChartCardWidgetState();
}

class _ActivityTodayPieChartCardWidgetState
    extends State<ActivityTodayPieChartCardWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 检查是否有数据
    if (widget.tagStats.isEmpty) {
      return _buildNoActivityWidget(context, theme);
    }

    // 按时长排序，只显示前5个
    final sortedEntries =
        widget.tagStats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = sortedEntries.take(5).toList();

    // 计算总时长
    final totalDuration = topEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.value,
    );

    // 为每个标签分配颜色
    final colors = [
      Colors.pink,
      Colors.purple,
      Colors.blue,
      Colors.orange,
      Colors.teal,
    ];

    return Container(
      padding: widget.size.getPadding(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            '今日活动统计',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.pink,
            ),
          ),
          SizedBox(height: widget.size.getItemSpacing()),

          // 饼状图（在上方）
          Expanded(
            flex: 3,
            child: Center(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 25,
                  sections: _buildPieChartSections(
                    topEntries,
                    totalDuration,
                    colors,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: widget.size.getItemSpacing()),

          // 图例（在下方）
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildLegendItems(topEntries, colors, totalDuration),
              ),
            ),
          ),

          SizedBox(height: widget.size.getSmallSpacing()),

          // 总时长
          Text(
            '总时长: ${_formatDuration(totalDuration)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建无数据时的占位Widget
  Widget _buildNoActivityWidget(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: widget.size.getPadding(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 标题
            Text(
              '今日活动统计',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
            SizedBox(height: widget.size.getTitleSpacing()),

            // 占位内容，保持2x3布局
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pie_chart,
                    color: Colors.pink.withOpacity(0.4),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '今日暂无活动',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                  SizedBox(height: widget.size.getItemSpacing()),
                  Text(
                    '添加活动后查看统计',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: widget.size.getItemSpacing()),

            // 底部占位文字（只在总时长>0时显示）
            if (widget.totalDuration > 0)
              Text(
                '总时长: ${_formatDuration(widget.totalDuration)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    List<MapEntry<String, int>> entries,
    int totalDuration,
    List<Color> colors,
  ) {
    return List.generate(entries.length, (index) {
      final entry = entries[index];
      final value = entry.value;
      final percentage = (value / totalDuration * 100).toInt();

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: value.toDouble(),
        title: '$percentage%',
        radius: 40,
        titleStyle: TextStyle(
          fontSize: widget.size.getLegendFontSize(),
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  List<Widget> _buildLegendItems(
    List<MapEntry<String, int>> entries,
    List<Color> colors,
    int totalDuration,
  ) {
    return List.generate(entries.length, (index) {
      final entry = entries[index];
      final tag = entry.key;
      final duration = entry.value;
      final percentage = (duration / totalDuration * 100).toInt();

      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                tag,
                style: const TextStyle(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$percentage%',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    });
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours > 0) {
      return '$hours小时$mins分钟';
    } else {
      return '$mins分钟';
    }
  }
}
