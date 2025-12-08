import 'package:flutter/material.dart';
import 'package:Memento/plugins/nodes/nodes_plugin.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'plugin_widget_syncer.dart';
import 'package:memento_widgets/memento_widgets.dart';

/// 节点插件同步器
class NodesSyncer extends PluginWidgetSyncer {
  @override
  Future<void> sync() async {
    await syncSafely('nodes', () async {
      final plugin = PluginManager.instance.getPlugin('nodes') as NodesPlugin?;
      if (plugin == null) return;

      final notebookCount = plugin.getNotebookCount();
      final totalNodes = plugin.getTotalNodeCount();
      final todayAdded = plugin.getTodayAddedNodeCount();

      await updateWidget(
        pluginId: 'nodes',
        pluginName: '节点',
        iconCodePoint: Icons.account_tree.codePoint,
        colorValue: Colors.cyan.value,
        stats: [
          WidgetStatItem(id: 'notebooks', label: '笔记本数', value: '$notebookCount'),
          WidgetStatItem(id: 'nodes', label: '总节点数', value: '$totalNodes'),
          WidgetStatItem(
            id: 'today',
            label: '今日新增',
            value: '$todayAdded',
            highlight: todayAdded > 0,
            colorValue: todayAdded > 0 ? Colors.green.value : null,
          ),
        ],
      );
    });
  }
}
