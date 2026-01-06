import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selectable_item.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
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

    // 2x3 活动热力图小组件 - 展示最近活动分布
    registry.register(
      HomeWidget(
        id: 'activity_heatmap',
        pluginId: 'activity',
        name: '活动热力图',
        description: '展示最近活动的热力图分布',
        icon: Icons.grid_on,
        color: Colors.pink,
        defaultSize: HomeWidgetSize.large3, // 2x3
        supportedSizes: [HomeWidgetSize.large3],
        category: 'home_categoryRecord'.tr,
        selectorId: 'activity.heatmap_granularity',
        dataSelector: extractHeatmapConfig,
        dataRenderer: renderHeatmapData,
        builder: (context, config) {
          return GenericSelectorWidget(
            widgetDefinition: registry.getWidget('activity_heatmap')!,
            config: config,
          );
        },
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

  /// 从选择器数据提取热力图配置
  static Map<String, dynamic> extractHeatmapConfig(List<dynamic> dataArray) {
    int granularity = 60; // 默认值
    final item = dataArray[0];

    // 提取 rawData
    if (item is SelectableItem) {
      granularity = item.rawData as int;
    } else if (item is int) {
      granularity = item;
    }

    return {'timeGranularity': granularity};
  }

  /// 渲染热力图数据
  static Widget renderHeatmapData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    return ActivityHeatmapWidget(config: config);
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

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ActivityEditScreen(),
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
          child: Row(
            children: [
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

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ActivityEditScreen(),
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

    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 12),

          // 占位内容，保持2x3布局
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
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

/// 活动热力图小组件（2x3）
/// 展示今日24小时的活动热力图，颜色深浅表示活动密集程度
class ActivityHeatmapWidget extends StatefulWidget {
  final Map<String, dynamic> config;

  const ActivityHeatmapWidget({
    super.key,
    this.config = const {},
  });

  @override
  State<ActivityHeatmapWidget> createState() => _ActivityHeatmapWidgetState();
}

class _ActivityHeatmapWidgetState extends State<ActivityHeatmapWidget> {
  // 存储已使用的颜色，用于确保颜色有明显区别
  final Map<String, Color> _tagColorCache = {};

  // 获取时间粒度配置（默认60分钟）
  int get _timeGranularity {
    return widget.config['timeGranularity'] as int? ?? 60;
  }

  @override
  Widget build(BuildContext context) {
    return EventListenerContainer(
      events: const ['activity_added', 'activity_updated', 'activity_deleted'],
      onEvent: () => setState(() {}),
      child: FutureBuilder<List<ActivityRecord>>(
        future: _getTodayActivities(),
        builder: (context, snapshot) {
          final activities = snapshot.data ?? [];

          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _navigateToActivity(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '今日活动热力图',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.pink,
                              ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Colors.pink.withAlpha(150),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 24小时热力图网格
                    Expanded(
                      child: _buildHeatmap(activities),
                    ),

                    const SizedBox(height: 8),

                    // 图例
                    _buildLegend(activities),

                    const SizedBox(height: 4),

                    // 统计信息
                    _buildStats(activities),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<List<ActivityRecord>> _getTodayActivities() async {
    try {
      final plugin =
          PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
      if (plugin == null) return [];

      final now = DateTime.now();
      return await plugin.activityService.getActivitiesForDate(now);
    } catch (e) {
      debugPrint('[ActivityHeatmap] 获取今日活动失败: $e');
      return [];
    }
  }

  Widget _buildHeatmap(List<ActivityRecord> activities) {
    final granularity = _timeGranularity;

    switch (granularity) {
      case 5:
        return _buildGranularHeatmap(activities, 5);
      case 10:
        return _buildGranularHeatmap(activities, 10);
      case 15:
        return _buildGranularHeatmap(activities, 15);
      case 30:
        return _buildGranularHeatmap(activities, 30);
      case 60:
      default:
        return _build60MinHeatmap(activities);
    }
  }

  // 通用的细粒度热力图构建方法（5/10/15/30分钟）
  Widget _buildGranularHeatmap(List<ActivityRecord> activities, int granularity) {
    final slots = _calculateTimeSlotData(activities, granularity);
    final columns = 12;
    final rows = (slots.length / columns).ceil();

    // 确保至少有1行
    final actualRows = rows > 0 ? rows : 1;

    // 使用 Column + Expanded 填满可用高度
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(actualRows, (row) {
        return Expanded(
          flex: 1,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(columns, (col) {
              final index = row * columns + col;
              if (index >= slots.length) {
                return const Expanded(child: SizedBox());
              }
              final data = slots[index];
              return Expanded(
                flex: 1,
                child: _buildHeatmapCell(
                  hour: data.hour,
                  durationMinutes: data.durationMinutes,
                  label: '',
                  showLabel: false,
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  // 60分钟粒度（24小时，4行6列）- 显示文本
  Widget _build60MinHeatmap(List<ActivityRecord> activities) {
    final hourlyData = _calculateHourlyData(activities);

    return Column(
      children: List.generate(4, (row) {
        return Expanded(
          child: Row(
            children: List.generate(6, (col) {
              final index = row * 6 + col;
              final data = hourlyData[index];
              return Expanded(
                child: _buildHeatmapCell(
                  hour: data.hour,
                  durationMinutes: data.durationMinutes,
                  label: '${data.hour}',
                  showLabel: true,
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  // 计算每小时的数据
  List<TimeSlotData> _calculateHourlyData(List<ActivityRecord> activities) {
    return List.generate(24, (hour) {
      int totalMinutes = 0;

      for (final activity in activities) {
        if (_activityCoversHour(activity, hour)) {
          totalMinutes += _calculateMinutesInHour(activity, hour);
        }
      }

      return TimeSlotData(hour: hour, minute: 0, durationMinutes: totalMinutes);
    });
  }

  // 计算指定时间粒度的数据
  List<TimeSlotData> _calculateTimeSlotData(List<ActivityRecord> activities, int granularityMinutes) {
    final totalSlots = (24 * 60) ~/ granularityMinutes;
    final slots = <TimeSlotData>[];

    for (int i = 0; i < totalSlots; i++) {
      final hour = (i * granularityMinutes) ~/ 60;
      final minute = (i * granularityMinutes) % 60;

      final slotStart = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        hour,
        minute,
      );
      final slotEnd = slotStart.add(Duration(minutes: granularityMinutes));

      int totalMinutes = 0;

      for (final activity in activities) {
        if (activity.startTime.isBefore(slotEnd) && activity.endTime.isAfter(slotStart)) {
          final effectiveStart = activity.startTime.isBefore(slotStart)
              ? slotStart
              : activity.startTime;
          final effectiveEnd = activity.endTime.isAfter(slotEnd)
              ? slotEnd
              : activity.endTime;

          if (effectiveEnd.isAfter(effectiveStart)) {
            totalMinutes += effectiveEnd.difference(effectiveStart).inMinutes;
          }
        }
      }

      slots.add(TimeSlotData(hour: hour, minute: minute, durationMinutes: totalMinutes));
    }

    return slots;
  }

  Widget _buildHeatmapCell({
    required int hour,
    required int durationMinutes,
    required String label,
    bool showLabel = true,
  }) {
    final color = _getSlotColor(durationMinutes, _timeGranularity);
    final isActive = durationMinutes > 0;

    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: showLabel
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (label.isNotEmpty)
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _getTextColor(color),
                    ),
                  ),
                if (isActive) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatMinutes(durationMinutes),
                    style: TextStyle(
                      fontSize: 8,
                      color: _getTextColor(color),
                    ),
                  ),
                ],
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Color _getSlotColor(int minutes, int granularity) {
    if (minutes == 0) {
      return Colors.grey.withValues(alpha: 0.1);
    }

    // 根据占时间槽的比例来决定颜色
    final ratio = minutes / granularity;

    if (ratio < 0.25) {
      return Colors.pink.withValues(alpha: 0.3);
    } else if (ratio < 0.5) {
      return Colors.pink.withValues(alpha: 0.5);
    } else if (ratio < 0.75) {
      return Colors.pink.withValues(alpha: 0.7);
    } else {
      return Colors.pink;
    }
  }

  Color _getTextColor(Color background) {
    if (background == Colors.grey.withValues(alpha: 0.1)) {
      return Colors.grey.withValues(alpha: 0.7);
    }
    return background.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '${hours}h${mins}m' : '${hours}h';
    }
  }

  // 检查活动是否覆盖指定小时
  bool _activityCoversHour(ActivityRecord activity, int hour) {
    final hourStart = DateTime(
      activity.startTime.year,
      activity.startTime.month,
      activity.startTime.day,
      hour,
      0,
    );
    final hourEnd = hourStart.add(const Duration(hours: 1));

    return activity.startTime.isBefore(hourEnd) &&
           activity.endTime.isAfter(hourStart);
  }

  // 计算活动在指定小时内的时长
  int _calculateMinutesInHour(ActivityRecord activity, int hour) {
    final hourStart = DateTime(
      activity.startTime.year,
      activity.startTime.month,
      activity.startTime.day,
      hour,
      0,
    );
    final hourEnd = hourStart.add(const Duration(hours: 1));

    final effectiveStart = activity.startTime.isBefore(hourStart)
        ? hourStart
        : activity.startTime;
    final effectiveEnd = activity.endTime.isAfter(hourEnd)
        ? hourEnd
        : activity.endTime;

    if (effectiveEnd.isBefore(effectiveStart)) {
      return 0;
    }

    return effectiveEnd.difference(effectiveStart).inMinutes;
  }

  Widget _buildLegend(List<ActivityRecord> activities) {
    // 统计标签使用情况
    final tagStats = <String, int>{};
    for (final activity in activities) {
      for (final tag in activity.tags) {
        tagStats[tag] = (tagStats[tag] ?? 0) + activity.durationInMinutes;
      }
    }

    // 取前3个标签
    final topTags = tagStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final displayTags = topTags.take(3).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: displayTags.map((entry) {
        final color = _getColorFromTag(entry.key);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              entry.key,
              style: const TextStyle(fontSize: 9),
            ),
          ],
        );
      }).toList(),
    );
  }

  // 从标签生成颜色（参考 activity_grid_view.dart）
  Color _getColorFromTag(String tag) {
    if (_tagColorCache.containsKey(tag)) {
      return _tagColorCache[tag]!;
    }

    final baseHue = (tag.hashCode % 360).abs().toDouble();
    final color = HSLColor.fromAHSL(1.0, baseHue, 0.6, 0.5).toColor();
    _tagColorCache[tag] = color;
    return color;
  }

  Widget _buildStats(List<ActivityRecord> activities) {
    if (activities.isEmpty) {
      return Text(
        '今日暂无活动',
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(180),
        ),
      );
    }

    final totalMinutes = activities.fold<int>(
      0,
      (sum, activity) => sum + activity.durationInMinutes,
    );
    final activeHours = _calculateActiveHours(activities);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '总时长: ${_formatMinutes(totalMinutes)}',
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(180),
          ),
        ),
        Text(
          '活跃: $activeHours小时',
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(180),
          ),
        ),
      ],
    );
  }

  int _calculateActiveHours(List<ActivityRecord> activities) {
    final activeHours = <int>{};
    for (final activity in activities) {
      final startHour = activity.startTime.hour;
      final endHour = activity.endTime.hour;

      for (int h = startHour; h <= endHour; h++) {
        if (_activityCoversHour(activity, h)) {
          activeHours.add(h);
        }
      }
    }
    return activeHours.length;
  }

  void _navigateToActivity(BuildContext context) {
    try {
      Navigator.push(
        context,
        NavigationHelper.createRoute(const ActivityMainView()),
      );
    } catch (e) {
      toastService.showToast('activity_operationFailed'.tr);
      debugPrint('[ActivityHeatmap] 导航失败: $e');
    }
  }
}

/// 时间槽数据
class TimeSlotData {
  final int hour;
  final int minute;
  final int durationMinutes;

  TimeSlotData({
    required this.hour,
    required this.minute,
    required this.durationMinutes,
  });
}
