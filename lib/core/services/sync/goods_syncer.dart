import 'package:flutter/material.dart';
import '../../../plugins/goods/goods_plugin.dart';
import '../../plugin_manager.dart';
import 'plugin_widget_syncer.dart';
import 'package:memento_widgets/memento_widgets.dart';

/// 物品管理插件同步器
class GoodsSyncer extends PluginWidgetSyncer {
  @override
  Future<void> sync() async {
    await syncSafely('goods', () async {
      final plugin = PluginManager.instance.getPlugin('goods') as GoodsPlugin?;
      if (plugin == null) return;

      final totalItems = plugin.getTotalItemsCount();
      final todayUsage = plugin.getTodayUsageCount();
      final warehouseCount = plugin.warehouses.length;

      await updateWidget(
        pluginId: 'goods',
        pluginName: '物品',
        iconCodePoint: Icons.inventory.codePoint,
        colorValue: Colors.deepOrange.value,
        stats: [
          WidgetStatItem(id: 'total', label: '总物品数', value: '$totalItems'),
          WidgetStatItem(
            id: 'today_usage',
            label: '今日使用',
            value: '$todayUsage',
            highlight: todayUsage > 0,
            colorValue: todayUsage > 0 ? Colors.green.value : null,
          ),
          WidgetStatItem(id: 'warehouses', label: '仓库数', value: '$warehouseCount'),
        ],
      );
    });
  }
}
