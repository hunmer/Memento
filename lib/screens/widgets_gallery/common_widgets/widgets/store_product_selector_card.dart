/// 商品选择器公共小组件
///
/// 显示商品列表，支持单个或多个商品展示
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/utils/image_utils.dart';

/// 商品数据模型
class ProductData {
  final String id;
  final String name;
  final String description;
  final int price;
  final int stock;
  final String? image;

  ProductData({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    this.image,
  });

  factory ProductData.fromJson(Map<String, dynamic> json) {
    return ProductData(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'image': image,
    };
  }
}

/// 商品选择器小组件
class StoreProductSelectorCardWidget extends StatefulWidget {
  /// 商品列表
  final List<ProductData> products;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const StoreProductSelectorCardWidget({
    super.key,
    required this.products,
    required this.size,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory StoreProductSelectorCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final productsList = (props['products'] as List<dynamic>?)
            ?.map((e) => ProductData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return StoreProductSelectorCardWidget(
      products: productsList,
      size: size,
    );
  }

  @override
  State<StoreProductSelectorCardWidget> createState() =>
      _StoreProductSelectorCardWidgetState();
}

class _StoreProductSelectorCardWidgetState extends State<StoreProductSelectorCardWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = widget.products;

    if (products.isEmpty) {
      return _buildEmptyWidget(context, theme);
    }

    // 单个商品显示详情，多个商品显示列表
    if (products.length == 1) {
      return _buildSingleProduct(context, theme, products.first);
    } else {
      return _buildProductList(context, theme, products);
    }
  }

  /// 构建单个商品布局
  Widget _buildSingleProduct(
    BuildContext context,
    ThemeData theme,
    ProductData product,
  ) {
    return FutureBuilder<String?>(
      future: _getImagePath(product.image),
      builder: (context, imageSnapshot) {
        final hasImage =
            imageSnapshot.hasData &&
            imageSnapshot.data != null &&
            imageSnapshot.data!.isNotEmpty;

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1),
              image: hasImage
                  ? DecorationImage(
                      image: ImageUtils.createImageProvider(imageSnapshot.data),
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
                        color: Colors.black.withOpacity(0.2),
                      ),
                    ),
                  ),
                // 内容区域
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 商品名称
                      Text(
                        product.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: hasImage ? Colors.white : theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // 商品描述
                      if (product.description.isNotEmpty) ...[
                        Text(
                          product.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: hasImage
                                ? Colors.white70
                                : theme.colorScheme.onSurfaceVariant,
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
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${product.price} ${'store_points'.tr}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          // 库存状态
                          Text(
                            product.stock > 0
                                ? '${'store_stockLabel'.tr}: ${product.stock}'
                                : 'store_outOfStock'.tr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: hasImage
                                  ? (product.stock > 0 ? Colors.green : Colors.grey)
                                  : (product.stock > 0 ? Colors.green : Colors.grey),
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
        );
      },
    );
  }

  /// 构建商品列表布局
  Widget _buildProductList(
    BuildContext context,
    ThemeData theme,
    List<ProductData> products,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.shopping_bag, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '商品列表',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${products.length}个商品',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // 商品列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _buildProductListItem(context, theme, products[index]);
            },
          ),
        ),
      ],
    ),
    );
  }

  /// 构建商品列表项
  Widget _buildProductListItem(
    BuildContext context,
    ThemeData theme,
    ProductData product,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 商品图标/图片
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.shopping_bag, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          // 商品信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Icon(Icons.monetization_on, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      '${product.price} ${'store_points'.tr}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      product.stock > 0
                          ? '${'store_stockLabel'.tr}: ${product.stock}'
                          : 'store_outOfStock'.tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: product.stock > 0 ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyWidget(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              '暂无商品',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取图片路径
  Future<String?> _getImagePath(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return null;
    if (imagePath.startsWith('/') || imagePath.startsWith('http')) {
      return imagePath;
    }
    return ImageUtils.getAbsolutePath(imagePath);
  }
}
