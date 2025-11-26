import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/goods/l10n/goods_localizations.dart';
import 'package:flutter/material.dart';
import '../models/warehouse.dart';
import '../widgets/warehouse_form.dart';
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
  late String _sortBy; // none, price, lastUsed
  late Warehouse _warehouse;

  @override
  void initState() {
    super.initState();
    _warehouse = widget.warehouse;
    // 从插件中获取该仓库的排序偏好
    _sortBy = GoodsPlugin.instance.getSortPreference(_warehouse.id);

    // 监听物品添加事件
    EventManager.instance.subscribe('goods_item_added', (args) {
      if (args is GoodsItemAddedEventArgs &&
          args.warehouseId == _warehouse.id) {
        _refreshWarehouse();
      }
    });

    // 监听物品删除事件
    EventManager.instance.subscribe('goods_item_deleted', (args) {
      if (args is GoodsItemDeletedEventArgs &&
          args.warehouseId == _warehouse.id) {
        _refreshWarehouse();
      }
    });
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
                title: Text(GoodsLocalizations.of(context).editWarehouseTitle),
                onTap: () {
                  Navigator.pop(context);
                  // 实现仓库编辑功能
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => WarehouseForm(
                            warehouse: _warehouse,
                            onSave: (warehouse) async {
                              await GoodsPlugin.instance.saveWarehouse(
                                warehouse,
                              );
                              if (context.mounted) {
                                await _refreshWarehouse();
                              }
                            },
                            onDelete: () async {
                              await GoodsPlugin.instance.deleteWarehouse(
                                _warehouse.id,
                              );
                              if (context.mounted) {
                                // 连退两页：关闭表单页和详情页
                                Navigator.pop(context); // 关闭表单
                                Navigator.pop(context); // 关闭详情
                              }
                            },
                          ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(GoodsLocalizations.of(context).clearWarehouseTitle),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text(
                            GoodsLocalizations.of(
                              context,
                            ).confirmClearWarehouse,
                          ),
                          content: Text(
                            GoodsLocalizations.of(
                              context,
                            ).confirmClearWarehouseMessage,
                          ),
                          actions: [
                            TextButton(
                              child: Text(AppLocalizations.of(context)!.cancel),
                              onPressed: () => Navigator.pop(context, false),
                            ),
                            TextButton(
                              child: Text(AppLocalizations.of(context)!.ok),
                              onPressed: () => Navigator.pop(context, true),
                            ),
                          ],
                        ),
                  );

                  if (confirm == true && context.mounted) {
                    await GoodsPlugin.instance.clearWarehouse(_warehouse.id);
                    Navigator.pop(context);
                    await _refreshWarehouse();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text(
                  GoodsLocalizations.of(context).deleteWarehouseTitle,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text(
                            GoodsLocalizations.of(context).confirmDelete,
                          ),
                          content: Text(
                            GoodsLocalizations.of(context)
                                .confirmDeleteWarehouseMessage
                                .replaceFirst('%s', _warehouse.title),
                          ),
                          actions: [
                            TextButton(
                              child: Text(AppLocalizations.of(context)!.cancel),
                              onPressed: () => Navigator.pop(context, false),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(AppLocalizations.of(context)!.delete),
                            ),
                          ],
                        ),
                  );

                  if (confirm == true && context.mounted) {
                    await GoodsPlugin.instance.deleteWarehouse(_warehouse.id);
                    // 关闭底部菜单
                    Navigator.pop(context);
                    // 返回上一页
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
              onDelete: (item) async {
                await GoodsPlugin.instance.deleteGoodsItem(
                  _warehouse.id,
                  item.id,
                );
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
  void dispose() {
    // 取消事件订阅
    EventManager.instance.unsubscribe('goods_item_added');
    EventManager.instance.unsubscribe('goods_item_deleted');
    super.dispose();
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
            onSelected: (value) async {
              setState(() {
                _sortBy = value;
              });
              // 保存排序偏好
              await GoodsPlugin.instance.saveSortPreference(
                _warehouse.id,
                value,
              );
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'none',
                    child: Text(GoodsLocalizations.of(context).sortByDefault),
                  ),
                  PopupMenuItem(
                    value: 'price',
                    child: Text(GoodsLocalizations.of(context).sortByPrice),
                  ),
                  PopupMenuItem(
                    value: 'lastUsed',
                    child: Text(
                      GoodsLocalizations.of(context).sortByLastUsedTime,
                    ),
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
              ? Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: List.generate(items.length, (index) {
                        final item = items[index];
                        final cardWidth = (constraints.maxWidth - 16) / 2; // 2列布局，减去一个spacing

                        return SizedBox(
                          width: cardWidth,
                          child: GoodsItemCard(
                            item: item,
                            warehouseId: _warehouse.id,
                            onTap: () => _showEditItemDialog(item),
                          ),
                        );
                      }),
                    );
                  },
                ),
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
