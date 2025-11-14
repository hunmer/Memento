import 'package:flutter/material.dart';
import 'dart:io';
import '../models/goods_item.dart';

class GoodsItemListTile extends StatefulWidget {
  final GoodsItem item;
  final String? warehouseTitle;
  final VoidCallback? onTap;

  const GoodsItemListTile({
    super.key,
    required this.item,
    this.warehouseTitle,
    this.onTap,
  });

  @override
  State<GoodsItemListTile> createState() => _GoodsItemListTileState();
}

class _GoodsItemListTileState extends State<GoodsItemListTile> {
  String? _resolvedImageUrl;

  @override
  void initState() {
    super.initState();
    _resolveImageUrl();
  }

  Future<void> _resolveImageUrl() async {
    if (widget.item.imageUrl != null) {
      try {
        // 优先使用缩略图进行预览
        final url = await widget.item.getThumbUrl() ?? await widget.item.getImageUrl();
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
    return ListTile(
      leading: _buildLeading(),
      title: Text(widget.item.title),
      subtitle: _buildSubtitle(context),
      trailing:
          widget.item.purchasePrice != null
              ? Text(
                '¥${widget.item.purchasePrice!.toStringAsFixed(2)}',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              )
              : null,
      onTap: widget.onTap,
    );
  }

  Widget _buildLeading() {
    if (widget.item.imageUrl != null && _resolvedImageUrl != null) {
      final imageUrl = _resolvedImageUrl!;
      return SizedBox(
        width: 48,
        height: 48,
        child: _buildImage(imageUrl),
      );
    }
    return _buildIcon();
  }

  Widget _buildImage(String imageUrl) {
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
              value: loadingProgress.expectedTotalBytes != null
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

  Widget _buildIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: widget.item.iconColor ?? Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(widget.item.icon ?? Icons.inventory_2, color: Colors.white),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final List<Widget> content = [];

    // Add tags
    if (widget.item.tags.isNotEmpty) {
      content.add(
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

    // Add warehouse info
    if (widget.warehouseTitle != null) {
      if (content.isNotEmpty) {
        content.add(const SizedBox(height: 4));
      }
      content.add(
        Row(
          children: [
            Icon(Icons.warehouse, size: 12, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.warehouseTitle!,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    
    // Add last used date
    if (widget.item.lastUsedDate != null) {
      if (content.isNotEmpty) {
        content.add(const SizedBox(height: 4));
      }
      content.add(
        Row(
          children: [
            Icon(Icons.history, size: 12, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '最后使用: ${widget.item.lastUsedDate.toString().split(' ')[0]}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: content,
    );
  }
}
