import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'store_plugin.dart';

/// 积分商店插件的主页小组件注册
class StoreHomeWidgets {
  /// 注册所有积分商店插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'store_icon',
      pluginId: 'store',
      name: 'store_widgetName'.tr,
      description: 'store_widgetDescription'.tr,
      icon: Icons.store,
      color: Colors.pinkAccent,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: 'home_categoryTool'.tr,
      builder: (context, config) => GenericIconWidget(
        icon: Icons.store,
        color: Colors.pinkAccent,
        name: 'store_widgetName'.tr,
      ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'store_overview',
      pluginId: 'store',
      name: 'store_overviewName'.tr,
      description: 'store_overviewDescription'.tr,
      icon: Icons.shopping_bag_outlined,
      color: Colors.pinkAccent,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: 'home_categoryTool'.tr,
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ));

    // 商品选择器小组件 - 快速访问特定商品的物品列表
    registry.register(
      HomeWidget(
        id: 'store_product_selector',
        pluginId: 'store',
        name: 'store_productQuickAccess'.tr,
        description: 'store_productQuickAccessDesc'.tr,
        icon: Icons.shopping_bag,
        color: Colors.pinkAccent,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
        category: 'home_categoryTool'.tr,

        // 选择器配置
        selectorId: 'store.product',
        dataRenderer: _renderProductData,
        navigationHandler: _navigateToProductItems,

        builder: (context, config) {
          return GenericSelectorWidget(
            widgetDefinition: registry.getWidget('store_product_selector')!,
            config: config,
          );
        },
      ),
    );

    // 用户物品选择器小组件 - 快速访问指定物品信息
    registry.register(
      HomeWidget(
        id: 'store_user_item_selector',
        pluginId: 'store',
        name: 'store_userItemQuickAccess'.tr,
        description: 'store_userItemQuickAccessDesc'.tr,
        icon: Icons.inventory_2,
        color: Colors.pinkAccent,
        defaultSize: HomeWidgetSize.medium,
        supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
        category: 'home_categoryTool'.tr,

        // 选择器配置
        selectorId: 'store.userItem',
        dataRenderer: _renderUserItemData,
        navigationHandler: _navigateToUserItemDetail,

        builder: (context, config) {
          return GenericSelectorWidget(
            widgetDefinition: registry.getWidget('store_user_item_selector')!,
            config: config,
          );
        },
      ),
    );
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
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
        pluginId: 'store',
        pluginName: 'store_name'.tr,
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
            'home_loadFailed'.tr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // ===== 选择器小组件相关方法 =====

  /// 渲染商品数据
  static Widget _renderProductData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    final theme = Theme.of(context);

    // 从 result.data 获取商品数据
    if (result.data == null) {
      return _buildErrorWidget(context, '数据不存在');
    }

    final productData = result.data as Map<String, dynamic>;
    final name = productData['name'] as String? ?? '未知商品';
    final description = productData['description'] as String? ?? '';
    final price = productData['price'] as int? ?? 0;
    final stock = productData['stock'] as int? ?? 0;

    // 获取该商品的已兑换物品数量
    int itemCount = 0;
    try {
      final plugin = PluginManager.instance.getPlugin('store') as StorePlugin?;
      if (plugin != null) {
        final productId = productData['id'] as String?;
        if (productId != null) {
          itemCount = plugin.controller.userItems
              .where((item) => item.productId == productId)
              .length;
        }
      }
    } catch (e) {
      // 忽略错误
    }

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部标签行
            Row(
              children: [
                Icon(
                  Icons.shopping_bag,
                  size: 20,
                  color: Colors.pinkAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'store_productQuickAccess'.tr,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 库存状态标签
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: stock > 0
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    stock > 0 ? '${'store_stockLabel'.tr}: $stock' : 'store_outOfStock'.tr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: stock > 0 ? Colors.green : Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            // 商品名称
            Text(
              name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // 商品描述
            if (description.isNotEmpty) ...[
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
            ],
            // 底部信息栏
            Row(
              children: [
                // 价格
                Icon(
                  Icons.monetization_on,
                  size: 16,
                  color: Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  '$price ${'store_points'.tr}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // 已兑换物品数量
                Icon(
                  Icons.inventory_2,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${'store_itemQuantity'.tr}: $itemCount',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 导航到商品物品列表
  static void _navigateToProductItems(
    BuildContext context,
    SelectorResult result,
  ) {
    final productData = result.data as Map<String, dynamic>;
    final productId = productData['id'] as String;
    final productName = productData['name'] as String? ?? '未知商品';

    // 跳转到商品物品列表页面
    NavigationHelper.pushNamed(
      context,
      '/store/product_items',
      arguments: {
        'productId': productId,
        'productName': productName,
      },
    );
  }

  // ===== 用户物品选择器小组件相关方法 =====

  /// 渲染用户物品数据
  static Widget _renderUserItemData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    final theme = Theme.of(context);

    if (result.data == null) {
      return _buildErrorWidget(context, '数据不存在');
    }

    final itemData = result.data as Map<String, dynamic>;
    final productSnapshot = itemData['productSnapshot'] as Map<String, dynamic>? ?? {};
    final productName = productSnapshot['name'] as String? ?? '未知物品';
    final purchasePrice = itemData['purchasePrice'] as int? ?? 0;
    final remaining = itemData['remaining'] as int? ?? 0;
    final expireDateStr = itemData['expireDate'] as String?;

    // 解析过期日期
    DateTime? expireDate;
    if (expireDateStr != null) {
      try {
        expireDate = DateTime.parse(expireDateStr);
      } catch (e) {
        expireDate = null;
      }
    }

    // 计算剩余天数
    int? remainingDays;
    if (expireDate != null) {
      remainingDays = expireDate.difference(DateTime.now()).inDays;
    }

    // 检查是否已过期
    final isExpired = remainingDays != null && remainingDays < 0;
    final isExpiringSoon = remainingDays != null && remainingDays >= 0 && remainingDays <= 7;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.inventory_2,
                  size: 20,
                  color: Colors.pinkAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'store_myItems'.tr,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isExpired
                        ? Colors.red.withOpacity(0.2)
                        : (isExpiringSoon ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isExpired
                        ? '已过期'
                        : (isExpiringSoon ? '即将过期' : '有效'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isExpired ? Colors.red : (isExpiringSoon ? Colors.orange : Colors.green),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              productName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // 剩余次数和过期信息
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$remaining ${'store_times'.tr}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.pinkAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (remainingDays != null)
                  Text(
                    isExpired
                        ? 'store_itemExpired'.tr
                        : '${'store_expireIn'.tr} $remainingDays ${'store_days'.tr}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isExpired ? Colors.red : (isExpiringSoon ? Colors.orange : Colors.green),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // 价格信息
            Row(
              children: [
                Icon(
                  Icons.monetization_on,
                  size: 16,
                  color: Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  '$purchasePrice ${'store_points'.tr}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 导航到用户物品详情
  static void _navigateToUserItemDetail(
    BuildContext context,
    SelectorResult result,
  ) {
    final itemData = result.data as Map<String, dynamic>;
    final itemId = itemData['id'] as String?;
    final productSnapshot = itemData['productSnapshot'] as Map<String, dynamic>? ?? {};
    final productName = productSnapshot['name'] as String? ?? '未知物品';

    if (itemId != null) {
      NavigationHelper.pushNamed(
        context,
        '/store',
        arguments: {
          'itemId': itemId,
          'productName': productName,
        },
      );
    }
  }
}
