import 'package:flutter/material.dart';
import 'dart:io';
import '../models/goods_item.dart';

class GoodsItemListTile extends StatefulWidget {
  final GoodsItem item;
  final VoidCallback? onTap;

  const GoodsItemListTile({super.key, required this.item, this.onTap});

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
      final url = await widget.item.getImageUrl();
      if (mounted) {
        setState(() {
          _resolvedImageUrl = url;
        });
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
    if (widget.item.imageUrl != null) {
      if (_resolvedImageUrl == null) {
        return const SizedBox(
          width: 48,
          height: 48,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return SizedBox(
        width: 48,
        height: 48,
        child: Image.file(
          File(_resolvedImageUrl!),
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

    // Add last used date
    if (widget.item.lastUsedDate != null) {
      if (content.isNotEmpty) {
        content.add(const SizedBox(height: 4));
      }
      content.add(
        Text(
          '最后使用: ${widget.item.lastUsedDate.toString().split(' ')[0]}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: content,
    );
  }
}
