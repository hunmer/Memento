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
import 'store_plugin.dart';

/// 积分商店插件的主页小组件注册
class StoreHomeWidgets {
  /// 注册所有积分商店插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(
      HomeWidget(
        id: 'store_icon',
        pluginId: 'store',
        name: 'store_widgetName'.tr,
        description: 'store_widgetDescription'.tr,
        icon: Icons.store,
        color: Colors.pinkAccent,
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
        category: 'home_categoryTools'.tr,
        builder:
            (context, config) => GenericIconWidget(
              icon: Icons.store,
              color: Colors.pinkAccent,
              name: 'store_widgetName'.tr,
            ),
      ),
    );

    // 2x2 详细卡片 - 显示统计信息
    registry.register(
      HomeWidget(
        id: 'store_overview',
        pluginId: 'store',
        name: 'store_overviewName'.tr,
        description: 'store_overviewDescription'.tr,
        icon: Icons.shopping_bag_outlined,
        color: Colors.pinkAccent,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large],
        category: 'home_categoryTools'.tr,
        builder: (context, config) => _buildOverviewWidget(context, config),
        availableStatsProvider: _getAvailableStats,
      ),
    );

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
        category: 'home_categoryTools'.tr,

        // 选择器配置
        selectorId: 'store.product',
        dataRenderer: _renderProductData,
        navigationHandler: _navigateToProductItems,
        dataSelector: (dataArray) {
          final productData = dataArray[0] as Map<String, dynamic>;
          return {
            'id': productData['id'] as String,
            'name': productData['name'] as String?,
            'image': productData['image'] as String?,
          };
        },

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
        category: 'home_categoryTools'.tr,

        // 选择器配置
        selectorId: 'store.userItem',
        dataRenderer: _renderUserItemData,
        navigationHandler: _navigateToUserItemDetail,
        dataSelector: (dataArray) {
          final itemData = dataArray[0] as Map<String, dynamic>;
          return {
            'id': itemData['id'] as String,
            'purchase_price': itemData['purchase_price'] as int?,
            'remaining': itemData['remaining'] as int?,
            'expire_date': itemData['expire_date'] as String?,
            'product_snapshot': itemData['product_snapshot'] as Map<String, dynamic>?,
          };
        },

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

  /// 加载最新的商品数据
  static Future<Map<String, dynamic>?> _loadLatestProductData(
    String productId,
  ) async {
    try {
      final plugin = PluginManager.instance.getPlugin('store') as StorePlugin?;
      if (plugin == null) return null;
      final product = plugin.controller.products.firstWhereOrNull(
        (p) => p.id == productId,
      );
      return product?.toJson();
    } catch (e) {
      debugPrint('加载商品数据失败: $e');
      return null;
    }
  }

  /// 加载最新的用户物品数据
  static Future<Map<String, dynamic>?> _loadLatestUserItemData(
    String itemId,
  ) async {
    try {
      final plugin = PluginManager.instance.getPlugin('store') as StorePlugin?;
      if (plugin == null) return null;
      final item = plugin.controller.userItems.firstWhereOrNull(
        (item) => item.id == itemId,
      );
      return item?.toJson();
    } catch (e) {
      debugPrint('加载用户物品数据失败: $e');
      return null;
    }
  }

  /// 渲染商品数据
  static Widget _renderProductData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    final theme = Theme.of(context);

    // 从 result.data 获取保存的商品 ID
    final savedData = result.data as Map<String, dynamic>?;
    if (savedData == null) {
      return _buildErrorWidget(context, '数据不存在');
    }

    final productId = savedData['id'] as String? ?? '';
    if (productId.isEmpty) {
      return _buildErrorWidget(context, '商品ID不存在');
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadLatestProductData(productId),
      builder: (context, snapshot) {
        // 使用最新数据，如果没有则使用保存的数据
        final productData = snapshot.data ?? savedData;
        final name =
            productData['name'] as String? ??
            savedData['name'] as String? ??
            '未知商品';
        final description =
            productData['description'] as String? ??
            savedData['description'] as String? ??
            '';
        final price =
            productData['price'] as int? ?? savedData['price'] as int? ?? 0;
        final stock =
            productData['stock'] as int? ?? savedData['stock'] as int? ?? 0;
        final imagePath =
            productData['image'] as String? ?? savedData['image'] as String?;

        return FutureBuilder<String?>(
          future: _getProductImagePath(imagePath),
          builder: (context, imageSnapshot) {
            final hasImage =
                imageSnapshot.hasData &&
                imageSnapshot.data != null &&
                imageSnapshot.data!.isNotEmpty;

            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _navigateToProductItems(context, result),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image:
                        hasImage
                            ? DecorationImage(
                              image: ImageUtils.createImageProvider(
                                imageSnapshot.data,
                              ),
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
                                Colors.pinkAccent.withAlpha(30),
                                Colors.pinkAccent.withAlpha(10),
                              ],
                            ),
                  ),
                  child: Stack(
                    children: [
                      // 半透明遮罩（确保文字可读性）
                      if (hasImage)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.black.withOpacity(0.4),
                            ),
                          ),
                        ),
                      // 内容区域（带 padding）
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 商品名称
                            Text(
                              name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: hasImage ? Colors.white : null,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // 商品描述
                            if (description.isNotEmpty) ...[
                              Text(
                                description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      (hasImage
                                          ? Colors.white70
                                          : theme.colorScheme.outline),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                            ],
                            const Spacer(),
                            // 底部信息栏 - 价格和库存
                            Row(
                              children: [
                                Icon(
                                  Icons.monetization_on,
                                  size: 16,
                                  color:
                                      hasImage ? Colors.orange : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$price ${'store_points'.tr}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        hasImage
                                            ? Colors.orange
                                            : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                // 库存状态
                                Text(
                                  stock > 0
                                      ? '${'store_stockLabel'.tr}: $stock'
                                      : 'store_outOfStock'.tr,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        hasImage
                                            ? (stock > 0
                                                ? Colors.green
                                                : Colors.grey)
                                            : (stock > 0
                                                ? Colors.green
                                                : Colors.grey),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 获取商品的图片绝对路径
  static Future<String?> _getProductImagePath(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return null;

    // 如果是绝对路径，直接返回
    if (imagePath.startsWith('/') || imagePath.startsWith('http')) {
      return imagePath;
    }

    // 如果是相对路径，使用 ImageUtils 转换
    return ImageUtils.getAbsolutePath(imagePath);
  }

  /// 导航到商品物品列表
  static void _navigateToProductItems(
    BuildContext context,
    SelectorResult result,
  ) {
    final savedData = result.data as Map<String, dynamic>?;
    if (savedData == null) return;

    final productId = savedData['id'] as String? ?? '';
    final productName = savedData['name'] as String? ?? '未知商品';

    if (productId.isNotEmpty) {
      NavigationHelper.pushNamed(
        context,
        '/store/product_items',
        arguments: {
          'productId': productId,
          'productName': productName,
          'autoUse': true, // 跳转到过滤页后自动弹出使用对话框
        },
      );
    }
  }

  // ===== 用户物品选择器小组件相关方法 =====

  /// 渲染用户物品数据
  static Widget _renderUserItemData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    final theme = Theme.of(context);

    // 从 result.data 获取保存的物品 ID
    final savedData = result.data as Map<String, dynamic>?;
    if (savedData == null) {
      return _buildErrorWidget(context, '数据不存在');
    }

    final itemId = savedData['id'] as String? ?? '';
    if (itemId.isEmpty) {
      return _buildErrorWidget(context, '物品ID不存在');
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadLatestUserItemData(itemId),
      builder: (context, snapshot) {
        // 使用最新数据，如果没有则使用保存的数据
        final itemData = snapshot.data ?? savedData;
        final productSnapshot =
            itemData['product_snapshot'] as Map<String, dynamic>? ??
            savedData['product_snapshot'] as Map<String, dynamic>? ??
            {};
        final productName =
            productSnapshot['name'] as String? ??
            savedData['product_snapshot']?['name'] as String? ??
            '未知物品';
        final productImage =
            productSnapshot['image'] as String? ??
            savedData['product_snapshot']?['image'] as String?;
        final purchasePrice =
            itemData['purchasePrice'] as int? ??
            savedData['purchasePrice'] as int? ??
            0;
        final remaining =
            itemData['remaining'] as int? ??
            savedData['remaining'] as int? ??
            0;
        final expireDateStr =
            itemData['expireDate'] as String? ??
            savedData['expireDate'] as String?;

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
        final isExpiringSoon =
            remainingDays != null && remainingDays >= 0 && remainingDays <= 7;

        return FutureBuilder<String?>(
          future: _getProductImagePath(productImage),
          builder: (context, imageSnapshot) {
            final hasImage =
                imageSnapshot.hasData &&
                imageSnapshot.data != null &&
                imageSnapshot.data!.isNotEmpty;

            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image:
                        hasImage
                            ? DecorationImage(
                              image: ImageUtils.createImageProvider(
                                imageSnapshot.data,
                              ),
                              fit: BoxFit.cover,
                            )
                            : null,
                  ),
                  child: Stack(
                    children: [
                      // 半透明遮罩
                      if (hasImage)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.black.withOpacity(0.4),
                            ),
                          ),
                        ),
                      // 内容区域
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 物品名称和剩余次数（在同一行）
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    productName,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: hasImage ? Colors.white : null,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // 剩余次数（标题右侧）
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (hasImage
                                            ? Colors.white.withOpacity(0.2)
                                            : Colors.pinkAccent.withOpacity(
                                              0.2,
                                            )),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$remaining ${'store_times'.tr}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          hasImage
                                              ? Colors.white
                                              : Colors.pinkAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // 底部区域：价格（左）和过期信息（右）
                            Row(
                              children: [
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
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: Colors.orange),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                // 过期信息（右下角）
                                if (remainingDays != null)
                                  Text(
                                    isExpired
                                        ? 'store_itemExpired'.tr
                                        : '${'store_expireIn'.tr} $remainingDays ${'store_days'.tr}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          hasImage
                                              ? (isExpired
                                                  ? Colors.red.shade300
                                                  : (isExpiringSoon
                                                      ? Colors.orange.shade300
                                                      : Colors.green.shade300))
                                              : (isExpired
                                                  ? Colors.red
                                                  : (isExpiringSoon
                                                      ? Colors.orange
                                                      : Colors.green)),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 导航到用户物品详情
  static void _navigateToUserItemDetail(
    BuildContext context,
    SelectorResult result,
  ) {
    final savedData = result.data as Map<String, dynamic>?;
    if (savedData == null) return;

    final itemId = savedData['id'] as String?;
    final productSnapshot =
        savedData['product_snapshot'] as Map<String, dynamic>? ?? {};
    final productName = productSnapshot['name'] as String? ?? '未知物品';

    if (itemId != null) {
      NavigationHelper.pushNamed(
        context,
        '/store',
        arguments: {
          'itemId': itemId,
          'productName': productName,
          'autoUse': true, // 跳转到详情页后自动弹出使用对话框
        },
      );
    }
  }
}
