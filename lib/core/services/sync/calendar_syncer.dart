import 'package:flutter/material.dart';
import '../../../plugins/calendar/calendar_plugin.dart';
import '../../plugin_manager.dart';
import 'plugin_widget_syncer.dart';
import 'package:memento_widgets/memento_widgets.dart';

/// 日历插件同步器
class CalendarSyncer extends PluginWidgetSyncer {
  @override
  Future<void> sync() async {
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
}
