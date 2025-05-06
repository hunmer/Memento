import 'package:flutter/material.dart';
import 'dart:io';
import '../models/goods_item.dart';

class GoodsItemCard extends StatefulWidget {
  final GoodsItem item;
  final String? warehouseTitle;
  final VoidCallback? onTap;

  const GoodsItemCard({
    super.key,
    required this.item,
    this.warehouseTitle,
    this.onTap,
  });

  @override
  State<GoodsItemCard> createState() => _GoodsItemCardState();
}

class _GoodsItemCardState extends State<GoodsItemCard> {
  String? _resolvedImageUrl;

  @override
  void initState() {
    super.initState();
    _resolveImageUrl();
  }

  @override
  void didUpdateWidget(GoodsItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.imageUrl != widget.item.imageUrl) {
      _resolveImageUrl();
    }
  }

  Future<void> _resolveImageUrl() async {
    if (widget.item.imageUrl != null) {
      try {
        final url = await widget.item.getImageUrl();
        if (mounted) {
          setState(() {
            _resolvedImageUrl = url;
          });
        }
      } catch (e) {
        debugPrint('获取图片URL失败: $e');
        if (mounted) {
          setState(() {
            _resolvedImageUrl = null;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child:
                  widget.item.imageUrl != null ? _buildImage() : _buildIcon(),
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
                          widget.item.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.item.totalPrice != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '¥${widget.item.totalPrice!.toStringAsFixed(2)}',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.item.subItems.isNotEmpty && widget.item.purchasePrice != null)
                              Text(
                                '基础价: ¥${widget.item.purchasePrice!.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // 使用记录信息行
                  // 子物品信息行
                  if (widget.item.subItems.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.layers, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.item.subItems.length}个子物品',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600], fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  
                  if (widget.item.usageRecords.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.history, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatLastUsed(widget.item.lastUsedDate)} · ${widget.item.usageRecords.length}次使用',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600], fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (widget.item.tags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children:
                          widget.item.tags.map((tag) {
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

  // 移除未使用的方法

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
      color: widget.item.iconColor ?? Colors.grey[200],
      child: Icon(
        widget.item.icon ?? Icons.inventory_2,
        size: 48,
        color: Colors.white,
      ),
    );
  }

  Widget _buildImage() {
    if (_resolvedImageUrl == null) {
      return _buildIcon();
    }
    
    final imageUrl = _resolvedImageUrl!;
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
      try {
        final file = File(imageUrl);
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('本地图片加载失败: $error\n路径: $imageUrl');
            return _buildIcon();
          },
        );
      } catch (e) {
        debugPrint('创建File对象失败: $e\n路径: $imageUrl');
        return _buildIcon();
      }
    }
  }
}
