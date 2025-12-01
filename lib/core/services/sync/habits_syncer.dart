import 'package:flutter/material.dart';
import '../../../plugins/habits/habits_plugin.dart';
import '../../plugin_manager.dart';
import 'plugin_widget_syncer.dart';
import 'package:memento_widgets/memento_widgets.dart';

/// 习惯插件同步器
class HabitsSyncer extends PluginWidgetSyncer {
  @override
  Future<void> sync() async {
    if (!isWidgetSupported()) {
      debugPrint('Widget not supported on this platform, skipping update for habits');
      return;
    }

    await syncSafely('habits', () async {
      final plugin = PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
      if (plugin == null) return;

      final habitCount = plugin.getHabitController().getHabits().length;
      final skillCount = plugin.getSkillController().getSkills().length;

      await updateWidget(
        pluginId: 'habits',
        pluginName: '习惯',
        iconCodePoint: Icons.auto_awesome.codePoint,
        colorValue: Colors.amber.value,
        stats: [
          WidgetStatItem(id: 'habits', label: '习惯', value: '$habitCount'),
          WidgetStatItem(id: 'skills', label: '技能', value: '$skillCount'),
        ],
      );
    });
  }
}
