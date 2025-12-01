import 'package:flutter/material.dart';
import '../../../plugins/activity/activity_plugin.dart';
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
}
