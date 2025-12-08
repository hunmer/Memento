import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/calendar/calendar_plugin.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'plugin_widget_syncer.dart';
import 'package:memento_widgets/memento_widgets.dart';

/// 日历插件同步器
class CalendarSyncer extends PluginWidgetSyncer {
  // 防止重复同步的标志
  bool _isSyncingPendingEvents = false;

  @override
  Future<void> sync() async {
    if (!isWidgetSupported()) {
      return;
    }
    await syncSafely('calendar', () async {
      final plugin = PluginManager.instance.getPlugin('calendar') as CalendarPlugin?;
      if (plugin == null) return;

      final todayCount = plugin.getTodayEventCount();
      final weekCount = plugin.getWeekEventCount();
      final pendingCount = plugin.getPendingEventCount();

      await updateWidget(
        pluginId: 'calendar',
        pluginName: '日历',
        iconCodePoint: Icons.calendar_today.codePoint,
        colorValue: Colors.teal.value,
        stats: [
          WidgetStatItem(
            id: 'today',
            label: '今日事件',
            value: '$todayCount',
            highlight: todayCount > 0,
            colorValue: todayCount > 0 ? Colors.blue.value : null,
          ),
          WidgetStatItem(
            id: 'week',
            label: '本周事件',
            value: '$weekCount',
          ),
          WidgetStatItem(
            id: 'pending',
            label: '待办事件',
            value: '$pendingCount',
            highlight: pendingCount > 0,
            colorValue: pendingCount > 0 ? Colors.orange.value : null,
          ),
        ],
      );
    });
  }

  /// 应用启动或恢复时同步待处理的日历事件完成操作
  /// 当用户在小组件上点击 checkbox 完成任务时，事件 ID 会被保存到待同步队列
  /// 此方法检查队列并执行实际的完成操作
  Future<void> syncPendingEventsOnStartup() async {
    if (_isSyncingPendingEvents) {
      debugPrint('Already syncing pending calendar events, skipping');
      return;
    }

    try {
      _isSyncingPendingEvents = true;

      final plugin = PluginManager.instance.getPlugin('calendar') as CalendarPlugin?;
      if (plugin == null) {
        debugPrint('Calendar plugin not found, skipping pending events sync');
        return;
      }

      // 读取待同步的完成事件队列
      final pendingJson = await MyWidgetManager().getData<String>(
        'calendar_pending_complete_events',
      );

      if (pendingJson == null || pendingJson.isEmpty || pendingJson == '[]') {
        return;
      }

      debugPrint('发现待同步的日历完成事件: $pendingJson');

      final List<dynamic> pendingIds = jsonDecode(pendingJson);
      if (pendingIds.isEmpty) return;

      int completedCount = 0;

      for (final eventId in pendingIds) {
        try {
          // 查找事件
          final event = plugin.controller.events.firstWhere(
            (e) => e.id == eventId,
            orElse: () => throw Exception('Event not found: $eventId'),
          );

          // 执行实际的完成操作
          plugin.controller.completeEvent(event);
          completedCount++;
          debugPrint('小组件日历事件已完成: $eventId');
        } catch (e) {
          debugPrint('完成小组件日历事件失败: $eventId - $e');
        }
      }

      // 清空待同步队列
      await MyWidgetManager().saveString(
        'calendar_pending_complete_events',
        '[]',
      );

      if (completedCount > 0) {
        debugPrint('已处理 $completedCount 个小组件待完成日历事件');
        // 同步小组件数据以反映最新状态
        plugin.syncWidgetData();
      }
    } catch (e) {
      debugPrint('处理小组件待完成日历事件失败: $e');
    } finally {
      _isSyncingPendingEvents = false;
    }
  }
}
