/// 七日周报小组件 - 公共组件
library;

import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:intl/intl.dart';

/// 七日周报小组件
///
/// 显示本周七天日记的概览，包括日期、心情和标题
class WeeklyDiaryWidget extends StatelessWidget {
  /// 组件标题
  final String title;

  /// 是否显示标题
  final bool showTitle;

  /// 主色调
  final int? primaryColorValue;

  /// 七天卡片数据列表
  final List<dynamic>? daysData;

  const WeeklyDiaryWidget({
    super.key,
    this.title = '本周日记',
    this.showTitle = true,
    this.primaryColorValue,
    this.daysData,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory WeeklyDiaryWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return WeeklyDiaryWidget(
      title: props['title'] as String? ?? '本周日记',
      showTitle: props['showTitle'] as bool? ?? true,
      primaryColorValue: props['primaryColor'] as int?,
      daysData: props['daysData'] as List<dynamic>?,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = primaryColorValue != null
        ? Color(primaryColorValue!)
        : theme.colorScheme.primary;

    final days = daysData ?? _getDefaultDaysData();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
          ],
          // 七天卡片
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: days.map((dayData) {
                return _buildDayCard(context, dayData, primaryColor);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建周报中的单日卡片组件
  Widget _buildDayCard(
    BuildContext context,
    dynamic dayData,
    Color primaryColor,
  ) {
    final isToday = dayData['isToday'] as bool? ?? false;
    final weekday = dayData['weekday'] as String? ?? '';
    final dayNumber = dayData['dayNumber'] as String? ?? '';
    final mood = dayData['mood'] as String?;
    final title = dayData['title'] as String? ?? '';
    final hasEntry = dayData['hasEntry'] as bool? ?? false;
    final dateStr = dayData['date'] as String? ?? '';

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: isToday
              ? primaryColor.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: primaryColor, width: 1.5)
              : null,
        ),
        child: InkWell(
          onTap: () => _openDiaryEditor(context, dateStr),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 星期几
                Text(
                  weekday,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isToday ? primaryColor : Colors.grey,
                    fontWeight:
                        isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                // 日期数字
                Text(
                  dayNumber,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isToday ? primaryColor : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                // 心情
                if (mood != null)
                  Text(mood, style: const TextStyle(fontSize: 18))
                else
                  const SizedBox(height: 18),
                // 标题（如果有）
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: hasEntry ? Colors.black87 : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 打开日记编辑器
  Future<void> _openDiaryEditor(BuildContext context, String dateStr) async {
    if (dateStr.isEmpty) return;

    try {
      final date = DateTime.parse(dateStr);

      // 使用路由导航到日记编辑器
      Navigator.of(context).pushNamed(
        '/diary/editor',
        arguments: {
          'date': date.toIso8601String(),
          // 注意：标题和内容由日记编辑器从存储加载
        },
      );
    } catch (e) {
      debugPrint('[WeeklyDiaryWidget] 打开日记编辑器失败: $e');
    }
  }

  /// 获取默认的七天数据（用于预览）
  List<dynamic> _getDefaultDaysData() {
    final now = DateTime.now();
    // Monday = 1, Sunday = 7
    final weekday = now.weekday;
    // 计算周一
    final monday = now.subtract(Duration(days: weekday - 1));
    // 生成周一到周日的日期列表
    return List.generate(7, (index) {
      final date = monday.add(Duration(days: index));
      return {
        'date': date.toIso8601String(),
        'isToday': DateUtils.isSameDay(date, now),
        'weekday': DateFormat('E').format(date),
        'dayNumber': DateFormat('d').format(date),
        'mood': null,
        'title': null,
        'hasEntry': false,
      };
    });
  }
}
