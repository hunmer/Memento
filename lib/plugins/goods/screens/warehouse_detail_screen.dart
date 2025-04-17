import 'package:flutter/material.dart';
import '../models/warehouse.dart';
import '../models/goods_item.dart';
import '../goods_plugin.dart';
import '../widgets/goods_item_card.dart';
import '../widgets/goods_item_list_tile.dart';
import '../widgets/goods_item_form.dart';

class WarehouseDetailScreen extends StatefulWidget {
  final Warehouse warehouse;

  const WarehouseDetailScreen({
    super.key,
    required this.warehouse,
  });

  @override
  State<WarehouseDetailScreen> createState() => _WarehouseDetailScreenState();
}

class _WarehouseDetailScreenState extends State<WarehouseDetailScreen> {
  bool _isGridView = true;
  String _sortBy = 'none'; // none, price, lastUsed

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: GoodsItemForm(
          onSave: (GoodsItem item) async {
            await GoodsPlugin.instance.saveGoodsItem(widget.warehouse.id, item);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('编辑仓库'),
            onTap: () {
              // TODO: Implement warehouse editing
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('清空仓库'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('确认清空'),
                  content: const Text('确定要清空此仓库中的所有物品吗？'),
                  actions: [
                    TextButton(
                      child: const Text('取消'),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    TextButton(
                      child: const Text('确定'),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                // TODO: Implement clear warehouse
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  List<GoodsItem> _getSortedItems() {
    final items = List<GoodsItem>.from(widget.warehouse.items);
    switch (_sortBy) {
      case 'price':
        items.sort((a, b) => 
          (b.purchasePrice ?? 0).compareTo(a.purchasePrice ?? 0));
        break;
      case 'lastUsed':
        items.sort((a, b) {
          final aDate = a.lastUsedDate;
          final bDate = b.lastUsedDate;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });
        break;
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _getSortedItems();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.warehouse.title),
            const SizedBox(width: 8),
            Text(
              '(${items.length})',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'none',
                child: Text('默认排序'),
              ),
              const PopupMenuItem(
                value: 'price',
                child: Text('按价格排序'),
              ),
              const PopupMenuItem(
                value: 'lastUsed',
                child: Text('按最近使用排序'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      body: _isGridView
          ? GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return GoodsItemCard(
                  item: items[index],
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        child: GoodsItemForm(
                          item: items[index],
                          onSave: (item) async {
                            await GoodsPlugin.instance.saveGoodsItem(
                              widget.warehouse.id,
                              item,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            )
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return GoodsItemListTile(
                  item: items[index],
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        child: GoodsItemForm(
                          item: items[index],
                          onSave: (item) async {
                            await GoodsPlugin.instance.saveGoodsItem(
                              widget.warehouse.id,
                              item,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}