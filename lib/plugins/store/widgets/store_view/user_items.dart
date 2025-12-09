import 'package:get/get.dart';
import 'package:Memento/plugins/store/models/user_item.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/store/widgets/user_item_card.dart';
import 'package:Memento/plugins/store/widgets/user_item_detail_page.dart';
import 'package:Memento/plugins/store/controllers/store_controller.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/core/services/toast_service.dart';

class UserItems extends StatefulWidget {
  final StoreController controller;
  final int initialStatusIndex;

  const UserItems({
    super.key,
    required this.controller,
    this.initialStatusIndex = 0,
  });

  @override
  State<UserItems> createState() => _UserItemsState();
}

class _UserItemsState extends State<UserItems> {
  late int _statusIndex; // 0:全部, 1:可使用, 2:已过期
  String _searchQuery = ''; // 搜索查询文本

  @override
  void initState() {
    super.initState();
    _statusIndex = widget.initialStatusIndex;
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void updateStatusFilter(int statusIndex) {
    setState(() {
      _statusIndex = statusIndex;
    });
  }

  /// 处理搜索文本变化
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  /// 搜索过滤物品（按名称和描述）
  List<UserItem> _searchItems(List<UserItem> items) {
    if (_searchQuery.isEmpty) return items;

    final query = _searchQuery.toLowerCase();
    return items.where((item) {
      final name = item.productName.toLowerCase();
      final description = (item.productSnapshot['description'] ?? '').toLowerCase();
      return name.contains(query) || description.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.userItems.isEmpty) {
      return _buildEmptyView();
    }

    return _buildMyItemsView();
  }

  Widget _buildEmptyView() {
    return SuperCupertinoNavigationWrapper(
      title: Icon(
        Icons.inventory,
        color: Colors.blue.shade600,
        size: 24,
      ),
      largeTitle: 'store_myItems'.tr,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'store_noItems'.tr,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '前往商品列表兑换物品',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
      enableLargeTitle: true,
      // 即使没有物品也启用搜索栏，让用户可以搜索（虽然不会有结果）
      enableSearchBar: true,
      searchPlaceholder: '搜索物品名称或描述',
      onSearchChanged: _onSearchChanged,
      // 提供空的搜索结果页面
      searchBody: _buildSearchResultsView(),
    );
  }

  Widget _buildMyItemsView() {
    final items = _getFilteredItems();
    final groupedItems = _groupItems(items);

    return SuperCupertinoNavigationWrapper(
      title: Icon(
        Icons.inventory,
        color: Colors.blue.shade600,
        size: 24,
      ),
      largeTitle: 'store_myItems'.tr,
      body: groupedItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.filter_alt_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '该筛选条件下暂无物品',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: groupedItems.length,
              itemBuilder: (context, index) {
                final group = groupedItems[index];
                return GestureDetector(
                  onTap: () {
                    // 获取同类型的所有物品
                    final sameTypeItems = widget.controller.userItems
                        .where((item) => item.productId == group.item.productId)
                        .toList();

                    NavigationHelper.push(context, UserItemDetailPage(
                          controller: widget.controller,
                          items: sameTypeItems,),
                    ).then((_) {
                      if (mounted) setState(() {});
                    });
                  },
                  child: UserItemCard(
                    item: group.item,
                    count: group.count,
                    onUse: () async {
                      // 优先使用最早过期的物品
                      final itemToUse = widget.controller.sortedUserItems.firstWhere(
                        (item) => item.productId == group.item.productId,
                      );

                      if (await widget.controller.useItem(itemToUse)) {
                        setState(() {});
                        Toast.success('store_useSuccess'.tr);
                      } else {
                        Toast.error('store_itemExpired'.tr);
                      }
                    },
                  ),
                );
              },
            ),
      // 启用搜索栏
      enableSearchBar: true,
      searchPlaceholder: '搜索物品名称或描述',
      onSearchChanged: _onSearchChanged,
      // 搜索结果页面
      searchBody: _buildSearchResultsView(),
      enableLargeTitle: true,
      actions: [
        PopupMenuButton<int>(
          icon: const Icon(Icons.filter_list),
          tooltip: '筛选方式',
          onSelected: (index) {
            setState(() {
              _statusIndex = index;
            });
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 0, child: Text('store_allItems'.tr)),
            PopupMenuItem(value: 1, child: Text('store_usable'.tr)),
            PopupMenuItem(value: 2, child: Text('store_expired'.tr)),
          ],
        ),
      ],
    );
  }

  List<UserItem> _getFilteredItems() {
    final now = DateTime.now();
    return widget.controller.userItems.where((item) {
      switch (_statusIndex) {
        case 1: // 可使用
          return item.expireDate.isAfter(now);
        case 2: // 已过期
          return item.expireDate.isBefore(now);
        default: // 全部
          return true;
      }
    }).toList();
  }

  List<ItemGroup> _groupItems(List<UserItem> items) {
    final groups = <String, ItemGroup>{};

    for (final item in items) {
      final key = '${item.productId}_${item.purchasePrice}';
      if (groups.containsKey(key)) {
        groups[key]!.count++;
      } else {
        groups[key] = ItemGroup(item: item, count: 1);
      }
    }

    return groups.values.toList();
  }

  /// 构建搜索结果页面
  Widget _buildSearchResultsView() {
    // 获取所有物品并应用搜索过滤
    final allItems = widget.controller.userItems;
    final filteredItems = _searchItems(allItems);
    final groupedItems = _groupItems(filteredItems);

    // 如果没有搜索查询，显示提示
    if (_searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '输入关键词搜索物品',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // 如果搜索结果为空，显示空状态
    if (groupedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '未找到相关物品',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '尝试使用其他关键词',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // 显示搜索结果
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: groupedItems.length,
      itemBuilder: (context, index) {
        final group = groupedItems[index];
        return GestureDetector(
          onTap: () {
            // 获取同类型的所有物品
            final sameTypeItems = widget.controller.userItems
                .where((item) => item.productId == group.item.productId)
                .toList();

            NavigationHelper.push(context, UserItemDetailPage(
                  controller: widget.controller,
                  items: sameTypeItems,),
            ).then((_) {
              if (mounted) setState(() {});
            });
          },
          child: UserItemCard(
            item: group.item,
            count: group.count,
            onUse: () async {
              // 优先使用最早过期的物品
              final itemToUse = widget.controller.sortedUserItems.firstWhere(
                (item) => item.productId == group.item.productId,
              );

              if (await widget.controller.useItem(itemToUse)) {
                setState(() {});
                Toast.success('store_useSuccess'.tr);
              } else {
                Toast.error('store_itemExpired'.tr);
              }
            },
          ),
        );
      },
    );
  }
}

class ItemGroup {
  final UserItem item;
  int count;

  ItemGroup({required this.item, required this.count});
}
