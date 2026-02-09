/// 物品管理插件主页小组件数据提供者
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';

const Color _goodsColor = Color.fromARGB(255, 207, 77, 116);

/// 获取可用的统计项
List<StatItemData> getAvailableStats(BuildContext context) {
  try {
    final plugin = PluginManager.instance.getPlugin('goods') as GoodsPlugin?;
    if (plugin == null) return [];

    final totalItems = plugin.getTotalItemsCount();
    final totalValue = plugin.getTotalItemsValue();
    final unusedItems = plugin.getUnusedItemsCount();

    return [
      StatItemData(
        id: 'total_quantity',
        label: 'goods_totalGoods'.tr,
        value: '$totalItems',
        highlight: false,
      ),
      StatItemData(
        id: 'total_value',
        label: '物品总价值',
        value: '¥${totalValue.toStringAsFixed(0)}',
        highlight: false,
      ),
      StatItemData(
        id: 'one_month_unused',
        label: '一个月未使用',
        value: '$unusedItems',
        highlight: unusedItems > 0,
        color: Colors.red,
      ),
    ];
  } catch (e) {
    return [];
  }
}

/// 构建概览小组件
Widget buildOverviewWidget(
  BuildContext context,
  Map<String, dynamic> config,
) {
  try {
    // 解析插件配置
    PluginWidgetConfig widgetConfig;
    try {
      if (config.containsKey('pluginWidgetConfig')) {
        widgetConfig = PluginWidgetConfig.fromJson(
          config['pluginWidgetConfig'] as Map<String, dynamic>,
        );
      } else {
        widgetConfig = PluginWidgetConfig();
      }
    } catch (e) {
      widgetConfig = PluginWidgetConfig();
    }

    // 获取可用的统计项数据
    final availableItems = getAvailableStats(context);

    // 使用通用小组件
    return GenericPluginWidget(
      pluginId: 'goods',
      pluginName: 'goods_name'.tr,
      pluginIcon: Icons.dashboard,
      pluginDefaultColor: _goodsColor,
      availableItems: availableItems,
      config: widgetConfig,
    );
  } catch (e) {
    return HomeWidget.buildErrorWidget(context, e.toString());
  }
}
