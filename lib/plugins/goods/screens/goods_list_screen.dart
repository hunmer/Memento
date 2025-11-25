import 'package:flutter/material.dart';
import '../l10n/goods_localizations.dart';
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
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    GoodsPlugin.instance.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    GoodsPlugin.instance.removeListener(_onDataChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // 切换仓库筛选
  void _onWarehouseFilterChanged(String? warehouseId) {
    setState(() {
      // 处理特殊的\"所有仓库\"标记
      if (warehouseId == "all_warehouses") {
        _filterWarehouseId = null;
        return;
      }

      // 如果选择的是当前已选中的仓库，则清除筛选
      if (_filterWarehouseId == warehouseId) {
        _filterWarehouseId = null;
      } else {
        _filterWarehouseId = warehouseId;
      }
    });
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
        // 如果有搜索查询，过滤不匹配的项目
        if (_searchQuery.isNotEmpty) {
          final searchLower = _searchQuery.toLowerCase();
          final titleLower = item.title.toLowerCase();
          if (!titleLower.contains(searchLower)) {
            continue;
          }
        }

        allItems.add({'item': item, 'warehouse': warehouse});
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
          return (itemB.lastUsedDate ?? DateTime(1970)).compareTo(
            itemA.lastUsedDate ?? DateTime(1970),
          );
        });
        break;
    }

    return allItems;
  }

  void _showEditItemDialog(GoodsItem item, Warehouse warehouse) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: GoodsItemForm(
              initialData: item,
              onSubmit: (updatedItem) async {
                await GoodsPlugin.instance.saveGoodsItem(
                  warehouse.id,
                  updatedItem,
                );
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
    // 获取仓库列表并添加"所有仓库"选项
    final List<Map<String, String>> warehouses = [
      // 添加"所有仓库"选项
      {
        'id': 'all_warehouses',
        'title': GoodsLocalizations.of(context).allWarehouses,
      },
      // 将现有仓库转换为简单的id和title映射
      ...GoodsPlugin.instance.warehouses.map(
        (w) => {'id': w.id, 'title': w.title},
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: GoodsLocalizations.of(context).searchGoods,
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Theme.of(context).hintColor),
                  ),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                )
                : Row(
                  children: [
                    Text(GoodsLocalizations.of(context).allItems),
                    const SizedBox(width: 8),
                    Text(
                      '(${allItems.length})',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
        actions:
            _isSearching
                ? [
                  // 搜索模式下只显示关闭按钮
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      semanticLabel: GoodsLocalizations.of(context).close,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  ),
                ]
                : [
                  // 搜索按钮
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      setState(() {
                        _isSearching = true;
                      });
                    },
                  ),
                  // 仓库筛选按钮
                  PopupMenuButton<String?>(
                    icon: Icon(
                      Icons.filter_list,
                      semanticLabel: GoodsLocalizations.of(context).filter,
                      // 当有筛选时显示不同的图标颜色
                      color:
                          _filterWarehouseId != null
                              ? Theme.of(context).colorScheme.primary
                              : null,
                    ),
                    initialValue: _filterWarehouseId,
                    onSelected: _onWarehouseFilterChanged,
                    itemBuilder:
                        (context) => [
                          // 删除单独的"所有仓库"选项，因为现在它已经包含在warehouses列表中
                          ...warehouses.map(
                            (warehouse) => PopupMenuItem(
                              value: warehouse['id'],
                              child: Row(
                                children: [
                                  Text(warehouse['title']!),
                                  if (_filterWarehouseId == warehouse['id'])
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Icon(
                                        Icons.check,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                  ),
                  // 视图切换按钮
                  IconButton(
                    icon: Icon(
                      _isGridView ? Icons.view_list : Icons.grid_view,
                      semanticLabel:
                          _isGridView
                              ? GoodsLocalizations.of(context).viewAsList
                              : GoodsLocalizations.of(context).viewAsGrid,
                    ),
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
                          PopupMenuItem(
                            value: 'none',
                            child: Text(
                              GoodsLocalizations.of(context).defaultSort,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'price',
                            child: Text(
                              GoodsLocalizations.of(context).sortByPrice,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'lastUsed',
                            child: Text(
                              GoodsLocalizations.of(context).sortByLastUsedTime,
                            ),
                          ),
                        ],
                  ),
                ],
      ),
      body:
          allItems.isEmpty
              ? Center(child: Text(GoodsLocalizations.of(context).noItems))
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
                    warehouseId: warehouse.id,
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
