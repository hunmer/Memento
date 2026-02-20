/// 商品选择器小组件 - 使用事件携带数据模式
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import '../events/store_cache_updated_event_args.dart';

/// 商品选择器小组件
class ProductSelectorWidget extends StatefulWidget {
  final Map<String, dynamic> config;

  const ProductSelectorWidget({required this.config, super.key});

  @override
  State<ProductSelectorWidget> createState() => ProductSelectorWidgetState();
}

class ProductSelectorWidgetState extends State<ProductSelectorWidget> {
  // 缓存的最新数据
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _archivedProducts = [];

  @override
  Widget build(BuildContext context) {
    return EventListenerContainer(
      events: const ['store_cache_updated'],
      onEventWithData: (EventArgs args) {
        if (args is StoreCacheUpdatedEventArgs) {
          setState(() {
            _products = args.products;
            _archivedProducts = args.archivedProducts;
          });
        }
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final productId = widget.config['id'] as String?;
    if (productId == null || productId.isEmpty) {
      return HomeWidget.buildErrorWidget(context, '商品ID不存在');
    }

    // 查找对应商品
    final productData = _products.firstWhere(
      (p) => p['id'] == productId,
      orElse:
          () => _archivedProducts.firstWhere(
            (p) => p['id'] == productId,
            orElse: () => {},
          ),
    );

    if (productData.isEmpty) {
      return HomeWidget.buildErrorWidget(context, '商品未找到');
    }

    final name = productData['name'] as String? ?? '';
    final description = productData['description'] as String? ?? '';
    final price = productData['price'] as int? ?? 0;
    final stock = productData['stock'] as int? ?? 0;
    final imagePath = productData['image'] as String?;

    final theme = Theme.of(context);

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
                  if (hasImage)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.black.withOpacity(0.2),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        if (description.isNotEmpty) ...[
                          Text(
                            description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  hasImage
                                      ? Colors.white70
                                      : theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                        ],
                        const Spacer(),
                        Row(
                          children: [
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

  Future<String?> _getProductImagePath(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return null;
    if (imagePath.startsWith('/') || imagePath.startsWith('http')) {
      return imagePath;
    }
    return ImageUtils.getAbsolutePath(imagePath);
  }
}
