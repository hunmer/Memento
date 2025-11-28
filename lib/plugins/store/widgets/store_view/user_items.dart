import 'package:Memento/plugins/store/l10n/store_localizations.dart';
import 'package:Memento/plugins/store/models/user_item.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/store/widgets/user_item_card.dart';
import 'package:Memento/plugins/store/widgets/user_item_detail_page.dart';
import 'package:Memento/plugins/store/controllers/store_controller.dart';

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

  @override
  Widget build(BuildContext context) {
    if (widget.controller.userItems.isEmpty) {
      return _buildEmptyView();
    }

    return _buildMyItemsView();
  }

  Widget _buildEmptyView() {
    return Center(
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
            StoreLocalizations.of(context).noItems,
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
    );
  }

  Widget _buildMyItemsView() {
    final items = _getFilteredItems();
    final groupedItems = _groupItems(items);

    return Column(
      children: [
        // 顶部标题栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.inventory,
                color: Colors.blue.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      StoreLocalizations.of(context).myItems,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '共 ${groupedItems.length} 种物品，${items.length} 件总计',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<int>(
                icon: const Icon(Icons.filter_list),
                tooltip: '筛选方式',
                onSelected: (index) {
                  setState(() {
                    _statusIndex = index;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 0, child: Text('全部物品')),
                  const PopupMenuItem(value: 1, child: Text('可使用')),
                  const PopupMenuItem(value: 2, child: Text('已过期')),
                ],
              ),
            ],
          ),
        ),
        // 物品列表
        Expanded(
          child: groupedItems.isEmpty
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

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserItemDetailPage(
                              controller: widget.controller,
                              items: sameTypeItems,
                            ),
                          ),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(StoreLocalizations.of(context).useSuccess),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(StoreLocalizations.of(context).itemExpired),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
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
}

class ItemGroup {
  final UserItem item;
  int count;

  ItemGroup({required this.item, required this.count});
}
