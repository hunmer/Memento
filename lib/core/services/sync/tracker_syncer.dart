import 'package:flutter/material.dart';
import '../../../plugins/tracker/tracker_plugin.dart';
import '../../plugin_manager.dart';
import 'plugin_widget_syncer.dart';
import 'package:memento_widgets/memento_widgets.dart';

/// 目标追踪插件同步器
class TrackerSyncer extends PluginWidgetSyncer {
  @override
  Future<void> sync() async {
    await syncSafely('tracker', () async {
      final plugin = PluginManager.instance.getPlugin('tracker') as TrackerPlugin?;
      if (plugin == null) return;

      final totalGoals = plugin.getGoalCount();
      final activeGoals = plugin.getActiveGoalCount();
      final todayRecords = plugin.getTodayRecordCount();

      await updateWidget(
        pluginId: 'tracker',
        pluginName: '目标',
        iconCodePoint: Icons.track_changes.codePoint,
        colorValue: Colors.orange.value,
        stats: [
          WidgetStatItem(id: 'total', label: '总目标数', value: '$totalGoals'),
          WidgetStatItem(
            id: 'active',
            label: '进行中',
            value: '$activeGoals',
            highlight: activeGoals > 0,
            colorValue: activeGoals > 0 ? Colors.blue.value : null,
          ),
          WidgetStatItem(
            id: 'records',
            label: '今日记录',
            value: '$todayRecords',
            highlight: todayRecords > 0,
            colorValue: todayRecords > 0 ? Colors.green.value : null,
          ),
        ],
      );
    });
  }
}
