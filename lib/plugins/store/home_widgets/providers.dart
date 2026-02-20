/// 积分商店插件主页小组件数据提供者
library;

import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import '../store_plugin.dart';

/// 获取可用的统计项
List<StatItemData> getAvailableStats(BuildContext context) {
  try {
    final plugin = PluginManager.instance.getPlugin('store') as StorePlugin?;
    if (plugin == null) return [];

    final controller = plugin.controller;
    final goodsCount = controller.getGoodsCount();
    final itemsCount = controller.getItemsCount();
    final currentPoints = controller.currentPoints;
    final expiringCount = controller.getExpiringItemsCount();

    return [
      StatItemData(
        id: 'goods_count',
        label: '商品数量',
        value: '$goodsCount',
        highlight: false,
      ),
      StatItemData(
        id: 'items_count',
        label: '物品数量',
        value: '$itemsCount',
        highlight: false,
      ),
      StatItemData(
        id: 'current_points',
        label: '我的积分',
        value: '$currentPoints',
        highlight: currentPoints > 0,
        color: Colors.orange,
      ),
      StatItemData(
        id: 'expiring_count',
        label: '七天到期',
        value: '$expiringCount',
        highlight: expiringCount > 0,
        color: Colors.red,
      ),
    ];
  } catch (e) {
    return [];
  }
}
