import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/index.dart';

class ProductCard extends StatelessWidget {
  final dynamic product;
  final VoidCallback onExchange;
  final VoidCallback? onLongPress;

  const ProductCard({
    super.key,
    required this.product,
    required this.onExchange,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // 转换 Product 为 ProductCardData
    final productData = ProductCardData(
      id: product.id,
      name: product.name,
      description: product.description,
      image: product.image,
      stock: product.stock,
      price: product.price,
      exchangeStart: product.exchangeStart,
      exchangeEnd: product.exchangeEnd,
      useDuration: product.useDuration,
    );

    return ProductCardWidget(
      data: productData,
      onExchange: onExchange,
      onLongPress: onLongPress,
    );
  }
}
