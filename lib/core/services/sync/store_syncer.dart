import 'package:flutter/material.dart';
import 'package:Memento/plugins/store/store_plugin.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'plugin_widget_syncer.dart';
import 'package:memento_widgets/memento_widgets.dart';

/// 商店插件同步器
class StoreSyncer extends PluginWidgetSyncer {
  @override
  Future<void> sync() async {
    await syncSafely('store', () async {
      final plugin = PluginManager.instance.getPlugin('store') as StorePlugin?;
      if (plugin == null) return;

      final totalProducts = plugin.controller.getGoodsCount();
      final todayRedeemCount = plugin.controller.getTodayRedeemCount();
      final currentPoints = plugin.controller.currentPoints;

      await updateWidget(
        pluginId: 'store',
        pluginName: '商店',
        iconCodePoint: Icons.store.codePoint,
        colorValue: Colors.red.value,
        stats: [
          WidgetStatItem(id: 'products', label: '总商品数', value: '$totalProducts'),
          WidgetStatItem(
            id: 'today_redeem',
            label: '今日兑换',
            value: '$todayRedeemCount',
            highlight: todayRedeemCount > 0,
            colorValue: todayRedeemCount > 0 ? Colors.purple.value : null,
          ),
          WidgetStatItem(
            id: 'points',
            label: '可用积分',
            value: '$currentPoints',
            highlight: currentPoints > 0,
            colorValue: currentPoints > 0 ? Colors.orange.value : null,
          ),
        ],
      );
    });
  }
}
