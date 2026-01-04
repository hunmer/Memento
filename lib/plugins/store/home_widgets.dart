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
import 'package:Memento/widgets/event_listener_container.dart';
import 'store_plugin.dart';

/// 积分商店插件的主页小组件注册
class StoreHomeWidgets {
  /// 注册所有积分商店插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 积分目标进度小组件 - 1x2 显示进度条
    registry.register(
      HomeWidget(
        id: 'store_points_goal_progress',
        pluginId: 'store',
        name: '积分目标进度',
        description: '显示今日积分与目标的进度',
        icon: Icons.flag,
        color: Colors.orange,
        defaultSize: HomeWidgetSize.medium, // 2x1
        supportedSizes: [
          HomeWidgetSize.medium, // 2x1
          HomeWidgetSize.large, // 2x2
        ],
        category: 'home_categoryTools'.tr,
        selectorId: 'store.pointsGoalForm',
        dataRenderer: _renderPointsGoalProgress,
        navigationHandler: _navigateToPointsHistory,
        dataSelector: (data) {
          // GenericSelectorWidget 已经将 List 转换为 Map
          if (data is Map<String, dynamic>) {
            final dataMap = data as Map<String, dynamic>;
            return {'goal': dataMap['goal'] as int};
          }
          return {};
        },
        builder: (context, config) {
          return GenericSelectorWidget(
            widgetDefinition: registry.getWidget('store_points_goal_progress')!,
            config: config,
          );
        },
      ),
    );

    // 1x1 简单图标组件 - 快速访问

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
        dataSelector: (dataArray) {
          final itemData = dataArray[0] as Map<String, dynamic>;
          return {
            'id': itemData['id'] as String,
            'purchase_price': itemData['purchase_price'] as int?,
            'remaining': itemData['remaining'] as int?,
            'expire_date': itemData['expire_date'] as String?,
            'product_snapshot':
                itemData['product_snapshot'] as Map<String, dynamic>?,
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

  /// 渲染商品数据
  static Widget _renderProductData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    // 从 result.data 获取保存的商品 ID
    final savedData = result.data as Map<String, dynamic>?;
    if (savedData == null) {
      return _buildErrorWidget(context, '数据不存在');
    }

    final productId = savedData['id'] as String? ?? '';
    if (productId.isEmpty) {
      return _buildErrorWidget(context, '商品ID不存在');
    }

    // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
    return StatefulBuilder(
      builder: (context, setState) {
        return EventListenerContainer(
          events: const [
            'store_product_added',
            'store_product_archived',
            'store_product_restored',
            'store_points_changed',
          ],
          onEvent: () => setState(() {}),
          child: _buildProductWidget(context, productId),
        );
      },
    );
  }

  /// 构建商品小组件内容（获取最新数据）
  static Widget _buildProductWidget(BuildContext context, String productId) {
    final theme = Theme.of(context);

    // 从 PluginManager 获取最新的商品数据
    final plugin = PluginManager.instance.getPlugin('store') as StorePlugin?;
    if (plugin == null) {
      return _buildErrorWidget(context, 'store_pluginNotAvailable'.tr);
    }

    // 查找对应商品
    final product = plugin.controller.products.firstWhereOrNull(
      (p) => p.id == productId,
    );

    // 如果商品不存在，尝试从存档中查找
    final finalProduct =
        product ??
        plugin.controller.archivedProducts.firstWhereOrNull(
          (p) => p.id == productId,
        );

    if (finalProduct == null) {
      return _buildErrorWidget(context, 'store_productNotFound'.tr);
    }

    final name = finalProduct.name;
    final description = finalProduct.description;
    final price = finalProduct.price;
    final stock = finalProduct.stock;
    final imagePath = finalProduct.image;

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
            onTap: () {
              // 导航到商品物品列表
              NavigationHelper.pushNamed(
                context,
                '/store/product_items',
                arguments: {
                  'productId': productId,
                  'productName': name,
                  'autoBuy': true,
                },
              );
            },
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
                  // 半透明遮罩（确保文字可读性）
                  if (hasImage)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.black.withOpacity(0.2),
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
                            color:
                                hasImage
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
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
                                      : theme.colorScheme.onSurfaceVariant),
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
                              color: hasImage ? Colors.orange : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$price ${'store_points'.tr}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: hasImage ? Colors.orange : Colors.orange,
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

  // ===== 用户物品选择器小组件相关方法 =====

  /// 渲染用户物品数据
  static Widget _renderUserItemData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    // 从 result.data 获取保存的物品 ID
    final savedData = result.data as Map<String, dynamic>?;
    if (savedData == null) {
      return _buildErrorWidget(context, '数据不存在');
    }

    final itemId = savedData['id'] as String? ?? '';
    if (itemId.isEmpty) {
      return _buildErrorWidget(context, '物品ID不存在');
    }

    // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
    return StatefulBuilder(
      builder: (context, setState) {
        return EventListenerContainer(
          events: const [
            'store_user_item_added',
            'store_user_item_used',
            'store_user_item_deleted',
            'store_points_changed',
          ],
          onEvent: () => setState(() {}),
          child: _buildUserItemWidget(context, itemId),
        );
      },
    );
  }

