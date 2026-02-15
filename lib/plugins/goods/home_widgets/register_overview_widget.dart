/// 物品管理插件 - 概览组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';

const Color _goodsColor = Color.fromARGB(255, 207, 77, 116);

/// 注册概览组件 (2x2)
void registerOverviewWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'goods_overview',
      pluginId: 'goods',
      name: 'goods_overviewName'.tr,
      description: 'goods_overviewDescription'.tr,
      icon: Icons.dashboard,
      color: _goodsColor,
      defaultSize: const LargeSize(),
      supportedSizes: [const LargeSize()],
      category: 'home_categoryRecord'.tr,
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ),
  );
}

/// 获取可用的统计项
List<StatItemData> _getAvailableStats(BuildContext context) {
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
Widget _buildOverviewWidget(
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
    final availableItems = _getAvailableStats(context);

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
