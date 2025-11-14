import 'package:flutter/material.dart';
import '../../screens/home_screen/models/home_widget_size.dart';
import '../../screens/home_screen/widgets/home_widget.dart';
import '../../screens/home_screen/widgets/generic_plugin_widget.dart';
import '../../screens/home_screen/models/plugin_widget_config.dart';
import '../../screens/home_screen/managers/home_widget_registry.dart';
import '../../core/plugin_manager.dart';
import 'store_plugin.dart';
import 'l10n/store_localizations.dart';

/// 积分商店插件的主页小组件注册
class StoreHomeWidgets {
  /// 注册所有积分商店插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'store_icon',
      pluginId: 'store',
      name: '积分商店',
      description: '快速打开积分商店',
      icon: Icons.store,
      color: Colors.pinkAccent,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: '工具',
      builder: (context, config) => const GenericIconWidget(
        icon: Icons.store,
        color: Colors.pinkAccent,
      ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'store_overview',
      pluginId: 'store',
      name: '积分商店概览',
      description: '显示商品、物品、积分和即将到期统计',
      icon: Icons.shopping_bag_outlined,
      color: Colors.pinkAccent,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: '工具',
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ));
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats() {
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

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(BuildContext context, Map<String, dynamic> config) {
    try {
      final l10n = StoreLocalizations.of(context);

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
      final availableItems = _getAvailableStats();

      // 使用通用小组件
      return GenericPluginWidget(
        pluginName: l10n.name,
        pluginIcon: Icons.store,
        pluginDefaultColor: Colors.pinkAccent,
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
