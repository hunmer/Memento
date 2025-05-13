import 'package:Memento/plugins/store/models/user_item.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/store/widgets/user_item_card.dart';
import 'package:Memento/plugins/store/controllers/store_controller.dart';

class UserItems extends StatefulWidget {
  final StoreController controller;

  const UserItems({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  _UserItemsState createState() => _UserItemsState();
}

class _UserItemsState extends State<UserItems> {
  int _filterIndex = 0; // 0:我的物品, 1:使用记录
  int _statusIndex = 0; // 0:全部, 1:可使用, 2:已过期

  @override
  Widget build(BuildContext context) {
    if (widget.controller.userItems.isEmpty) {
      return const Center(child: Text('暂无物品'));
    }
    
    return Column(
      children: [
        // 过滤栏
        Column(
          children: [
            // 第一行过滤
            Row(
              children: [
                _buildFilterButton('我的物品', 0),
                _buildFilterButton('使用记录', 1),
              ],
            ),
            // 第二行状态过滤
            if (_filterIndex == 0)
              Row(
                children: [
                  _buildStatusButton('全部', 0),
                  _buildStatusButton('可使用', 1),
                  _buildStatusButton('已过期', 2),
                ],
              ),
          ],
        ),
        // 物品列表
        Expanded(
          child: _filterIndex == 0 
              ? _buildMyItemsView()
              : _buildUsedItemsView(),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String text, int index) {
    return Expanded(
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: _filterIndex == index ? Colors.blue[100] : null,
        ),
        onPressed: () => setState(() => _filterIndex = index),
        child: Text(text),
      ),
    );
  }

  Widget _buildStatusButton(String text, int index) {
    return Expanded(
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: _statusIndex == index ? Colors.blue[100] : null,
        ),
        onPressed: () => setState(() => _statusIndex = index),
        child: Text(text),
      ),
    );
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
        return UserItemCard(
          item: group.item,
          count: group.count,
          onUse: () async {
            // 优先使用最早过期的物品
            final itemToUse = widget.controller.sortedUserItems
                .firstWhere((item) => item.productId == group.item.productId);
            
            if (await widget.controller.useItem(itemToUse)) {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('使用成功')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('物品已过期')),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildUsedItemsView() {
    return ListView.builder(
      itemCount: widget.controller.usedItems.length,
      itemBuilder: (context, index) {
        final usedItem = widget.controller.usedItems[index];
        return ListTile(
          title: Text(usedItem.productSnapshot['name'] ?? ''),
          subtitle: Text('使用时间: ${_formatDate(usedItem.useDate)}'),
        );
      },
    );
  }

  List<UserItem> _getFilteredItems() {
    final now = DateTime.now();
    switch (_statusIndex) {
      case 1: // 可使用
        return widget.controller.userItems
            .where((item) => item.expireDate.isAfter(now))
            .toList();
      case 2: // 已过期
        return widget.controller.userItems
            .where((item) => item.expireDate.isBefore(now))
            .toList();
      default: // 全部
        return widget.controller.userItems;
    }
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class ItemGroup {
  final UserItem item;
  int count;

  ItemGroup({
    required this.item,
    required this.count,
  });
}
