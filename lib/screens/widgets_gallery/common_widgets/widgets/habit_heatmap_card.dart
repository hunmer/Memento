/// 习惯热力图卡片 - 公共小组件
///
/// 显示习惯的每日热力图，支持过去7天和当月两种视图模式
library;

import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 习惯热力图每日数据
class HabitHeatmapDailyData {
  final int day;
  final int minutes;

  const HabitHeatmapDailyData({required this.day, required this.minutes});

  /// 从 JSON 创建
  factory HabitHeatmapDailyData.fromJson(Map<String, dynamic> json) {
    return HabitHeatmapDailyData(
      day: json['day'] as int? ?? 0,
      minutes: json['minutes'] as int? ?? 0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {'day': day, 'minutes': minutes};
  }
}

/// 习惯热力图卡片小组件
class HabitHeatmapCardWidget extends StatelessWidget {
  /// 习惯标题
  final String title;

  /// 分组名称（可选）
  final String? group;

  /// 图标代码（MaterialIcons codePoint 字符串）
  final String? iconCode;

  /// 习惯颜色
  final Color color;

  /// 总时长（分钟）
  final int totalMinutes;

  /// 每日数据列表
  final List<HabitHeatmapDailyData> dailyData;

  /// 视图模式：'week' 表示过去7天，'month' 表示当月
  final String viewMode;

  /// 点击回调
  final VoidCallback? onTap;

  const HabitHeatmapCardWidget({
    super.key,
    required this.title,
    this.group,
    this.iconCode,
    required this.color,
    required this.totalMinutes,
    required this.dailyData,
    this.viewMode = 'week',
    this.onTap,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory HabitHeatmapCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final dailyDataList =
        (props['dailyData'] as List<dynamic>?)
            ?.map(
              (e) => HabitHeatmapDailyData.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        const [];

    return HabitHeatmapCardWidget(
      title: props['title'] as String? ?? '',
      group: props['group'] as String?,
      iconCode: props['iconCode'] as String?,
      color: Color(props['color'] as int? ?? 0xFFFFB300),
      totalMinutes: props['totalMinutes'] as int? ?? 0,
      dailyData: dailyDataList,
      viewMode: props['viewMode'] as String? ?? 'week',
      onTap: null, // props 中不包含回调
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMedium = viewMode == 'week';
    final showNumbers = !isMedium;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, theme),
            const SizedBox(height: 8),
            Expanded(child: _buildHeatmapGrid(context, isMedium, showNumbers)),
          ],
        ),
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child:
              iconCode != null
                  ? Icon(
                    IconData(int.parse(iconCode!), fontFamily: 'MaterialIcons'),
                    color: color,
                    size: 18,
                  )
                  : Icon(Icons.auto_awesome, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (group != null)
                Text(
                  group!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        // 统计信息
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
          ),
          child: Text(
            '$totalMinutes分钟',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.amber,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建热力图网格
  Widget _buildHeatmapGrid(
    BuildContext context,
    bool isMedium,
    bool showNumbers,
  ) {
    final spacing = isMedium ? 4.0 : 3.0;
    final crossAxisCount = 7;

    // 计算最大分钟数
    final maxMinutes = dailyData
        .where((d) => d.minutes > 0)
        .fold<int>(0, (max, d) => d.minutes > max ? d.minutes : max);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;

        final totalWidthSpacing = (crossAxisCount - 1) * spacing;
        final cellWidth = (maxWidth - totalWidthSpacing) / crossAxisCount;

        final totalItems = dailyData.length;
        final rows = (totalItems / crossAxisCount).ceil();

        final totalHeightSpacing = (rows - 1) * spacing;
        final cellHeight = (maxHeight - totalHeightSpacing) / rows;

        final cellSize = cellWidth < cellHeight ? cellWidth : cellHeight;
        final fontSize = cellSize * 0.35;

        final totalHeight = rows * cellSize + (rows - 1) * spacing;

        return SizedBox(
          height: totalHeight.clamp(0.0, maxHeight),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            alignment: WrapAlignment.start,
            runAlignment: WrapAlignment.end,
            children:
                dailyData.map((item) {
                  // 根据时长计算透明度
                  final double opacity;
                  if (maxMinutes > 0) {
                    opacity = 0.1 + (item.minutes / maxMinutes) * 0.7;
                  } else {
                    opacity = 0.1;
                  }

                  if (item.day == 0) {
                    return SizedBox(width: cellSize, height: cellSize);
                  }

                  return SizedBox(
                    width: cellSize,
                    height: cellSize,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color.withOpacity(
                          item.minutes > 0 ? opacity.clamp(0.2, 0.9) : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(cellSize / 3),
                      ),
                      child:
                          showNumbers
                              ? Center(
                                child: Text(
                                  '${item.day}',
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color:
                                        item.minutes > 0
                                            ? Colors.black54
                                            : Colors.black26,
                                    fontWeight:
                                        item.minutes > 0
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                  ),
                                ),
                              )
                              : null,
                    ),
                  );
                }).toList(),
          ),
        );
      },
    );
  }
}
