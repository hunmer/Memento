import 'package:flutter/material.dart';
import '../../../plugins/timer/timer_plugin.dart';
import '../../plugin_manager.dart';
import 'plugin_widget_syncer.dart';
import 'package:memento_widgets/memento_widgets.dart';

/// 计时器插件同步器
class TimerSyncer extends PluginWidgetSyncer {
  @override
  Future<void> sync() async {
    await syncSafely('timer', () async {
      final plugin = PluginManager.instance.getPlugin('timer') as TimerPlugin?;
      if (plugin == null) return;

      final tasks = plugin.getTasks();
      final totalCount = tasks.length;
      final runningCount = tasks.where((task) => task.isRunning).length;

      await updateWidget(
        pluginId: 'timer',
        pluginName: '计时器',
        iconCodePoint: Icons.timer.codePoint,
        colorValue: Colors.blueGrey.value,
        stats: [
          WidgetStatItem(id: 'total', label: '总计时器', value: '$totalCount'),
          WidgetStatItem(
            id: 'running',
            label: '运行中',
            value: '$runningCount',
            highlight: runningCount > 0,
            colorValue: runningCount > 0 ? Colors.green.value : null,
          ),
        ],
      );
    });
  }
}
