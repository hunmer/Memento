import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'package:fl_chart/fl_chart.dart';
import 'activity_plugin.dart';
import 'screens/activity_edit_screen.dart';
import 'models/activity_record.dart';

/// 活动插件的主页小组件注册
class ActivityHomeWidgets {
  /// 注册所有活动插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(
      HomeWidget(
        id: 'activity_icon',
        pluginId: 'activity',
        name: 'activity_widgetName'.tr,
        description: 'activity_widgetDescription'.tr,
        icon: Icons.timeline,
        color: Colors.pink,
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
        category: 'home_categoryRecord'.tr,
        builder:
            (context, config) => GenericIconWidget(
              icon: Icons.timeline,
              color: Colors.pink,
              name: 'activity_widgetName'.tr,
            ),
      ),
    );

    // 2x2 详细卡片 - 显示统计信息
    registry.register(
      HomeWidget(
        id: 'activity_overview',
        pluginId: 'activity',
        name: 'activity_overviewName'.tr,
        description: 'activity_overviewDescription'.tr,
        icon: Icons.access_time,
        color: Colors.pink,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large],
        category: 'home_categoryRecord'.tr,
        builder: (context, config) => _buildOverviewWidget(context, config),
        availableStatsProvider: _getAvailableStats,
      ),
    );

    // 1x1 创建活动快捷入口 - 直接跳转
    registry.register(
      HomeWidget(
        id: 'activity_create_shortcut',
        pluginId: 'activity',
        name: 'activity_createActivityShortcut'.tr,
        description: 'activity_createActivityShortcutDesc'.tr,
        icon: Icons.add_circle,
        color: Colors.pink,
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
        category: 'home_categoryRecord'.tr,
        builder: (context, config) => const ActivityCreateShortcutWidget(),
      ),
    );

    // 1x2 上次活动小组件 - 显示距离上次活动的时间
    registry.register(
      HomeWidget(
        id: 'activity_last_activity',
        pluginId: 'activity',
        name: '上次活动',
        description: '显示距离上次活动经过的时间和上次活动的时间',
        icon: Icons.history,
        color: Colors.pink,
        defaultSize: HomeWidgetSize.medium, // 2x1
        supportedSizes: [HomeWidgetSize.medium],
        category: 'home_categoryRecord'.tr,
        builder: (context, config) => const ActivityLastActivityWidget(),
      ),
    );

    // 2x3 今日活动统计小组件 - 饼状图展示
    registry.register(
      HomeWidget(
        id: 'activity_today_pie_chart',
        pluginId: 'activity',
        name: '今日活动统计',
        description: '使用饼状图展示今日活动统计',
        icon: Icons.pie_chart,
        color: Colors.pink,
        defaultSize: HomeWidgetSize.large3, // 2x3
        supportedSizes: [HomeWidgetSize.large3],
        category: 'home_categoryRecord'.tr,
        builder: (context, config) => const ActivityTodayPieChartWidget(),
      ),
    );
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    try {
      final plugin =
          PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
      if (plugin == null) return [];

      final activityCount = plugin.getTodayActivityCountSync();
      final activityDuration = plugin.getTodayActivityDurationSync();
      final remainingTime = plugin.getTodayRemainingTime();

      return [
        StatItemData(
          id: 'today_activities',
          label: 'activity_todayActivities'.tr,
          value: '$activityCount',
          highlight: activityCount > 0,
          color: Colors.pink,
        ),
        StatItemData(
          id: 'today_duration',
          label: 'activity_todayDuration'.tr,
          value: '${(activityDuration / 60).toStringAsFixed(1)}H',
          highlight: false,
        ),
        StatItemData(
          id: 'remaining_time',
          label: 'activity_remainingTime'.tr,
          value: '${(remainingTime / 60).toStringAsFixed(1)}H',
          highlight: remainingTime < 120,
          color: Colors.red,
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

      // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
      return StatefulBuilder(
        builder: (context, setState) {
          return EventListenerContainer(
            events: const [
              'activity_added',
              'activity_updated',
              'activity_deleted',
            ],
            onEvent: () => setState(() {}),
            child: _buildOverviewContent(context, widgetConfig),
          );
        },
      );
    } catch (e) {
      return _buildErrorWidget(context, e.toString());
    }
  }

  /// 构建概览小组件内容（获取最新数据）
  static Widget _buildOverviewContent(
    BuildContext context,
    PluginWidgetConfig widgetConfig,
  ) {
    // 获取可用的统计项数据（每次重建时重新获取）
    final availableItems = _getAvailableStats(context);

    // 使用通用小组件
    return GenericPluginWidget(
      pluginId: 'activity',
      pluginName: 'activity_name'.tr,
      pluginIcon: Icons.access_time,
      pluginDefaultColor: Colors.pink,
      availableItems: availableItems,
      config: widgetConfig,
    );
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
}

/// 创建活动快捷入口小组件（1x1）
class ActivityCreateShortcutWidget extends StatelessWidget {
  const ActivityCreateShortcutWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth.clamp(0.0, constraints.maxHeight);
        final iconSize = size * 0.4;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _navigateToCreateActivity(context),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle, size: iconSize, color: Colors.pink),
                  SizedBox(height: size * 0.05),
                  Text(
                    'activity_createActivity'.tr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: (size * 0.12).clamp(10.0, 14.0),
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToCreateActivity(BuildContext context) {
    try {
      final plugin =
          PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
      if (plugin == null) {
        toastService.showToast('activity_loadFailed'.tr);
        return;
      }

      final activityService = plugin.activityService;
      final now = DateTime.now();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => ActivityEditScreen(
                activityService: activityService,
                selectedDate: now,
                onTagsUpdated: (tags) async {
                  await activityService.saveRecentTags(tags);
                },
              ),
        ),
      );
    } catch (e) {
      toastService.showToast('activity_operationFailed'.tr);
      debugPrint('[ActivityCreateShortcut] 打开创建界面失败: $e');
    }
  }
}

