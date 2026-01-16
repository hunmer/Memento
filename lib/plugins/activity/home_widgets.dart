import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selectable_item.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:intl/intl.dart';
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
    // 活动小组件 - 支持公共小组件样式（不需要选择数据）
    registry.register(
      HomeWidget(
        id: 'activity_common_widgets',
        pluginId: 'activity',
        name: 'activity_commonWidgetsName'.tr,
        description: 'activity_commonWidgetsDesc'.tr,
        icon: Icons.dashboard,
        color: Colors.pink,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large, HomeWidgetSize.custom],
        category: 'home_categoryRecord'.tr,
        commonWidgetsProvider: _provideCommonWidgets,
        builder: (context, config) {
          return StatefulBuilder(
            builder: (context, setState) {
              return EventListenerContainer(
                events: const [
                  'activity_added',
                  'activity_updated',
                  'activity_deleted',
                ],
                onEvent: () => setState(() {}),
                child: _buildCommonWidgetsWidget(context, config),
              );
            },
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
      return HomeWidget.buildErrorWidget(context, e.toString());
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

  /// 构建公共小组件显示
  static Widget _buildCommonWidgetsWidget(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    final selectorConfig =
        config['selectorWidgetConfig'] as Map<String, dynamic>?;
    if (selectorConfig == null) {
      return HomeWidget.buildErrorWidget(
        context,
        '配置错误：缺少 selectorWidgetConfig',
      );
    }

    final commonWidgetId = selectorConfig['commonWidgetId'] as String?;
    final commonWidgetProps =
        selectorConfig['commonWidgetProps'] as Map<String, dynamic>?;

    if (commonWidgetId == null || commonWidgetProps == null) {
      return HomeWidget.buildErrorWidget(
        context,
        '配置错误：缺少 commonWidgetId 或 commonWidgetProps',
      );
    }

    // 查找对应的 CommonWidgetId 枚举
    final widgetIdEnum = CommonWidgetId.values.asNameMap()[commonWidgetId];
    if (widgetIdEnum == null) {
      return HomeWidget.buildErrorWidget(
        context,
        '未知的公共小组件类型: $commonWidgetId',
      );
    }

    // 获取元数据以确定默认尺寸
    final metadata = CommonWidgetsRegistry.getMetadata(widgetIdEnum);

    return CommonWidgetBuilder.build(
      context,
      widgetIdEnum,
      commonWidgetProps,
      metadata.defaultSize,
    );
  }

  /// 构建动态热力图小组件（支持事件触发时重新获取数据）
  static Widget _buildDynamicHeatmapWidget(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    // 解析选择器配置
    final selectorConfig =
        config['selectorWidgetConfig'] as Map<String, dynamic>?;
    if (selectorConfig == null) {
      return HomeWidget.buildErrorWidget(
        context,
        '配置错误：缺少 selectorWidgetConfig',
      );
    }

    // 检查是否使用了公共小组件
    final commonWidgetId = selectorConfig['commonWidgetId'] as String?;
    if (commonWidgetId == null || commonWidgetId != 'activityHeatmapCard') {
      return HomeWidget.buildErrorWidget(context, '配置错误：未配置活动热力图组件');
    }

    // 获取选择器数据
    final selectedData =
        selectorConfig['selectedData'] as Map<String, dynamic>?;
    if (selectedData == null) {
      return HomeWidget.buildErrorWidget(context, '无法获取选择的数据');
    }

    // 获取小组件定义
    final registry = HomeWidgetRegistry();
    final widgetDef = registry.getWidget('activity_heatmap');
    if (widgetDef == null || widgetDef.commonWidgetsProvider == null) {
      return HomeWidget.buildErrorWidget(context, '小组件定义错误');
    }

    // 从 selectedData 中提取时间粒度配置
    Map<String, dynamic> data = {};
    if (selectedData.containsKey('data')) {
      final dataArray = selectedData['data'];
      if (dataArray is List && dataArray.isNotEmpty) {
        final rawData = dataArray[0];
        if (rawData is Map<String, dynamic>) {
          data = rawData;
        } else if (rawData != null && rawData is Map) {
          data = Map<String, dynamic>.from(rawData);
        }
      }
    }

    // 动态调用 commonWidgetsProvider 获取最新数据
    final availableWidgets = widgetDef.commonWidgetsProvider!(data);
    final latestProps = availableWidgets['activityHeatmapCard'];

    if (latestProps == null) {
      return HomeWidget.buildErrorWidget(context, '无法获取最新数据');
    }

    // 使用公共组件构建器渲染
    final commonWidgetIdEnum = CommonWidgetId.activityHeatmapCard;
    final metadata = CommonWidgetsRegistry.getMetadata(commonWidgetIdEnum);

    return CommonWidgetBuilder.build(
      context,
      commonWidgetIdEnum,
      latestProps,
      metadata.defaultSize,
    );
  }

  /// 导航处理函数
  static void _navigateToActivityMain(
    BuildContext context,
    SelectorResult result,
  ) {
    try {
      Navigator.push(
        context,
        NavigationHelper.createRoute(const ActivityMainView()),
      );
    } catch (e) {
      toastService.showToast('activity_operationFailed'.tr);
      debugPrint('[ActivityHomeWidgets] 导航失败: $e');
    }
  }

  /// 构建动态今日活动统计小组件（支持事件触发时重新获取数据）
  static Widget _buildDynamicTodayPieChartWidget(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    // 获取小组件定义
    final registry = HomeWidgetRegistry();
    final widgetDef = registry.getWidget('activity_today_pie_chart');
    if (widgetDef == null || widgetDef.commonWidgetsProvider == null) {
      return HomeWidget.buildErrorWidget(context, '小组件定义错误');
    }

    // 动态调用 commonWidgetsProvider 获取最新数据
    final availableWidgets = widgetDef.commonWidgetsProvider!({});
    final latestProps = availableWidgets['activityTodayPieChartCard'];

    if (latestProps == null) {
      return HomeWidget.buildErrorWidget(context, '无法获取最新数据');
    }

    // 使用公共组件构建器渲染
    final commonWidgetIdEnum = CommonWidgetId.activityTodayPieChartCard;
    final metadata = CommonWidgetsRegistry.getMetadata(commonWidgetIdEnum);

    return CommonWidgetBuilder.build(
      context,
      commonWidgetIdEnum,
      latestProps,
      metadata.defaultSize,
    );
  }

  /// 公共小组件提供者函数（同步版本）
  static Map<String, Map<String, dynamic>> _provideCommonWidgets(
    Map<String, dynamic> data,
  ) {
    // 获取今日活动数据
    final plugin =
        PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
    if (plugin == null) return {};

    final now = DateTime.now();

    // 同步获取今日活动（使用缓存）
    final todayActivities = plugin.getTodayActivitiesSync();

    // 同步获取昨日活动（使用缓存）
    final yesterdayActivities = plugin.getYesterdayActivitiesSync();

    // 计算今日统计数据
    final todayActivityCount = todayActivities.length;
    final todayDurationMinutes = todayActivities.fold<int>(
      0,
      (sum, a) => sum + a.durationInMinutes,
    );
    final remainingMinutes = plugin.getTodayRemainingTime();

    // 按标签统计
    final tagStats = <String, int>{};
    for (final activity in todayActivities) {
      for (final tag in activity.tags) {
        tagStats[tag] = (tagStats[tag] ?? 0) + activity.durationInMinutes;
      }
    }

    // 按标签分类活动
    final activitiesByTag = <String, List<ActivityRecord>>{};
    for (final activity in todayActivities) {
      for (final tag in activity.tags) {
        activitiesByTag.putIfAbsent(tag, () => []).add(activity);
      }
    }

    // 计算今日活动中的最长时长
    final maxDurationMinutes =
        todayActivities.isEmpty
            ? 60.0
            : todayActivities
                .map((a) => a.durationInMinutes.toDouble())
                .reduce((a, b) => a > b ? a : b);

    return {
      // 分段进度卡片：按标签统计时长
      'segmentedProgressCard': {
        'title': '今日活动',
        'subtitle': '$todayActivityCount个活动',
        'currentValue': todayDurationMinutes.toDouble(),
        'targetValue': (12 * 60).toDouble(), // 12小时目标
        'unit': '分钟',
        'segments':
            tagStats.entries
                .map(
                  (e) => {
                    'label': e.key,
                    'value': e.value.toDouble(),
                    'display': _formatDurationForDisplay(e.value),
                    'color': _getColorFromTagForWidgets(e.key).value,
                  },
                )
                .toList(),
      },

      // 任务进度卡片：显示今日活动进度
      'taskProgressCard': {
        'title': '今日活动',
        'subtitle': '$todayActivityCount个记录',
        'completedTasks': now.hour,
        'totalTasks': 24,
        'progressLabel': '今日时间',
        'pendingLabel': '活动列表',
        'maxPendingTasks': null,
        'pendingTasks':
            todayActivities
                .map(
                  (a) =>
                      '${a.title.isEmpty ? '未命名活动' : a.title} · ${_formatTimeRangeStatic(a.startTime, a.endTime)}',
                )
                .toList(),
      },

      // 营养进度卡片：左侧今日剩余时间，右侧活动列表
      'nutritionProgressCard': {
        'leftData': {
          'current': (24 * 60 - remainingMinutes).toDouble(),
          'total': (24 * 60).toDouble(),
          'unit': '分钟',
        },
        'leftConfig': {
          'icon': '⏰',
          'label': '今日剩余',
          'subtext': '${(remainingMinutes / 60).toStringAsFixed(1)}小时',
        },
        'rightItems':
            todayActivities
                .take(4)
                .map(
                  (a) => {
                    'icon': '📝',
                    'name': a.title.isEmpty ? '未命名活动' : a.title,
                    'current': a.durationInMinutes.toDouble(),
                    'total': maxDurationMinutes, // 使用今日最长活动时长作为总值
                    'color': Colors.blue.value,
                    'subtitle':
                        '${_formatTimeStatic(a.startTime)} - ${_formatTimeStatic(a.endTime)}',
                  },
                )
                .toList(),
      },

      // 观看进度卡片：显示活动列表
      'watchProgressCard': {
        'userName': '今日活动',
        'lastWatched': '',
        'enableHeader': false,
        'progressLabel': '已用时间',
        'currentCount': now.hour,
        'totalCount': 24,
        'items':
            todayActivities
                .map(
                  (a) => {
                    'title': a.title.isEmpty ? '未命名活动' : a.title,
                    'subtitle':
                        '${_formatTimeStatic(a.startTime)} - ${_formatTimeStatic(a.endTime)}',
                    'thumbnailUrl': null,
                  },
                )
                .toList(),
      },

      // 每日日程卡片：今日活动和昨日活动
      'dailyScheduleCard': {
        'todayDate': '${now.month}月${now.day}日',
        'todayEvents':
            todayActivities
                .map((a) => _convertActivityToEventData(a))
                .toList(),
        'tomorrowEvents':
            yesterdayActivities
                .map((a) => _convertActivityToEventData(a))
                .toList(),
      },

      // 支出分类环形图：按标签统计活动时长
      'expenseDonutChart': {
        'badgeLabel': '活动',
        'timePeriod': '${now.month}月${now.day}日',
        'totalAmount': todayDurationMinutes.toDouble() / 60,
        'totalUnit': '小时',
        'categories':
            tagStats.entries
                .map(
                  (e) => {
                    'label': e.key,
                    'percentage': todayDurationMinutes > 0
                        ? (e.value / todayDurationMinutes * 100)
                        : 0.0,
                    'color': _getColorFromTagForWidgets(e.key).value,
                    'subtitle': _formatActivitiesTimeRange(activitiesByTag[e.key] ?? []),
                  },
                )
                .toList(),
      },

      // 任务列表卡片
      'taskListCard': {
        'title': '今日活动',
        'count': todayActivityCount,
        'countLabel': '个活动',
        'items':
            todayActivities
                .map((a) => a.title.isEmpty ? '未命名活动' : a.title)
                .toList(),
        'moreCount': 0,
      },

      // 彩色标签任务列表卡片
      'colorTagTaskCard': {
        'taskCount': todayActivityCount,
        'label': '今日活动',
        'tasks':
            todayActivities.map((a) {
              final primaryTag = a.tags.isNotEmpty ? a.tags.first : '默认';
              final timeRange = _formatTimeRangeStatic(a.startTime, a.endTime);
              return {
                'title': '($timeRange)',
                'color': _getColorFromTagForWidgets(primaryTag).value,
                'tag': a.title.isEmpty ? '未命名活动' : a.title,
              };
            }).toList(),
        'moreCount': 0,
      },

      // 即将到来的任务小组件：显示接下来的活动
      'upcomingTasksWidget': {
        'title': '活动',
        'taskCount': todayActivityCount,
        'moreCount': 0,
        'tasks':
            todayActivities
                .take(4)
                .map(
                  (a) => {
                    'title': a.title.isEmpty ? '未命名活动' : a.title,
                    'color': a.tags.isNotEmpty
                        ? _getColorFromTagForWidgets(a.tags.first).value
                        : Colors.pink.value,
                    'tag': _formatTimeRangeStatic(a.startTime, a.endTime),
                  },
                )
                .toList(),
      },

      // 圆角任务列表卡片
      'roundedTaskListCard': {
        'headerText': '今日活动',
        'tasks':
            todayActivities
                .map(
                  (a) => {
                    'title': a.title.isEmpty ? '未命名活动' : a.title,
                    'subtitle': _formatTimeRangeStatic(a.startTime, a.endTime),
                    'date': '${now.month}月${now.day}日',
                  },
                )
                .toList(),
      },

      // 圆角提醒事项列表
      'roundedRemindersList': {
        'title': '今日活动',
        'count': todayActivityCount,
        'items':
            todayActivities
                .map(
                  (a) => {
                    'text': a.title.isEmpty ? '未命名活动' : a.title,
                    'isCompleted': true,
                  },
                )
                .toList(),
      },

      // 现代圆角消费卡片：显示活动时长
      'modernRoundedSpendingWidget': {
        'title': '今日活动',
        'currentAmount': todayDurationMinutes.toDouble(),
        'budgetAmount': (12 * 60).toDouble(), // 12小时目标
        'unit': '分钟',
        'categories':
            tagStats.entries
                .map(
                  (e) => {
                    'name': e.key,
                    'amount': e.value.toDouble(),
                    'color': _getColorFromTagForWidgets(e.key).value,
                  },
                )
                .toList(),
        'categoryItems':
            activitiesByTag.entries
                .map(
                  (e) => {
                    'categoryName': e.key,
                    'items':
                        e.value
                            .take(5)
                            .map(
                              (a) => {
                                'title': a.title.isEmpty ? '未命名活动' : a.title,
                                'subtitle': '${a.durationInMinutes}分钟',
                              },
                            )
                            .toList(),
                  },
                )
                .toList(),
      },

      // 分类堆叠消费卡片
      'categoryStackWidget': {
        'title': '今日活动分布',
        'currentAmount': todayDurationMinutes.toDouble(),
        'targetAmount': (12 * 60).toDouble(),
        'categories':
            tagStats.entries
                .map(
                  (e) => {
                    'name': e.key,
                    'amount': e.value.toDouble(),
                    'color': _getColorFromTagForWidgets(e.key).value,
                  },
                )
                .toList(),
      },

      // 时间线日程卡片：显示昨天和今天的活动
      'timelineScheduleCard': _buildTimelineScheduleCardData(
        todayActivities,
        yesterdayActivities,
        now,
      ),

      // 活动热力图卡片
      'activityHeatmapCard': _buildHeatmapCardData(todayActivities, data),

      // 今日活动统计卡片
      'activityTodayPieChartCard': {
        'tagStats': tagStats,
        'totalDuration': todayDurationMinutes,
      },
    };
  }

  /// 构建活动热力图卡片数据
  static Map<String, dynamic> _buildHeatmapCardData(
    List<ActivityRecord> activities,
    Map<String, dynamic> selectorData,
  ) {
    // 获取时间粒度（从选择器数据或使用默认值60分钟）
    int timeGranularity = 60;
    if (selectorData.containsKey('timeGranularity')) {
      timeGranularity = selectorData['timeGranularity'] as int? ?? 60;
    }

    // 计算时间槽数据
    final timeSlots = _calculateTimeSlotDataForWidget(
      activities,
      timeGranularity,
    );

    // 计算总时长
    final totalMinutes = activities.fold<int>(
      0,
      (sum, a) => sum + a.durationInMinutes,
    );

    // 计算活跃小时数
    final activeHours = _calculateActiveHoursForWidget(activities);

    // 转换时间槽数据为 Map 格式
    final timeSlotsList =
        timeSlots
            .map(
              (slot) => {
                'hour': slot.hour,
                'minute': slot.minute,
                'durationMinutes': slot.durationMinutes,
                'tagDurations': slot.tagDurations,
              },
            )
            .toList();

    return {
      'timeGranularity': timeGranularity,
      'timeSlots': timeSlotsList,
      'totalMinutes': totalMinutes,
      'activeHours': activeHours,
    };
  }

  /// 计算指定时间粒度的数据（用于公共组件）
  static List<_TimeSlotDataWrapper> _calculateTimeSlotDataForWidget(
    List<ActivityRecord> activities,
    int granularityMinutes,
  ) {
    final totalSlots = (24 * 60) ~/ granularityMinutes;
    final slots = <_TimeSlotDataWrapper>[];
    final now = DateTime.now();

    for (int i = 0; i < totalSlots; i++) {
      final hour = (i * granularityMinutes) ~/ 60;
      final minute = (i * granularityMinutes) % 60;

      final slotStart = DateTime(now.year, now.month, now.day, hour, minute);
      final slotEnd = slotStart.add(Duration(minutes: granularityMinutes));

      int totalMinutes = 0;
      final Map<String, int> tagDurations = {};

      for (final activity in activities) {
        if (activity.startTime.isBefore(slotEnd) &&
            activity.endTime.isAfter(slotStart)) {
          final effectiveStart =
              activity.startTime.isBefore(slotStart)
                  ? slotStart
                  : activity.startTime;
          final effectiveEnd =
              activity.endTime.isAfter(slotEnd) ? slotEnd : activity.endTime;

          if (effectiveEnd.isAfter(effectiveStart)) {
            final minutes = effectiveEnd.difference(effectiveStart).inMinutes;
            totalMinutes += minutes;

            // 收集每个标签的时长
            for (final tag in activity.tags) {
              tagDurations[tag] = (tagDurations[tag] ?? 0) + minutes;
            }
          }
        }
      }

      slots.add(
        _TimeSlotDataWrapper(
          hour: hour,
          minute: minute,
          durationMinutes: totalMinutes,
          tagDurations: tagDurations,
        ),
      );
    }

    return slots;
  }

  /// 计算活跃小时数（用于公共组件）
  static int _calculateActiveHoursForWidget(List<ActivityRecord> activities) {
    final activeHours = <int>{};
    for (final activity in activities) {
      final startHour = activity.startTime.hour;
      final endHour = activity.endTime.hour;

      for (int h = startHour; h <= endHour; h++) {
        final hourStart = DateTime(
          activity.startTime.year,
          activity.startTime.month,
          activity.startTime.day,
          h,
          0,
        );
        final hourEnd = hourStart.add(const Duration(hours: 1));

        if (activity.startTime.isBefore(hourEnd) &&
            activity.endTime.isAfter(hourStart)) {
          activeHours.add(h);
        }
      }
    }
    return activeHours.length;
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
        MaterialPageRoute(builder: (context) => const ActivityEditScreen()),
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

class _ActivityLastActivityWidgetState
    extends State<ActivityLastActivityWidget> {
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
              Icon(Icons.history, color: Colors.pink, size: 32),
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
              Icon(Icons.add_circle, color: Colors.pink, size: 24),
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
              Icon(Icons.edit, color: Colors.pink.withAlpha(150), size: 20),
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
        MaterialPageRoute(builder: (context) => const ActivityEditScreen()),
      );
    } catch (e) {
      toastService.showToast('activity_operationFailed'.tr);
      debugPrint('[ActivityLastActivity] 打开创建界面失败: $e');
    }
  }
}

/// 时间槽数据
class TimeSlotData {
  final int hour;
  final int minute;
  final int durationMinutes;

  /// 标签到时长的映射（用于确定主要标签颜色）
  final Map<String, int> tagDurations;

  TimeSlotData({
    required this.hour,
    required this.minute,
    required this.durationMinutes,
    this.tagDurations = const {},
  });

  /// 获取持续时间最长的标签
  String? get primaryTag {
    if (tagDurations.isEmpty) return null;
    return tagDurations.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

/// 格式化时间范围（静态版本）
String _formatTimeRangeStatic(DateTime start, DateTime end) {
  return '${_formatTimeStatic(start)} - ${_formatTimeStatic(end)}';
}

/// 格式化时间（HH:mm）（静态版本）
String _formatTimeStatic(DateTime time) {
  return DateFormat('HH:mm').format(time);
}

/// 从标签生成颜色（与 ActivityGridView 保持一致）
Color _getColorFromTagForWidgets(String tag) {
  final baseHue = (tag.hashCode % 360).abs().toDouble();
  return HSLColor.fromAHSL(1.0, baseHue, 0.6, 0.5).toColor();
}

/// 格式化时长为显示文本（如果超过60分钟转小时，带小数点）
String _formatDurationForDisplay(int minutes) {
  if (minutes >= 60) {
    final hours = minutes / 60;
    // 如果是整数小时，不显示小数
    if (hours == hours.truncateToDouble()) {
      return '${hours.toInt()}小时';
    }
    // 否则显示一位小数
    return '${hours.toStringAsFixed(1)}小时';
  }
  return '$minutes分钟';
}

/// 格式化活动列表的时间段为字符串
String _formatActivitiesTimeRange(List<ActivityRecord> activities) {
  if (activities.isEmpty) return '';

  // 按开始时间排序
  final sortedActivities = List<ActivityRecord>.from(activities);
  sortedActivities.sort((a, b) => a.startTime.compareTo(b.startTime));

  // 最多显示3个时间段
  final timeRanges = sortedActivities
      .take(3)
      .map((a) => _formatTimeRangeStatic(a.startTime, a.endTime))
      .toList();

  if (sortedActivities.length > 3) {
    return '${timeRanges.join('、')}...';
  }

  return timeRanges.join('、');
}

/// 将活动记录转换为 DailyScheduleCardWidget 的 EventData 格式
Map<String, dynamic> _convertActivityToEventData(ActivityRecord activity) {
  // 将 24 小时制转换为 12 小时制
  final startHour = activity.startTime.hour;
  final endHour = activity.endTime.hour;

  final startPeriod = startHour >= 12 ? 'PM' : 'AM';
  final endPeriod = endHour >= 12 ? 'PM' : 'AM';

  final startHour12 = startHour == 0 ? 12 : (startHour > 12 ? startHour - 12 : startHour);
  final endHour12 = endHour == 0 ? 12 : (endHour > 12 ? endHour - 12 : endHour);

  // 根据标签选择颜色
  String color = 'gray';
  if (activity.tags.isNotEmpty) {
    final primaryTag = activity.tags.first;
    color = _getColorNameFromTag(primaryTag);
  }

  return {
    'title': activity.title.isEmpty ? '未命名活动' : activity.title,
    'startTime': startHour12.toString().padLeft(2, '0'),
    'startPeriod': startPeriod,
    'endTime': endHour12.toString().padLeft(2, '0'),
    'endPeriod': endPeriod,
    'color': color,
    'location': null,
    'isAllDay': false,
  };
}

/// 根据标签获取颜色名称
String _getColorNameFromTag(String tag) {
  final colorValue = _getColorFromTagForWidgets(tag).value;

  // 简单映射：根据颜色值范围选择预设颜色
  if (colorValue == 0xFFF97316) return 'orange';
  if (colorValue == 0xFF4ADE80) return 'green';
  if (colorValue == 0xFF60A5FA) return 'blue';
  if (colorValue == 0xFFF87171) return 'red';
  return 'gray';
}

/// 时间槽数据包装类（用于公共组件数据传递）
class _TimeSlotDataWrapper {
  final int hour;
  final int minute;
  final int durationMinutes;
  final Map<String, int> tagDurations;

  _TimeSlotDataWrapper({
    required this.hour,
    required this.minute,
    required this.durationMinutes,
    this.tagDurations = const {},
  });
}

/// 构建时间线日程卡片数据
/// 显示今天和昨天的活动（ TimelineScheduleCard 组件使用）
Map<String, dynamic> _buildTimelineScheduleCardData(
  List<ActivityRecord> todayActivities,
  List<ActivityRecord> yesterdayActivities,
  DateTime now,
) {
  // 计算昨天的日期
  final yesterday = now.subtract(const Duration(days: 1));

  // 获取星期名称
  final todayWeekday = _getWeekdayName(now.weekday);
  final yesterdayWeekday = _getWeekdayName(yesterday.weekday);

  // 转换今日活动为 TimelineEvent 格式
  final todayEvents = todayActivities
      .map((a) => _convertActivityToTimelineEvent(a))
      .toList();

  // 转换昨日活动为 TimelineEvent 格式
  final yesterdayEvents = yesterdayActivities
      .map((a) => _convertActivityToTimelineEvent(a))
      .toList();

  return {
    'todayWeekday': todayWeekday,
    'todayDay': now.day,
    'tomorrowWeekday': yesterdayWeekday,
    'tomorrowDay': yesterday.day,
    'todayEvents': todayEvents,
    'tomorrowEvents': yesterdayEvents,
  };
}

/// 获取星期名称（中文）
String _getWeekdayName(int weekday) {
  const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
  return weekdays[(weekday - 1) % 7];
}

/// 将活动记录转换为 TimelineEvent 格式
Map<String, dynamic> _convertActivityToTimelineEvent(
  ActivityRecord activity,
) {
  // 获取主标签颜色
  final tagColor = activity.tags.isNotEmpty
      ? _getColorFromTagForWidgets(activity.tags.first)
      : Colors.pink;

  // 计算背景色和文本色
  final backgroundColorLight = tagColor.withOpacity(0.15);
  final backgroundColorDark = tagColor.withOpacity(0.25);
  final textColorLight = tagColor;
  final textColorDark = tagColor.withOpacity(0.9);

  // 格式化时间显示（如 "9:45AM"）
  final timeDisplay = _formatTimeToAMPM(activity.startTime);

  return {
    'hour': activity.startTime.hour,
    'title': activity.title.isEmpty ? '未命名活动' : activity.title,
    'time': timeDisplay,
    'color': tagColor.value,
    'backgroundColorLight': backgroundColorLight.value,
    'backgroundColorDark': backgroundColorDark.value,
    'textColorLight': textColorLight.value,
    'textColorDark': textColorDark.value,
    'subtextLight': const Color(0xFF8E8E93).value,
    'subtextDark': const Color(0xFF98989D).value,
  };
}

/// 格式化时间为 AM/PM 格式（如 "9:45AM"）
String _formatTimeToAMPM(DateTime time) {
  final hour = time.hour;
  final minute = time.minute;
  final period = hour >= 12 ? 'PM' : 'AM';
  final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  final minuteStr = minute.toString().padLeft(2, '0');
  return '$hour12:$minuteStr$period';
}
