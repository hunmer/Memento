import 'package:flutter/material.dart';
import '../../../plugins/day/day_plugin.dart';
import '../../plugin_manager.dart';
import 'plugin_widget_syncer.dart';
import 'package:memento_widgets/memento_widgets.dart';

/// 纪念日插件同步器
class DaySyncer extends PluginWidgetSyncer {
  @override
  Future<void> sync() async {
    await syncSafely('day', () async {
      final plugin = PluginManager.instance.getPlugin('day') as DayPlugin?;
      if (plugin == null) return;

      final totalCount = plugin.getMemorialDayCount();
      final upcomingCount = plugin.getUpcomingMemorialDayCount();
      final todayCount = plugin.getTodayMemorialDayCount();

      await updateWidget(
        pluginId: 'day',
        pluginName: '纪念日',
        iconCodePoint: Icons.celebration.codePoint,
        colorValue: Colors.pink.value,
        stats: [
          WidgetStatItem(
            id: 'total',
            label: '总纪念日数',
            value: '$totalCount',
          ),
          WidgetStatItem(
            id: 'upcoming',
            label: '即将到来',
            value: '$upcomingCount',
            highlight: upcomingCount > 0,
            colorValue: upcomingCount > 0 ? Colors.amber.value : null,
          ),
          WidgetStatItem(
            id: 'today',
            label: '今日纪念日',
            value: '$todayCount',
            highlight: todayCount > 0,
            colorValue: todayCount > 0 ? Colors.red.value : null,
          ),
        ],
      );
    });
  }
}
