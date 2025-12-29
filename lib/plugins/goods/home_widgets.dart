import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'goods_plugin.dart';
import 'models/goods_item.dart';

const Color _goodsColor = Color.fromARGB(255, 207, 77, 116);

/// 物品管理插件的主页小组件注册
class GoodsHomeWidgets {
  /// 注册所有物品管理插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(
      HomeWidget(
        id: 'goods_icon',
        pluginId: 'goods',
        name: 'goods_widgetName'.tr,
        description: 'goods_widgetDescription'.tr,
        icon: Icons.inventory_2,
        color: _goodsColor,
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
        category: 'home_categoryRecord'.tr,
        builder:
            (context, config) => GenericIconWidget(
              icon: Icons.inventory_2,
              color: _goodsColor,
              name: 'goods_widgetName'.tr,
            ),
      ),
    );

    // 2x2 详细卡片 - 显示统计信息
    registry.register(
      HomeWidget(
        id: 'goods_overview',
        pluginId: 'goods',
        name: 'goods_overviewName'.tr,
        description: 'goods_overviewDescription'.tr,
        icon: Icons.dashboard,
        color: _goodsColor,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large],
        category: 'home_categoryRecord'.tr,
        builder: (context, config) => _buildOverviewWidget(context, config),
        availableStatsProvider: _getAvailableStats,
      ),
    );

    // 仓库选择器小组件
    registry.register(
      HomeWidget(
        id: 'goods_warehouse_selector',
        pluginId: 'goods',
        name: 'goods_warehouseSelector'.tr,
        description: 'goods_warehouseSelectorDesc'.tr,
        icon: Icons.warehouse,
        color: _goodsColor,
        defaultSize: HomeWidgetSize.medium,
        supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
        category: 'home_categoryRecord'.tr,
        selectorId: 'goods.warehouse',
        dataRenderer: _renderWarehouseData,
        navigationHandler: _navigateToWarehouse,
        builder:
            (context, config) => GenericSelectorWidget(
              widgetDefinition: registry.getWidget('goods_warehouse_selector')!,
              config: config,
            ),
      ),
    );

    // 物品选择器小组件
    registry.register(
      HomeWidget(
        id: 'goods_item_selector',
        pluginId: 'goods',
        name: 'goods_itemSelector'.tr,
        description: 'goods_itemSelectorDesc'.tr,
        icon: Icons.inventory_2,
        color: _goodsColor,
        defaultSize: HomeWidgetSize.medium,
        supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
        category: 'home_categoryRecord'.tr,
        selectorId: 'goods.item',
        dataRenderer: _renderItemData,
        navigationHandler: _navigateToItem,
        builder:
            (context, config) => GenericSelectorWidget(
              widgetDefinition: registry.getWidget('goods_item_selector')!,
              config: config,
            ),
      ),
    );
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
  static Widget _buildOverviewWidget(
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

  /// 渲染选中的仓库数据
  static Widget _renderWarehouseData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    final theme = Theme.of(context);

    // 从 result.data 获取仓库 ID
    final data = result.data as Map<String, dynamic>?;
    if (data == null) {
      return _buildErrorWidget(context, '请选择仓库');
    }

    final warehouseId = data['id'] as String?;

    // 从 GoodsPlugin 获取最新数据
    final plugin = GoodsPlugin.instance;
    final warehouse =
        warehouseId != null ? plugin.getWarehouse(warehouseId) : null;

    if (warehouse == null) {
      return _buildErrorWidget(context, '仓库不存在');
    }

    final title = warehouse.title;
    final itemCount = warehouse.items.length;
    final icon = warehouse.icon;
    final color = warehouse.iconColor;

    return FutureBuilder<String?>(
      future: warehouse.getImageUrl(),
      builder: (context, snapshot) {
        final hasImage =
            snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.isNotEmpty;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _navigateToWarehouse(context, result),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image:
                    hasImage
                        ? DecorationImage(
                          image: ImageUtils.createImageProvider(snapshot.data),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: hasImage ? Colors.black.withOpacity(0.3) : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 顶部图标和标题
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: (hasImage ? Colors.white : color).withAlpha(
                              hasImage ? 200 : 50,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            size: 28,
                            color: hasImage ? color : color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: hasImage ? Colors.white : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '$itemCount 件物品',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      (hasImage
                                          ? Colors.white70
                                          : theme.colorScheme.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 导航到仓库详情页面
  static void _navigateToWarehouse(
    BuildContext context,
    SelectorResult result,
  ) {
    final data = result.data as Map<String, dynamic>?;
    final warehouseId = data?['id'] as String?;
    final warehouseName = data?['title'] as String?;

    if (warehouseId == null || warehouseId.isEmpty) {
      debugPrint('仓库ID为空');
      return;
    }

    // 尝试获取最新数据
    final plugin = GoodsPlugin.instance;
    final warehouse = plugin.getWarehouse(warehouseId);
    final name = warehouse?.title ?? warehouseName ?? '未知仓库';

    NavigationHelper.pushNamed(
      context,
      '/goods/warehouse_detail',
      arguments: {'warehouseId': warehouseId, 'warehouseName': name},
    );
  }

  /// 渲染选中的物品数据
  static Widget _renderItemData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    final theme = Theme.of(context);

    // 从 result.data 获取物品 ID
    final data = result.data as Map<String, dynamic>?;
    if (data == null) {
      return _buildErrorWidget(context, '请选择物品');
    }

    final itemId = data['id'] as String?;

    // 从 GoodsPlugin 获取最新数据
    final plugin = GoodsPlugin.instance;
    final findResult = itemId != null ? plugin.findGoodsItemById(itemId) : null;
    final item = findResult?.item;

    if (item == null) {
      return _buildErrorWidget(context, '物品不存在');
    }

    final title = item.title;
    final price = item.purchasePrice;

    return FutureBuilder<String?>(
      future: item.getImageUrl(),
      builder: (context, snapshot) {
        final hasImage =
            snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.isNotEmpty;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _navigateToItem(context, result),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image:
                    hasImage
                        ? DecorationImage(
                          image: ImageUtils.createImageProvider(snapshot.data),
                          fit: BoxFit.cover,
                        )
                        : null,
                gradient:
                    hasImage
                        ? null
                        : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _goodsColor.withAlpha(30),
                            _goodsColor.withAlpha(10),
                          ],
                        ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: hasImage ? Colors.black.withOpacity(0.3) : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 图片和基本信息
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 物品图片或图标
                        _buildItemImageWidget(item, hasImage: hasImage),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: hasImage ? Colors.white : null,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (price != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '¥${price.toStringAsFixed(2)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color:
                                        hasImage
                                            ? Colors.white
                                            : theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建物品图片组件（支持图片背景）
  static Widget _buildItemImageWidget(GoodsItem item, {bool hasImage = false}) {
    final effectiveColor = item.iconColor ?? _goodsColor;
    final icon = item.icon ?? Icons.inventory_2;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: (hasImage ? Colors.white : effectiveColor).withAlpha(
          hasImage ? 200 : 50,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 32, color: effectiveColor),
    );
  }

  /// 导航到物品详情页面
  static void _navigateToItem(BuildContext context, SelectorResult result) {
    final data = result.data as Map<String, dynamic>?;
    final itemId = data?['id'] as String?;

    if (itemId == null || itemId.isEmpty) {
      debugPrint('物品ID为空');
      return;
    }

    // 尝试从 GoodsPlugin 获取最新数据以获取仓库ID
    final plugin = GoodsPlugin.instance;
    final findResult = plugin.findGoodsItemById(itemId);

    if (findResult == null) {
      debugPrint('未找到物品: $itemId');
      return;
    }

    NavigationHelper.pushNamed(
      context,
      '/goods/item_detail',
      arguments: {
        'itemId': itemId,
        'warehouseId': findResult.warehouseId,
        'itemTitle': findResult.item.title,
      },
    );
  }
}
