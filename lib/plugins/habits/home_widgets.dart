import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/plugins/habits/models/habit.dart';
import 'package:Memento/plugins/habits/models/completion_record.dart';
import 'habits_plugin.dart';

/// 习惯追踪插件的主页小组件注册
class HabitsHomeWidgets {
  /// 注册所有习惯追踪插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(
      HomeWidget(
        id: 'habits_icon',
        pluginId: 'habits',
        name: 'habits_widgetName'.tr,
        description: 'habits_widgetDescription'.tr,
        icon: Icons.auto_awesome,
        color: Colors.amber,
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
        category: 'home_categoryRecord'.tr,
        builder:
            (context, config) => GenericIconWidget(
              icon: Icons.auto_awesome,
              color: Colors.amber,
              name: 'habits_widgetName'.tr,
            ),
      ),
    );

    // 2x2 详细卡片 - 显示统计信息
    registry.register(
      HomeWidget(
        id: 'habits_overview',
        pluginId: 'habits',
        name: 'habits_overviewName'.tr,
        description: 'habits_overviewDescription'.tr,
        icon: Icons.trending_up,
        color: Colors.amber,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large],
        category: 'home_categoryRecord'.tr,
        builder: (context, config) => _buildOverviewWidget(context, config),
        availableStatsProvider: _getAvailableStats,
      ),
    );

    // 习惯热力图选择器小组件 - 显示单个习惯的完成记录热力图
    registry.register(
      HomeWidget(
        id: 'habits_habit_heatmap',
        pluginId: 'habits',
        name: 'habits_heatmapWidgetName'.tr,
        description: 'habits_heatmapWidgetDescription'.tr,
        icon: Icons.calendar_today,
        color: Colors.amber,
        defaultSize: HomeWidgetSize.medium,
        supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
        category: 'home_categoryRecord'.tr,
        selectorId: 'habits.habit',
        dataRenderer: _renderHabitHeatmapData,
        navigationHandler: _navigateToHabitDetail,
        dataSelector: _extractHabitHeatmapData,
        builder:
            (context, config) => GenericSelectorWidget(
              widgetDefinition: registry.getWidget('habits_habit_heatmap')!,
              config: config,
            ),
      ),
    );
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    try {
      final plugin =
          PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
      if (plugin == null) return [];

      final habitController = plugin.getHabitController();
      final skillController = plugin.getSkillController();
      final timerController = plugin.timerController;

      final habitCount = habitController.getHabits().length;
      final skillCount = skillController.getSkills().length;
      final activeTimers = timerController.getActiveTimers();
      final activeTimerCount = activeTimers.values.where((v) => v).length;

      return [
        StatItemData(
          id: 'habits_count',
          label: '习惯数',
          value: '$habitCount',
          highlight: habitCount > 0,
          color: Colors.amber,
        ),
        StatItemData(
          id: 'skills_count',
          label: '技能数',
          value: '$skillCount',
          highlight: false,
        ),
        StatItemData(
          id: 'active_timers_count',
          label: '活动计时器',
          value: '$activeTimerCount',
          highlight: activeTimerCount > 0,
          color: Colors.orange,
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    try {
      // 解析插件配置
      PluginWidgetConfig widgetConfig;
      try {
        if (config.containsKey('pluginWidgetConfig')) {
          widgetConfig = PluginWidgetConfig.fromJson(
            config['pluginWidgetConfig'] as Map<String, dynamic>,
          );
        } else {
          widgetConfig = PluginWidgetConfig();
        }
      } catch (e) {
        widgetConfig = PluginWidgetConfig();
      }

      // 获取可用的统计项数据
      final availableItems = _getAvailableStats(context);

      // 使用通用小组件
      return GenericPluginWidget(
        pluginId: 'habits',
        pluginName: 'habits_name'.tr,
        pluginIcon: Icons.auto_awesome,
        pluginDefaultColor: Colors.amber,
        availableItems: availableItems,
        config: widgetConfig,
      );
    } catch (e) {
      return _buildErrorWidget(context, e.toString());
    }
  }

  /// 构建错误提示组件
  static Widget _buildErrorWidget(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 32, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            'home_loadFailed'.tr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // ===== 习惯热力图小组件相关方法 =====

  /// 从选择器数据中提取小组件需要的数据
  static Map<String, dynamic> _extractHabitHeatmapData(
    List<dynamic> dataArray,
  ) {
    if (dataArray.isEmpty) {
      return {};
    }

    final rawData = dataArray[0];

    // 处理 Habit 对象
    if (rawData is Habit) {
      return {
        'id': rawData.id,
        'title': rawData.title,
        'group': rawData.group,
        'icon': rawData.icon,
        'color': Colors.amber.value,
      };
    }

    // 处理 Map 类型
    if (rawData is Map<String, dynamic>) {
      return {
        'id': rawData['id']?.toString(),
        'title': rawData['title']?.toString(),
        'group': rawData['group']?.toString(),
        'icon': rawData['icon']?.toString(),
        'color': Colors.amber.value,
      };
    }

    // 其他情况返回空 Map
    return {};
  }

  /// 渲染习惯热力图数据
  static Widget _renderHabitHeatmapData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    final theme = Theme.of(context);

    if (result.data == null) {
      return _buildErrorWidget(context, '数据不存在');
    }

    final savedData =
        result.data is Map<String, dynamic>
            ? result.data as Map<String, dynamic>
            : {};

    final habitId = savedData['id'] as String?;
    final title = savedData['title'] as String? ?? '未知习惯';
    final group = savedData['group'] as String?;
    final iconCode = savedData['icon'] as String?;
    final colorValue = savedData['color'] as int? ?? Colors.amber.value;

    return FutureBuilder<_HabitHeatmapData?>(
      future: _loadHabitHeatmapData(habitId),
      builder: (context, snapshot) {
        final heatmapData = snapshot.data;
        final widgetSize = config['widgetSize'] as HomeWidgetSize?;

        return Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 习惯图标和标题
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(colorValue).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child:
                        iconCode != null
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
              ),
              // 热力图（根据卡片大小显示不同范围）
              if (heatmapData != null &&
                  (widgetSize == HomeWidgetSize.medium ||
                      widgetSize == HomeWidgetSize.large)) ...[
                const SizedBox(height: 8),
                _buildHeatmapGrid(context, heatmapData, widgetSize!),
              ],
            ],
          ),
        );
      },
    );
  }

  /// 加载习惯热力图数据
  static Future<_HabitHeatmapData?> _loadHabitHeatmapData(
    String? habitId,
  ) async {
    if (habitId == null || habitId.isEmpty) return null;

    try {
      final plugin =
          PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
      if (plugin == null) return null;

      final recordController = plugin.getRecordController();
      final records = await recordController.getHabitCompletionRecords(habitId);

      // 计算总时长
      int totalMinutes = 0;
      for (final record in records) {
        totalMinutes += (record.duration.inMinutes as int);
      }

      return _HabitHeatmapData(
        habitId: habitId,
        records: records,
        totalMinutes: totalMinutes,
      );
    } catch (e) {
      debugPrint('加载习惯热力图数据失败: $e');
      return null;
    }
  }

  /// 构建热力图网格（参考 checkin 插件实现）
  static Widget _buildHeatmapGrid(
    BuildContext context,
    _HabitHeatmapData data,
    HomeWidgetSize size,
  ) {
    final today = DateTime.now();
    final List<int> dayNumbers = [];
    final List<int> dailyMinutes = [];
    final habitColor = Colors.amber;

    if (size == HomeWidgetSize.medium) {
      // medium: 显示过去7天
      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        dayNumbers.add(date.day);
        dailyMinutes.add(_getMinutesForDate(data.records, date));
      }
    } else {
      // large: 显示当月所有日期
      final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(today.year, today.month, day);
        dayNumbers.add(day);
        dailyMinutes.add(_getMinutesForDate(data.records, date));
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
    final spacing = size == HomeWidgetSize.medium ? 4.0 : 3.0;
    final showNumber = size == HomeWidgetSize.large;
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
                  child:
                      showNumber
                          ? Center(
                            child: Text(
                              '$day',
                              style: TextStyle(
                                fontSize: fontSize,
                                color:
                                    minutes > 0
                                        ? Colors.black54
                                        : Colors.black26,
                                fontWeight:
                                    minutes > 0
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

  /// 获取指定日期的完成时长（分钟）
  static int _getMinutesForDate(List<CompletionRecord> records, DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return records
        .where(
          (r) =>
              '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}' ==
              dateStr,
        )
        .fold<int>(0, (sum, r) => sum + r.duration.inMinutes);
  }

  /// 导航到习惯详情页（显示计时器对话框）
  static void _navigateToHabitDetail(
    BuildContext context,
    SelectorResult result,
  ) {
    final data =
        result.data is Map<String, dynamic>
            ? result.data as Map<String, dynamic>
            : {};
    final habitId = data['id'] as String?;

    if (habitId != null) {
      // 使用路由跳转到习惯计时器页面
      NavigationHelper.pushNamed(
        context,
        '/habit/timer',
        arguments: {'habitId': habitId, 'action': 'show_dialog'},
      );
    }
  }
}

/// 习惯热力图数据模型
class _HabitHeatmapData {
  final String habitId;
  final List<CompletionRecord> records;
  final int totalMinutes;

  _HabitHeatmapData({
    required this.habitId,
    required this.records,
    required this.totalMinutes,
  });
}
