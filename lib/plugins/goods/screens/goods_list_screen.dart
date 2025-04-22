import 'package:flutter/material.dart';
import '../models/goods_item.dart';
import '../models/warehouse.dart';
import '../goods_plugin.dart';
import '../widgets/goods_item_card.dart';
import '../widgets/goods_item_list_tile.dart';
import '../widgets/goods_item_form/goods_item_form.dart';

class GoodsListScreen extends StatefulWidget {
  const GoodsListScreen({super.key});

  @override
  State<GoodsListScreen> createState() => _GoodsListScreenState();
}

class _GoodsListScreenState extends State<GoodsListScreen> {
  bool _isGridView = true;
  String _sortBy = 'none'; // none, price, lastUsed
  String? _filterWarehouseId;
  
  @override
  void initState() {
    super.initState();
    GoodsPlugin.instance.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    GoodsPlugin.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // 获取所有物品的列表，包含仓库信息
  List<Map<String, dynamic>> _getAllItems() {
    final warehouses = GoodsPlugin.instance.warehouses;
    final allItems = <Map<String, dynamic>>[];
    
    for (var warehouse in warehouses) {
      if (_filterWarehouseId != null && warehouse.id != _filterWarehouseId) {
        continue;
      }
      
      for (var item in warehouse.items) {
        allItems.add({
          'item': item,
          'warehouse': warehouse,
        });
      }
    }
    
    // 根据排序选项排序
    switch (_sortBy) {
      case 'price':
        allItems.sort((a, b) {
          final itemA = a['item'] as GoodsItem;
          final itemB = b['item'] as GoodsItem;
          return (itemB.purchasePrice ?? 0).compareTo(itemA.purchasePrice ?? 0);
        });
        break;
      case 'lastUsed':
        allItems.sort((a, b) {
          final itemA = a['item'] as GoodsItem;
          final itemB = b['item'] as GoodsItem;
          return (itemB.lastUsedDate ?? DateTime(1970))
              .compareTo(itemA.lastUsedDate ?? DateTime(1970));
        });
        break;
    }
    
    return allItems;
  }

  void _showEditItemDialog(GoodsItem item, Warehouse warehouse) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: GoodsItemForm(
          initialData: item,
          onSubmit: (updatedItem) async {
            await GoodsPlugin.instance.saveGoodsItem(warehouse.id, updatedItem);
            if (context.mounted) {
              Navigator.pop(context);
              setState(() {});
            }
          },
          onDelete: (itemToDelete) async {
            await GoodsPlugin.instance.deleteGoodsItem(
              warehouse.id,
              itemToDelete.id,
            );
            if (context.mounted) {
              Navigator.pop(context);
              setState(() {});
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allItems = _getAllItems();
    final warehouses = GoodsPlugin.instance.warehouses;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('所有物品'),
            const SizedBox(width: 8),
            Text(
              '(${allItems.length})',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          // 仓库筛选按钮
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterWarehouseId = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('所有仓库'),
              ),
              ...warehouses.map((warehouse) => PopupMenuItem(
                    value: warehouse.id,
                    child: Text(warehouse.title),
                  )),
            ],
          ),
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
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'none', child: Text('默认排序')),
              const PopupMenuItem(value: 'price', child: Text('按价格排序')),
              const PopupMenuItem(
                value: 'lastUsed',
                child: Text('按最后使用时间'),
              ),
            ],
          ),
        ],
      ),
      body: allItems.isEmpty
          ? const Center(
              child: Text('没有物品'),
            )
          : _isGridView
              ? GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: allItems.length,
                  itemBuilder: (context, index) {
                    final item = allItems[index]['item'] as GoodsItem;
                    final warehouse = allItems[index]['warehouse'] as Warehouse;
                    return GoodsItemCard(
                      item: item,
                      warehouseTitle: warehouse.title,
                      onTap: () => _showEditItemDialog(item, warehouse),
                    );
                  },
                )
              : ListView.builder(
                  itemCount: allItems.length,
                  itemBuilder: (context, index) {
                    final item = allItems[index]['item'] as GoodsItem;
                    final warehouse = allItems[index]['warehouse'] as Warehouse;
                    return GoodsItemListTile(
                      item: item,
                      warehouseTitle: warehouse.title,
                      onTap: () => _showEditItemDialog(item, warehouse),
                    );
                  },
                ),
    );
  }
}