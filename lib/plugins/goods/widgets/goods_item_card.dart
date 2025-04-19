import 'package:flutter/material.dart';
import 'dart:io';
import '../models/goods_item.dart';

class GoodsItemCard extends StatelessWidget {
  final GoodsItem item;
  final VoidCallback? onTap;

  const GoodsItemCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: item.imageUrl != null ? _buildImage() : _buildIcon(),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题和价格行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.purchasePrice != null)
                        Text(
                          '¥${item.purchasePrice!.toStringAsFixed(2)}',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // 使用记录信息行
                  if (item.usageRecords.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.history, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatLastUsed(item.lastUsedDate)} · ${item.usageRecords.length}次使用',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600], fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (item.tags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children:
                          item.tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tag,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '今天';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}天前';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  String _formatLastUsed(DateTime? dateTime) {
    if (dateTime == null) return '从未使用';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}天前';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months个月前';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years年前';
    }
  }

  Widget _buildIcon() {
    return Container(
      color: item.iconColor ?? Colors.grey[200],
      child: Icon(
        item.icon ?? Icons.inventory_2,
        size: 48,
        color: Colors.white,
      ),
    );
  }

  Widget _buildImage() {
    final imageUrl = item.imageUrl!;
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      // 网络图片
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('网络图片加载失败: $error');
          return _buildIcon();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
            ),
          );
        },
      );
    } else {
      // 本地图片
      final file = File(imageUrl);
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('本地图片加载失败: $error\n路径: $imageUrl');
          return _buildIcon();
        },
      );
    }
  }
}
