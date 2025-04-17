import 'package:flutter/material.dart';
import '../models/warehouse.dart';
import '../models/goods_item.dart';
import '../goods_plugin.dart';
import '../widgets/goods_item_card.dart';
import '../widgets/goods_item_list_tile.dart';
import '../widgets/goods_item_form/goods_item_form.dart';

class WarehouseDetailScreen extends StatefulWidget {
  final Warehouse warehouse;

  const WarehouseDetailScreen({super.key, required this.warehouse});

  @override
  State<WarehouseDetailScreen> createState() => _WarehouseDetailScreenState();
}

class _WarehouseDetailScreenState extends State<WarehouseDetailScreen> {
  bool _isGridView = true;
  String _sortBy = 'none'; // none, price, lastUsed
  late Warehouse _warehouse;

  @override
  void initState() {
    super.initState();
    _warehouse = widget.warehouse;
  }

  Future<void> _refreshWarehouse() async {
    final updatedWarehouse = GoodsPlugin.instance.getWarehouse(_warehouse.id);
    if (updatedWarehouse != null && mounted) {
      setState(() {
        _warehouse = updatedWarehouse;
      });
    }
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: GoodsItemForm(
              onSubmit: (GoodsItem item) async {
                await GoodsPlugin.instance.saveGoodsItem(_warehouse.id, item);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  await _refreshWarehouse();
                }
              },
            ),
          ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
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
                    builder:
                        (context) => AlertDialog(
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
    final items = List<GoodsItem>.from(_warehouse.items);
    switch (_sortBy) {
      case 'price':
        items.sort(
          (a, b) => (b.purchasePrice ?? 0).compareTo(a.purchasePrice ?? 0),
        );
        break;
      case 'lastUsed':
        items.sort(
          (a, b) => (b.lastUsedDate ?? DateTime(1970)).compareTo(
            a.lastUsedDate ?? DateTime(1970),
          ),
        );
        break;
    }
    return items;
  }

  void _showEditItemDialog(GoodsItem item) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: GoodsItemForm(
              initialData: item,
              onSubmit: (item) async {
                await GoodsPlugin.instance.saveGoodsItem(_warehouse.id, item);
                if (context.mounted) {
                  Navigator.pop(context);
                  await _refreshWarehouse();
                }
              },
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _getSortedItems();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(_warehouse.title),
            const SizedBox(width: 8),
            Text(
              '(${items.length})',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          // 视图切换按钮
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          // 排序按钮
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'none', child: Text('默认排序')),
                  const PopupMenuItem(value: 'price', child: Text('按价格排序')),
                  const PopupMenuItem(
                    value: 'lastUsed',
                    child: Text('按最后使用时间'),
                  ),
                ],
          ),
          // 更多选项按钮
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      body:
          _isGridView
              ? GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return GoodsItemCard(
                    item: item,
                    onTap: () => _showEditItemDialog(item),
                  );
                },
              )
              : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return GoodsItemListTile(
                    item: item,
                    onTap: () => _showEditItemDialog(item),
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
