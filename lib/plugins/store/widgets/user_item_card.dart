import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/index.dart';

class UserItemCard extends StatelessWidget {
  final dynamic item;
  final int count;
  final VoidCallback onUse;
  final VoidCallback? onDelete;
  final VoidCallback? onViewProduct;

  const UserItemCard({
    super.key,
    required this.item,
    required this.count,
    required this.onUse,
    this.onDelete,
    this.onViewProduct,
  });

  @override
  Widget build(BuildContext context) {
    // 转换 UserItem 为 UserItemCardData
    final itemData = UserItemCardData(
      id: item.id,
      productId: item.productId,
      remaining: item.remaining,
      expireDate: item.expireDate,
      purchaseDate: item.purchaseDate,
      purchasePrice: item.purchasePrice,
      productSnapshot: item.productSnapshot,
    );

    return UserItemCardWidget(
      data: itemData,
      count: count,
      onUse: onUse,
      onDelete: onDelete,
      onViewProduct: onViewProduct,
    );
  }
}
