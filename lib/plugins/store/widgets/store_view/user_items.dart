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
  _UserItemsState createState() => _UserItemsState();
}

class _UserItemsState extends State<UserItems> {
  late int _statusIndex; // 0:全部, 1:可使用, 2:已过期

  @override
  void initState() {
    super.initState();
    _statusIndex = widget.initialStatusIndex;
  }

  void updateStatusFilter(int statusIndex) {
    setState(() {
      _statusIndex = statusIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.userItems.isEmpty) {
      return const Center(child: Text('暂无物品'));
    }

    return _buildMyItemsView();
  }

  Widget _buildMyItemsView() {
    final items = _getFilteredItems();
    final groupedItems = _groupItems(items);

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
            final sameTypeItems =
                widget.controller.userItems
                    .where((item) => item.productId == group.item.productId)
                    .toList();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => UserItemDetailPage(
                      controller: widget.controller,
                      items: sameTypeItems,
                    ),
              ),
            );
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
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('使用成功')));
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('物品已过期')));
              }
            },
          ),
        );
      },
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
