/// 积分商店插件 - 商品选择器注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'widgets/product_selector_widget.dart';
import '../store_plugin.dart';

/// 注册商品选择器小组件
void registerProductSelectorWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'store_product_selector',
      pluginId: 'store',
      name: 'store_productQuickAccess'.tr,
      description: 'store_productQuickAccessDesc'.tr,
      icon: Icons.shopping_bag,
      color: Colors.pinkAccent,
      defaultSize: const LargeSize(),
      supportedSizes: [const MediumSize(), const LargeSize()],
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
        final dataMap = config['selectedData'] as Map<String, dynamic>? ?? {};
        return ProductSelectorWidget(config: dataMap);
      },
    ),
  );
}

/// 渲染商品数据
Widget _renderProductData(
  BuildContext context,
  SelectorResult result,
  Map<String, dynamic> config,
) {
  // 从 result.data 获取保存的商品 ID
  final savedData = result.data as Map<String, dynamic>?;
  if (savedData == null) {
    return HomeWidget.buildErrorWidget(context, '数据不存在');
  }

  final productId = savedData['id'] as String? ?? '';
  if (productId.isEmpty) {
    return HomeWidget.buildErrorWidget(context, '商品ID不存在');
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
Widget _buildProductWidget(BuildContext context, String productId) {
  final theme = Theme.of(context);

  // 从 PluginManager 获取最新的商品数据
  final plugin = PluginManager.instance.getPlugin('store') as StorePlugin?;
  if (plugin == null) {
    return HomeWidget.buildErrorWidget(
      context,
      'store_pluginNotAvailable'.tr,
    );
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
    return HomeWidget.buildErrorWidget(context, 'store_productNotFound'.tr);
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
Future<String?> _getProductImagePath(String? imagePath) async {
  if (imagePath == null || imagePath.isEmpty) return null;

  // 如果是绝对路径，直接返回
  if (imagePath.startsWith('/') || imagePath.startsWith('http')) {
    return imagePath;
  }

  // 如果是相对路径，使用 ImageUtils 转换
  return ImageUtils.getAbsolutePath(imagePath);
}
