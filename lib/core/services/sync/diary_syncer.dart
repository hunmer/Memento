import 'package:flutter/material.dart';
import '../../../plugins/diary/diary_plugin.dart';
import '../../plugin_manager.dart';
import 'plugin_widget_syncer.dart';
import 'package:memento_widgets/memento_widgets.dart';

/// 日记插件同步器
class DiarySyncer extends PluginWidgetSyncer {
  @override
  Future<void> sync() async {
    if (!isWidgetSupported()) {
      return;
    }

    await syncSafely('diary', () async {
      final plugin = PluginManager.instance.getPlugin('diary') as DiaryPlugin?;
      if (plugin == null) return;

      final todayCount = await plugin.getTodayWordCount();
      final monthCount = await plugin.getMonthWordCount();
      final progress = await plugin.getMonthProgress();
      final completedDays = progress.$1;
      final totalDays = progress.$2;

      await updateWidget(
        pluginId: 'diary',
        pluginName: '日记',
        iconCodePoint: Icons.book.codePoint,
        colorValue: Colors.brown.value,
        stats: [
          WidgetStatItem(
            id: 'today',
            label: '今日字数',
            value: '$todayCount',
            highlight: todayCount > 0,
            colorValue: todayCount > 0 ? Colors.deepOrange.value : null,
          ),
          WidgetStatItem(
            id: 'month',
            label: '本月字数',
            value: '$monthCount',
          ),
          WidgetStatItem(
            id: 'progress',
            label: '本月进度',
            value: '$completedDays/$totalDays',
            highlight: completedDays == totalDays,
            colorValue: completedDays == totalDays ? Colors.green.value : null,
          ),
        ],
      );
    });
  }
}
