/// 习惯热力图小组件
library;

import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'package:Memento/core/plugin_manager.dart';
import '../../habits_plugin.dart';
import '../data.dart';
import '../utils.dart';

/// 渲染习惯热力图数据
Widget renderHabitHeatmapData(
  BuildContext context,
  SelectorResult result,
  Map<String, dynamic> config,
  void Function(void Function()) setState, {
  required SelectorNavigationHandler navigateToHabitDetail,
}) {
  if (result.data == null) {
    return _buildErrorWidget(context, '数据不存在');
  }

  final savedData = result.data is Map<String, dynamic>
      ? result.data as Map<String, dynamic>
      : <String, dynamic>{};

  final habitId = savedData['id'] as String?;

  if (habitId == null) {
    return _buildErrorWidget(context, '习惯ID不存在');
  }

  // 使用 EventListenerContainer 实现动态更新
  return EventListenerContainer(
    events: const [
      'habit_data_changed',
      'habit_timer_started',
      'habit_timer_stopped',
    ],
    onEvent: () => setState(() {}),
    child: _HabitHeatmapContent(
      habitId: habitId,
      savedData: savedData,
      config: config,
      onTap: () => navigateToHabitDetail(context, result),
    ),
  );
}

Widget _buildErrorWidget(BuildContext context, String message) {
  return Center(
    child: Text(
      message,
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
}

/// 习惯热力图内容组件
class _HabitHeatmapContent extends StatelessWidget {
  final String habitId;
  final Map<String, dynamic> savedData;
  final Map<String, dynamic> config;
  final VoidCallback? onTap;

  const _HabitHeatmapContent({
    required this.habitId,
    required this.savedData,
    required this.config,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FutureBuilder<HabitHeatmapData?>(
        future: _loadHabitHeatmapData(habitId),
        builder: (context, snapshot) {
          final heatmapData = snapshot.data;
          final widgetSize = config['widgetSize'] as HomeWidgetSize?;

          return Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, heatmapData),
                // 热力图（根据卡片大小显示不同范围）
                if (heatmapData != null &&
                    (widgetSize == const MediumSize() ||
                        widgetSize == const LargeSize())) ...[
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildHeatmapGrid(
                        context, heatmapData, widgetSize!),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, HabitHeatmapData? heatmapData) {
    final theme = Theme.of(context);
    final title = savedData['title'] as String? ?? '未知习惯';
    final group = savedData['group'] as String?;
    final iconCode = savedData['icon'] as String?;
    final colorValue = savedData['color'] as int? ?? Colors.amber.value;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Color(colorValue).withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: iconCode != null
              ? Icon(
                  IconData(
                    int.parse(iconCode),
                    fontFamily: 'MaterialIcons',
                  ),
                  color: Color(colorValue),
                  size: 18,
                )
              : Icon(
                  Icons.auto_awesome,
                  color: Color(colorValue),
                  size: 18,
                ),
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
                  group,
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
        if (heatmapData != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Colors.amber.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              '${heatmapData.totalMinutes}分钟',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.amber,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 构建热力图网格
  Widget _buildHeatmapGrid(
    BuildContext context,
    HabitHeatmapData data,
    HomeWidgetSize size,
  ) {
    final today = DateTime.now();
    final List<int> dayNumbers = [];
    final List<int> dailyMinutes = [];
    final habitColor = Colors.amber;

    if (size == const MediumSize()) {
      // medium: 显示过去7天
      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        dayNumbers.add(date.day);
        dailyMinutes.add(getMinutesForDate(data.records, date));
      }
    } else {
      // large: 显示当月所有日期
      final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(today.year, today.month, day);
        dayNumbers.add(day);
        dailyMinutes.add(getMinutesForDate(data.records, date));
      }

      // 居中显示：首尾添加空网格占位
      final daysInMonthMod = daysInMonth % 7;
      if (daysInMonthMod != 0) {
        final emptyCount = 7 - daysInMonthMod;
        final emptyAtStart = emptyCount ~/ 2;
        final emptyAtEnd = emptyCount - emptyAtStart;

        for (int i = 0; i < emptyAtStart; i++) {
          dayNumbers.insert(0, 0);
          dailyMinutes.insert(0, 0);
        }
        for (int i = 0; i < emptyAtEnd; i++) {
          dayNumbers.add(0);
          dailyMinutes.add(0);
        }
      }
    }

    final crossAxisCount = 7;
    final spacing = size == const MediumSize() ? 4.0 : 3.0;
    final showNumber = size == const LargeSize();
    final maxMinutes = dailyMinutes
        .where((m) => m > 0)
        .fold<int>(0, (max, m) => m > max ? m : max);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;

        final totalWidthSpacing = (crossAxisCount - 1) * spacing;
        final cellWidth = (maxWidth - totalWidthSpacing) / crossAxisCount;

        final totalItems = dayNumbers.length;
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
            runAlignment: WrapAlignment.start,
            children: List.generate(dayNumbers.length, (index) {
              final day = dayNumbers[index];
              final minutes = dailyMinutes[index];

              if (day == 0) {
                return SizedBox(width: cellSize, height: cellSize);
              }

              // 根据时长计算透明度
              final double opacity;
              if (maxMinutes > 0) {
                opacity = 0.1 + (minutes / maxMinutes) * 0.7;
              } else {
                opacity = 0.1;
              }

              return SizedBox(
                width: cellSize,
                height: cellSize,
                child: Container(
                  decoration: BoxDecoration(
                    color: habitColor.withOpacity(
                      minutes > 0 ? opacity.clamp(0.2, 0.9) : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(cellSize / 3),
                  ),
                  child: showNumber
                      ? Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: fontSize,
                              color: minutes > 0
                                  ? Colors.black54
                                  : Colors.black26,
                              fontWeight: minutes > 0
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        )
                      : null,
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

/// 加载习惯热力图数据
Future<HabitHeatmapData?> _loadHabitHeatmapData(String? habitId) async {
  if (habitId == null || habitId.isEmpty) return null;

  try {
    final plugin = PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
    if (plugin == null) return null;

    final recordController = plugin.getRecordController();
    final records = await recordController.getHabitCompletionRecords(habitId);

    // 计算总时长
    int totalMinutes = 0;
    for (final record in records) {
      totalMinutes += (record.duration.inMinutes as int);
    }

    return HabitHeatmapData(
      habitId: habitId,
      records: records,
      totalMinutes: totalMinutes,
    );
  } catch (e) {
    debugPrint('加载习惯热力图数据失败: $e');
    return null;
  }
}