/// 上次活动小组件（2x1）
/// 显示距离上次活动经过的时间和上次活动的时间，点击跳转到活动编辑界面
class ActivityLastActivityWidget extends StatefulWidget {
  const ActivityLastActivityWidget({super.key});

  @override
  State<ActivityLastActivityWidget> createState() =>
      _ActivityLastActivityWidgetState();
}

class _ActivityLastActivityWidgetState extends State<ActivityLastActivityWidget> {
  @override
  Widget build(BuildContext context) {
    return EventListenerContainer(
      events: const ['activity_added', 'activity_updated', 'activity_deleted'],
      onEvent: () => setState(() {}),
      child: FutureBuilder<ActivityRecord?>(
        future: _getLastActivity(),
        builder: (context, snapshot) {
          final lastActivity = snapshot.data;

          if (lastActivity == null) {
            return _buildNoActivityWidget(context);
          }

          return _buildLastActivityWidget(context, lastActivity);
        },
      ),
    );
  }

  Future<ActivityRecord?> _getLastActivity() async {
    try {
      final plugin =
          PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
      if (plugin == null) return null;
      return await plugin.activityService.getLastActivity();
    } catch (e) {
      debugPrint('[ActivityLastActivity] 获取上次活动失败: $e');
      return null;
    }
  }

