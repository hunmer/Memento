import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'goods_plugin.dart';

const Color _goodsColor = Color.fromARGB(255, 207, 77, 116);

/// 物品管理插件的主页小组件注册
class GoodsHomeWidgets {
  /// 注册所有物品管理插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'goods_icon',
      pluginId: 'goods',
      name: '物品',
      description: '快速打开物品管理',
      icon: Icons.inventory_2,
      color: _goodsColor,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: '记录',
      builder: (context, config) => const GenericIconWidget(
        icon: Icons.inventory_2,
        color: _goodsColor,
        name: '物品',
      ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'goods_overview',
      pluginId: 'goods',
      name: '物品概览',
      description: '显示物品数量、价值和使用情况',
      icon: Icons.dashboard,
      color: _goodsColor,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: '记录',
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ));
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
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

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(BuildContext context, Map<String, dynamic> config) {
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
        pluginName: 'goods_name'.tr,
        pluginIcon: Icons.dashboard,
        pluginDefaultColor: _goodsColor,
        availableItems: availableItems,
        config: widgetConfig,
      );
    } catch (e) {
      return _buildErrorWidget(context, e.toString());
    }
  }

  /// 构建错误提示组件
  static Widget _buildErrorWidget(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 32, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            '加载失败',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
