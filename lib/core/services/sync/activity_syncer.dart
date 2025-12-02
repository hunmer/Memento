import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../../../plugins/activity/activity_plugin.dart';
import '../../../plugins/activity/models/activity_weekly_widget_config.dart';
import '../../../plugins/activity/services/activity_widget_service.dart';
import '../../plugin_manager.dart';
import 'plugin_widget_syncer.dart';
import 'package:memento_widgets/memento_widgets.dart';

/// 活动记录插件同步器
class ActivitySyncer extends PluginWidgetSyncer {
  @override
  Future<void> sync() async {
    if (!isWidgetSupported()) {
      debugPrint('Widget not supported on this platform, skipping update for activity');
      return;
    }

    await syncSafely('activity', () async {
      final plugin = PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
      if (plugin == null) return;

      final activityCount = await plugin.getTodayActivityCount();
      final durationMinutes = await plugin.getTodayActivityDuration();
      final remainingMinutes = plugin.getTodayRemainingTime();

      final durationHours = (durationMinutes / 60.0).toStringAsFixed(1);
      final remainingHours = (remainingMinutes / 60.0).toStringAsFixed(1);

      final totalDayMinutes = 24 * 60;
      final coveragePercent = (durationMinutes / totalDayMinutes * 100).toStringAsFixed(0);

      await updateWidget(
        pluginId: 'activity',
        pluginName: '活动',
        iconCodePoint: Icons.timeline.codePoint,
        colorValue: Colors.purple.value,
        stats: [
          WidgetStatItem(id: 'count', label: '今日活动', value: '$activityCount'),
          WidgetStatItem(id: 'duration', label: '已记录', value: '${durationHours}h'),
          WidgetStatItem(
            id: 'remaining',
            label: '剩余时间',
            value: '${remainingHours}h',
            highlight: remainingMinutes < 120,
            colorValue: remainingMinutes < 120 ? Colors.red.value : null,
          ),
          WidgetStatItem(id: 'coverage', label: '覆盖率', value: '$coveragePercent%'),
        ],
      );
    });
  }

  /// 同步周视图活动列表小组件
  ///
  /// 遍历所有已配置的周视图小组件，更新其数据
  Future<void> syncActivityWeeklyWidget() async {
    try {
      final plugin = PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
      if (plugin == null) {
        debugPrint('Activity plugin not found, skipping weekly widget sync');
        return;
      }

      // 获取所有已配置的小组件ID列表
      final widgetIdsJson = await HomeWidget.getWidgetData<String>(
        'activity_weekly_widget_ids',
      );

      if (widgetIdsJson == null || widgetIdsJson.isEmpty) {
        debugPrint('No configured activity weekly widgets found');
        return;
      }

      final widgetIds = List<int>.from(jsonDecode(widgetIdsJson) as List);

      final widgetService = ActivityWidgetService(plugin);

      // 同步每个小组件
      for (final widgetId in widgetIds) {
        try {
          await _syncSingleWeeklyWidget(widgetId, widgetService);
        } catch (e) {
          debugPrint('Failed to sync activity weekly widget $widgetId: $e');
        }
      }

      debugPrint('Synced ${widgetIds.length} activity weekly widgets');
    } catch (e) {
      debugPrint('Failed to sync activity weekly widgets: $e');
    }
  }

  /// 同步单个周视图小组件
  Future<void> _syncSingleWeeklyWidget(
    int widgetId,
    ActivityWidgetService widgetService,
  ) async {
    // 读取小组件配置
    final widgetDataJson = await HomeWidget.getWidgetData<String>(
      'activity_weekly_data_$widgetId',
    );

    int weekOffset = 0;
    if (widgetDataJson != null && widgetDataJson.isNotEmpty) {
      try {
        final widgetData = jsonDecode(widgetDataJson) as Map<String, dynamic>;
        final configJson = widgetData['config'] as Map<String, dynamic>?;
        if (configJson != null) {
          final config = ActivityWeeklyWidgetConfig.fromJson(configJson);
          weekOffset = config.currentWeekOffset;
        }
      } catch (e) {
        debugPrint('Failed to parse widget config for $widgetId: $e');
      }
    }

    // 计算周数据
    final weekData = await widgetService.calculateWeekData(weekOffset);

    // 更新数据（保留现有配置，只更新数据部分）
    if (widgetDataJson != null && widgetDataJson.isNotEmpty) {
      try {
        final widgetData = jsonDecode(widgetDataJson) as Map<String, dynamic>;
        widgetData['data'] = weekData.toJson();

        await HomeWidget.saveWidgetData<String>(
          'activity_weekly_data_$widgetId',
          jsonEncode(widgetData),
        );

        debugPrint('Updated activity weekly widget $widgetId data');
      } catch (e) {
        debugPrint('Failed to update widget $widgetId data: $e');
      }
    }
  }
}