  Widget _buildNoActivityWidget(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToCreateActivity(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.history,
                color: Colors.pink,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '暂无活动记录',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '点击添加第一个活动',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.add_circle,
                color: Colors.pink,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastActivityWidget(
    BuildContext context,
    ActivityRecord activity,
  ) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final endTime = activity.endTime;
    final timeDiff = now.difference(endTime);

    // 格式化时间差
    String timeAgo;
    if (timeDiff.inMinutes < 1) {
      timeAgo = '刚刚';
    } else if (timeDiff.inHours < 1) {
      timeAgo = '${timeDiff.inMinutes}分钟前';
    } else if (timeDiff.inDays < 1) {
      timeAgo = '${timeDiff.inHours}小时前';
    } else {
      timeAgo = '${timeDiff.inDays}天前';
    }

    // 活动标题（如果没有标题则使用"未命名活动"）
    final title = activity.title.trim().isEmpty ? '未命名活动' : activity.title;

    // 计算持续时长
    final duration = activity.endTime.difference(activity.startTime);
    final durationText = _formatDuration(duration.inMinutes);

    // 构建副标题信息
    final List<String> subtitleParts = [];

    // 添加心情
    if (activity.mood != null && activity.mood!.isNotEmpty) {
      subtitleParts.add(activity.mood!);
    }

    // 添加标签
    if (activity.tags.isNotEmpty) {
      subtitleParts.add(activity.tags.join(', '));
    }

    // 添加持续时长
    subtitleParts.add(durationText);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToCreateActivity(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.pink.withAlpha(25),
          ),
          child: Row(
            children: [
              Icon(
                Icons.history,
                color: Colors.pink,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '上次活动: $timeAgo',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleParts.join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withAlpha(180),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.edit,
                color: Colors.pink.withAlpha(150),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
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

  void _navigateToCreateActivity(BuildContext context) {
    try {
      final plugin =
          PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
      if (plugin == null) {
        toastService.showToast('activity_loadFailed'.tr);
        return;
      }

      final activityService = plugin.activityService;
      final now = DateTime.now();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => ActivityEditScreen(
                activityService: activityService,
                selectedDate: now,
                onTagsUpdated: (tags) async {
                  await activityService.saveRecentTags(tags);
                },
              ),
        ),
      );
    } catch (e) {
      toastService.showToast('activity_operationFailed'.tr);
      debugPrint('[ActivityLastActivity] 打开创建界面失败: $e');
    }
  }
}

/// 今日活动统计饼状图小组件（2x3）
/// 使用饼状图展示今日活动统计
class ActivityTodayPieChartWidget extends StatefulWidget {
  const ActivityTodayPieChartWidget({super.key});

  @override
  State<ActivityTodayPieChartWidget> createState() =>
      _ActivityTodayPieChartWidgetState();
}

class _ActivityTodayPieChartWidgetState
    extends State<ActivityTodayPieChartWidget> {
  @override
  Widget build(BuildContext context) {
    return EventListenerContainer(
      events: const ['activity_added', 'activity_updated', 'activity_deleted'],
      onEvent: () => setState(() {}),
      child: FutureBuilder<Map<String, int>>(
        future: _getTodayActivityStats(),
        builder: (context, snapshot) {
          final stats = snapshot.data ?? {};

          if (stats.isEmpty) {
            return _buildNoActivityWidget(context);
          }

          return _buildPieChartWidget(context, stats);
        },
      ),
    );
  }

  Future<Map<String, int>> _getTodayActivityStats() async {
    try {
      final plugin =
          PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
      if (plugin == null) return {};

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      return await plugin.activityService.getActivityStatsByTag(
        startOfDay,
        endOfDay,
      );
    } catch (e) {
      debugPrint('[ActivityTodayPieChart] 获取统计失败: $e');
      return {};
    }
  }

  Widget _buildNoActivityWidget(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.pink.withAlpha(25),
      ),
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
          const SizedBox(height: 12),

          // 占位内容，保持2x3布局
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pie_chart,
                  color: Colors.pink.withAlpha(100),
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  '今日暂无活动',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withAlpha(150),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '添加活动后查看统计',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 底部占位文字
          Text(
            '总时长: 0分钟',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartWidget(
    BuildContext context,
    Map<String, int> stats,
  ) {
    final theme = Theme.of(context);

    // 按时长排序，只显示前5个
    final sortedEntries = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.pink.withAlpha(25),
      ),
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
          const SizedBox(height: 8),

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

          const SizedBox(height: 8),

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

          const SizedBox(height: 4),

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
        titleStyle: const TextStyle(
          fontSize: 10,
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
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
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