  /// 构建用户物品小组件内容（获取最新数据）
  static Widget _buildUserItemWidget(BuildContext context, String itemId) {
    final theme = Theme.of(context);

    // 从 PluginManager 获取最新的用户物品数据
    final plugin = PluginManager.instance.getPlugin('store') as StorePlugin?;
    if (plugin == null) {
      return _buildErrorWidget(context, 'store_pluginNotAvailable'.tr);
    }

    // 查找对应的用户物品
    final item = plugin.controller.userItems.firstWhereOrNull(
      (item) => item.id == itemId,
    );

    if (item == null) {
      return _buildErrorWidget(context, 'store_itemNotFound'.tr);
    }

    final productName = item.productName;
    final productImage = item.productImage;
    final purchasePrice = item.purchasePrice;
    final remaining = item.remaining;
    final expireDate = item.expireDate;

    // 计算剩余天数
    final remainingDays = expireDate.difference(DateTime.now()).inDays;

    // 检查是否已过期
    final isExpired = remainingDays < 0;
    final isExpiringSoon = remainingDays >= 0 && remainingDays <= 7;

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
            onTap: () {
              // 导航到用户物品详情
              NavigationHelper.pushNamed(
                context,
                '/store/user_item',
                arguments: {'itemId': itemId, 'autoUse': true},
              );
            },
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
                                        : Colors.pinkAccent.withOpacity(0.2)),
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
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // 过期信息（右下角）
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
  }

  // ===== 积分目标进度小组件相关方法 =====

  /// 渲染积分目标进度
  static Widget _renderPointsGoalProgress(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    // GenericSelectorWidget 会将 List 转换为合并的 Map
    // 所以 result.data 是 Map<String, dynamic> 类型
    final data = result.data;

    if (data is! Map<String, dynamic>) {
      return _buildErrorWidget(context, '数据格式错误');
    }

    final dataMap = data;
    final goal = dataMap['goal'] as int?;

    if (goal == null || goal <= 0) {
      return _buildErrorWidget(context, '目标值无效');
    }

    // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
    return StatefulBuilder(
      builder: (context, setState) {
        return EventListenerContainer(
          events: const ['store_points_changed'],
          onEvent: () => setState(() {}),
          child: _buildPointsGoalProgressWidget(context, goal),
        );
      },
    );
  }

  /// 构建积分目标进度小组件内容
  static Widget _buildPointsGoalProgressWidget(BuildContext context, int goal) {
    final theme = Theme.of(context);

    // 从 PluginManager 获取最新的积分数据
    final plugin = PluginManager.instance.getPlugin('store') as StorePlugin?;
    if (plugin == null) {
      return _buildErrorWidget(context, 'store_pluginNotAvailable'.tr);
    }

    final todayPoints = plugin.controller.getTodayPoints();
    final progress = goal > 0 ? (todayPoints / goal).clamp(0.0, 1.0) : 0.0;
    final isCompleted = todayPoints >= goal;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // 导航到积分历史
          NavigationHelper.pushNamed(context, '/store/points_history');
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  isCompleted
                      ? [Colors.orange.shade400, Colors.orange.shade600]
                      : [Colors.orange.shade100, Colors.orange.shade200],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  Icon(
                    isCompleted ? Icons.emoji_events : Icons.flag,
                    color: isCompleted ? Colors.white : Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '今日积分目标',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color:
                          isCompleted ? Colors.white : Colors.orange.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (isCompleted)
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                ],
              ),
              const SizedBox(height: 8),

              // 高进度条+文字内嵌显示
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 高进度条（文字内嵌）
                  Stack(
                    children: [
                      // 背景条
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      // 进度填充
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color:
                                  isCompleted
                                      ? Colors.white.withOpacity(0.9)
                                      : Colors.orange.shade700,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      // 文字内嵌在进度条中
                      SizedBox(
                        height: 48,
                        child: Center(
                          child: Text(
                            '$todayPoints / $goal',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color:
                                  isCompleted
                                      ? Colors.orange.shade700
                                      : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 导航到积分历史
  static void _navigateToPointsHistory(
    BuildContext context,
    SelectorResult result,
  ) {
    NavigationHelper.pushNamed(context, '/store/points_history');
  }
}
