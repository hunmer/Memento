import 'package:get/get.dart';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper/index.dart';
import 'package:Memento/plugins/goods/models/goods_item.dart';
import 'package:Memento/plugins/goods/models/warehouse.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';
import 'package:Memento/plugins/goods/widgets/goods_item_card.dart';
import 'package:Memento/plugins/goods/widgets/goods_item_list_tile.dart';
import 'package:Memento/plugins/goods/widgets/goods_item_form/goods_item_form.dart';

class GoodsListScreen extends StatefulWidget {
  const GoodsListScreen({super.key, this.initialFilterWarehouseId});

  final String? initialFilterWarehouseId;

  @override
  State<GoodsListScreen> createState() => _GoodsListScreenState();
}

class _GoodsListScreenState extends State<GoodsListScreen> {
  bool _isGridView = true;
  String _sortBy = 'none'; // none, price, lastUsed
  String? _filterWarehouseId;
  String _searchQuery = '';

  // 多条件过滤参数
  Map<String, dynamic> _multiFilters = {};

  @override
  void initState() {
    super.initState();
    _filterWarehouseId = widget.initialFilterWarehouseId;
    GoodsPlugin.instance.addListener(_onDataChanged);

    // 设置路由上下文
    _updateRouteContext();
  }

  /// 更新路由上下文,使"询问当前上下文"功能能获取到当前筛选状态
  void _updateRouteContext() {
    if (_filterWarehouseId != null) {
      final warehouse = GoodsPlugin.instance.getWarehouse(_filterWarehouseId!);
      if (warehouse != null) {
        RouteHistoryManager.updateCurrentContext(
          pageId: "/goods/items_filtered",
          title: '物品 - 仓库: ${warehouse.title}',
          params: {
            'warehouseId': _filterWarehouseId!,
            'warehouseName': warehouse.title,
          },
        );
        return;
      }
    }

    // 没有筛选或找不到仓库，显示所有物品
    RouteHistoryManager.updateCurrentContext(
      pageId: "/goods/items_all",
      title: '物品 - 所有物品',
      params: {},
    );
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

  // 切换仓库筛选
  void _onWarehouseFilterChanged(String? warehouseId) {
    setState(() {
      // 处理特殊的\"所有仓库\"标记
      if (warehouseId == "all_warehouses") {
        _filterWarehouseId = null;
      }
      // 如果选择的是当前已选中的仓库，则清除筛选
      else if (_filterWarehouseId == warehouseId) {
        _filterWarehouseId = null;
      } else {
        _filterWarehouseId = warehouseId;
      }
    });

    // 更新路由上下文
    _updateRouteContext();
  }

  /// 获取所有物品的标签列表
  List<String> _getAllTags() {
    final tags = <String>{};
    for (var warehouse in GoodsPlugin.instance.warehouses) {
      for (var item in warehouse.items) {
        tags.addAll(item.tags);
        // 递归获取子物品的标签
        _collectTagsFromSubItems(item.subItems, tags);
      }
    }
    return tags.toList()..sort();
  }

  /// 递归收集子物品的标签
  void _collectTagsFromSubItems(List<GoodsItem> items, Set<String> tags) {
    for (var item in items) {
      tags.addAll(item.tags);
      if (item.subItems.isNotEmpty) {
        _collectTagsFromSubItems(item.subItems, tags);
      }
    }
  }

  /// 构建多条件过滤项
  List<FilterItem> _buildFilterItems() {
    final availableTags = _getAllTags();

    return [
      // 1. 标签多选过滤
      if (availableTags.isNotEmpty)
        FilterItem(
          id: 'tags',
          title: 'goods_tag'.tr,
          type: FilterType.tagsMultiple,
          builder: (context, currentValue, onChanged) {
            return FilterBuilders.buildTagsFilter(
              context: context,
              currentValue: currentValue,
              onChanged: onChanged,
              availableTags: availableTags,
            );
          },
          getBadge: FilterBuilders.tagsBadge,
        ),

      // 2. 购入日期范围过滤
      FilterItem(
        id: 'purchaseDateRange',
        title: 'goods_purchaseDateRange'.tr,
        type: FilterType.dateRange,
        builder: (context, currentValue, onChanged) {
          return FilterBuilders.buildDateRangeFilter(
            context: context,
            currentValue: currentValue,
            onChanged: onChanged,
          );
        },
        getBadge: FilterBuilders.dateRangeBadge,
      ),

      // 3. 过期日期范围过滤
      FilterItem(
        id: 'expirationDateRange',
        title: 'goods_expirationDateRange'.tr,
        type: FilterType.dateRange,
        builder: (context, currentValue, onChanged) {
          return FilterBuilders.buildDateRangeFilter(
            context: context,
            currentValue: currentValue,
            onChanged: onChanged,
          );
        },
        getBadge: FilterBuilders.dateRangeBadge,
      ),

      // 4. 价格范围过滤
      FilterItem(
        id: 'priceRange',
        title: 'goods_priceRange'.tr,
        type: FilterType.custom,
        builder: (context, currentValue, onChanged) {
          return _buildPriceRangeFilter(
            context: context,
            currentValue: currentValue,
            onChanged: onChanged,
          );
        },
        getBadge: (value) {
          if (value == null) return null;
          final range = value as Map<String, double?>;
          final min = range['min'];
          final max = range['max'];
          if (min != null && max != null) {
            return '¥$min - ¥$max';
          } else if (min != null) {
            return '≥ ¥$min';
          } else if (max != null) {
            return '≤ ¥$max';
          }
          return null;
        },
      ),

      // 5. 使用状态过滤
      FilterItem(
        id: 'status',
        title: 'goods_status'.tr,
        type: FilterType.checkbox,
        builder: (context, currentValue, onChanged) {
          return FilterBuilders.buildCheckboxFilter(
            context: context,
            currentValue: currentValue,
            onChanged: onChanged,
            options: {
              'normal': 'goods_statusNormal'.tr,
              'damaged': 'goods_statusDamaged'.tr,
              'lent': 'goods_statusLent'.tr,
              'sold': 'goods_statusSold'.tr,
            },
          );
        },
        getBadge: FilterBuilders.checkboxBadge,
        initialValue: const {
          'normal': true,
          'damaged': true,
          'lent': true,
          'sold': true,
        },
      ),
    ];
  }

  /// 构建价格范围过滤器
  Widget _buildPriceRangeFilter({
    required BuildContext context,
    required dynamic currentValue,
    required ValueChanged<dynamic> onChanged,
  }) {
    final range = (currentValue as Map<String, double?>?) ?? {'min': null, 'max': null};
    final minController = TextEditingController(
      text: range['min']?.toString() ?? '',
    );
    final maxController = TextEditingController(
      text: range['max']?.toString() ?? '',
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'goods_priceRange'.tr,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: minController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'goods_minPrice'.tr,
                    prefixText: '¥',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final newRange = Map<String, double?>.from(range);
                    newRange['min'] = double.tryParse(value);
                    onChanged(newRange);
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('-'),
              ),
              Expanded(
                child: TextField(
                  controller: maxController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'goods_maxPrice'.tr,
                    prefixText: '¥',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final newRange = Map<String, double?>.from(range);
                    newRange['max'] = double.tryParse(value);
                    onChanged(newRange);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 应用多条件过滤
  void _applyMultiFilters(Map<String, dynamic> filters) {
    // 使用 addPostFrameCallback 避免在 build 阶段调用 setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _multiFilters = filters;
        });
      }
    });
  }

  /// 检查物品是否通过所有多条件过滤
  bool _passesMultiFilters(GoodsItem item) {
    if (_multiFilters.isEmpty) return true;

    // 1. 标签过滤
    if (_multiFilters['tags'] != null && (_multiFilters['tags'] as List).isNotEmpty) {
      final selectedTags = (_multiFilters['tags'] as List).cast<String>();
      final hasAnyTag = item.tags.any((tag) => selectedTags.contains(tag));
      if (!hasAnyTag) return false;
    }

    // 2. 购入日期范围过滤
    if (_multiFilters['purchaseDateRange'] != null) {
      final range = _multiFilters['purchaseDateRange'] as DateTimeRange;
      if (item.purchaseDate == null) return false;
      if (item.purchaseDate!.isBefore(range.start) ||
          item.purchaseDate!.isAfter(range.end.add(const Duration(days: 1)))) {
        return false;
      }
    }

    // 3. 过期日期范围过滤
    if (_multiFilters['expirationDateRange'] != null) {
      final range = _multiFilters['expirationDateRange'] as DateTimeRange;
      if (item.expirationDate == null) return false;
      if (item.expirationDate!.isBefore(range.start) ||
          item.expirationDate!.isAfter(range.end.add(const Duration(days: 1)))) {
        return false;
      }
    }

    // 4. 价格范围过滤
    if (_multiFilters['priceRange'] != null) {
      final range = _multiFilters['priceRange'] as Map<String, double?>;
      final min = range['min'];
      final max = range['max'];

      if (item.purchasePrice == null) return false;

      if (min != null && item.purchasePrice! < min) return false;
      if (max != null && item.purchasePrice! > max) return false;
    }

    // 5. 使用状态过滤
    if (_multiFilters['status'] != null) {
      final statusMap = _multiFilters['status'] as Map<String, bool>;
      final itemStatus = item.status ?? 'normal';

      // 如果所有状态都被取消选择，显示所有物品
      final anyStatusSelected = statusMap.values.any((selected) => selected);
      if (anyStatusSelected && statusMap[itemStatus] != true) {
        return false;
      }
    }

    return true;
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

        // 应用多条件过滤
        if (!_passesMultiFilters(item)) {
          continue;
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
        'title': 'goods_allWarehouses'.tr,
      },
      // 将现有仓库转换为简单的id和title映射
      ...GoodsPlugin.instance.warehouses.map(
        (w) => {'id': w.id, 'title': w.title},
      ),
    ];

    return SuperCupertinoNavigationWrapper(
      title: Text(
        '${'goods_allItems'.tr} (${allItems.length})',
      ),
      largeTitle: '物品',
      enableLargeTitle: true,
      enableSearchBar: true,
      searchPlaceholder: 'goods_searchGoods'.tr,
      onSearchChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),

      // 启用多条件过滤
      enableMultiFilter: true,
      multiFilterItems: _buildFilterItems(),
      multiFilterBarHeight: 50,
      onMultiFilterChanged: _applyMultiFilters,
      // 将原有的 AppBar actions 移到右上角
      actions: [
        // 仓库筛选按钮
        PopupMenuButton<String?>(
          icon: Icon(
            Icons.filter_list,
            semanticLabel: 'goods_filter'.tr,
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
                              color: Theme.of(context).colorScheme.primary,
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
                    ? 'goods_viewAsList'.tr
                    : 'goods_viewAsGrid'.tr,
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
                  child: Text('goods_defaultSort'.tr),
                ),
                PopupMenuItem(
                  value: 'price',
                  child: Text('goods_sortByPrice'.tr),
                ),
                PopupMenuItem(
                  value: 'lastUsed',
                  child: Text(
                    'goods_sortByLastUsedTime'.tr,
                  ),
                ),
              ],
        ),
      ],
      body:
          allItems.isEmpty
              ? Center(child: Text('goods_noItems'.tr))
              : _isGridView
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            constraints.maxWidth > 600 ? 3 : 2, // 响应式列数
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75, // 调整卡片比例
                      ),
                      itemCount: allItems.length,
                      itemBuilder: (context, index) {
                        final item = allItems[index]['item'] as GoodsItem;
                        final warehouse =
                            allItems[index]['warehouse'] as Warehouse;
                        return GoodsItemCard(
                          item: item,
                          warehouseTitle: warehouse.title,
                          warehouseId: warehouse.id,
                          onTap: () => _showEditItemDialog(item, warehouse),
                        );
                      },
                    );
                  },
                )
              : ListView.builder(
                padding: EdgeInsets.zero,
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
