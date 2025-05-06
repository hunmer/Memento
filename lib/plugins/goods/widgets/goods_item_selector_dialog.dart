import 'package:flutter/material.dart';
import '../models/goods_item.dart';
import '../goods_plugin.dart';

class GoodsItemSelectorDialog extends StatefulWidget {
  final String? excludeItemId; // 要排除的物品ID（避免选择自己或已选择的子物品）
  final List<String>? excludeItemIds; // 要排除的物品ID列表

  const GoodsItemSelectorDialog({
    super.key,
    this.excludeItemId,
    this.excludeItemIds,
  });

  @override
  State<GoodsItemSelectorDialog> createState() => _GoodsItemSelectorDialogState();
}

class _GoodsItemSelectorDialogState extends State<GoodsItemSelectorDialog> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 获取可选择的物品列表
  List<GoodsItem> _getSelectableItems() {
    final allItems = GoodsPlugin.instance.warehouses
        .expand((warehouse) => warehouse.items)
        .where((item) {
      // 排除指定的物品
      if (widget.excludeItemId != null && item.id == widget.excludeItemId) {
        return false;
      }
      if (widget.excludeItemIds != null && widget.excludeItemIds!.contains(item.id)) {
        return false;
      }

      // 搜索过滤
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final titleLower = item.title.toLowerCase();
        return titleLower.contains(searchLower);
      }

      return true;
    }).toList();

    return allItems;
  }

  @override
  Widget build(BuildContext context) {
    final items = _getSelectableItems();

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '选择物品',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '搜索物品...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    leading: item.icon != null
                        ? Icon(item.icon, color: item.iconColor)
                        : null,
                    title: Text(item.title),
                    subtitle: item.purchasePrice != null
                        ? Text('￥${item.purchasePrice?.toStringAsFixed(2)}')
                        : null,
                    onTap: () => Navigator.of(context).pop(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}