import 'package:flutter/material.dart';
import '../models/goods_item.dart';

class GoodsItemListTile extends StatelessWidget {
  final GoodsItem item;
  final VoidCallback? onTap;

  const GoodsItemListTile({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildLeading(),
      title: Text(item.title),
      subtitle: _buildSubtitle(context),
      trailing: item.purchasePrice != null
          ? Text(
              '¥${item.purchasePrice!.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildLeading() {
    if (item.imageUrl != null) {
      return SizedBox(
        width: 48,
        height: 48,
        child: Image.network(
          item.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildIcon();
          },
        ),
      );
    }
    return _buildIcon();
  }

  Widget _buildIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: item.iconColor ?? Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        item.icon ?? Icons.inventory_2,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final List<Widget> content = [];

    // Add tags
    if (item.tags.isNotEmpty) {
      content.add(
        Wrap(
          spacing: 4,
          children: item.tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tag,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          }).toList(),
        ),
      );
    }

    // Add last used date
    if (item.lastUsedDate != null) {
      if (content.isNotEmpty) {
        content.add(const SizedBox(height: 4));
      }
      content.add(
        Text(
          '最后使用: ${item.lastUsedDate.toString().split(' ')[0]}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: content,
    );
  }
}