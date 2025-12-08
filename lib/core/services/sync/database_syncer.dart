import 'package:flutter/material.dart';
import 'package:Memento/plugins/database/database_plugin.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'plugin_widget_syncer.dart';
import 'package:memento_widgets/memento_widgets.dart';

/// 数据库插件同步器
class DatabaseSyncer extends PluginWidgetSyncer {
  @override
  Future<void> sync() async {
    await syncSafely('database', () async {
      final plugin = PluginManager.instance.getPlugin('database') as DatabasePlugin?;
      if (plugin == null) return;

      final databaseCount = await plugin.service.getDatabaseCount();
      final todayRecordCount = await plugin.service.getTodayRecordCount(plugin.controller);
      final totalRecordCount = await plugin.service.getTotalRecordCount(plugin.controller);

      await updateWidget(
        pluginId: 'database',
        pluginName: '数据库',
        iconCodePoint: Icons.storage.codePoint,
        colorValue: Colors.grey.value,
        stats: [
          WidgetStatItem(
            id: 'total_records',
            label: '总记录数',
            value: '$totalRecordCount',
          ),
          WidgetStatItem(
            id: 'today_records',
            label: '今日新增',
            value: '$todayRecordCount',
            highlight: todayRecordCount > 0,
            colorValue: todayRecordCount > 0 ? Colors.green.value : null,
          ),
          WidgetStatItem(
            id: 'databases',
            label: '数据库表数',
            value: '$databaseCount',
          ),
        ],
      );
    });
  }
}
