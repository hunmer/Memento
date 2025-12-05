import 'package:Memento/plugins/store/l10n/store_localizations.dart';
import 'package:Memento/plugins/store/models/user_item.dart';
import 'package:Memento/plugins/store/widgets/user_item_card.dart';
import 'package:Memento/plugins/store/widgets/user_item_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import '../../controllers/store_controller.dart';

/// 我的物品内容组件（不包含 Scaffold，用于 TabBarView）
class UserItemsContent extends StatefulWidget {
  final StoreController controller;
  final int initialStatusIndex;

  const UserItemsContent({
    super.key,
    required this.controller,
    this.initialStatusIndex = 0,
  });

  @override
  State<UserItemsContent> createState() => _UserItemsContentState();
}

class _UserItemsContentState extends State<UserItemsContent> {
  late int _statusIndex;

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
      return Center(child: Text(StoreLocalizations.of(context).noItems));
    }

    return _buildMyItemsView();
  }

  Widget _buildMyItemsView() {
    final items = _getFilteredItems();
    final groupedItems = _groupItems(items);

    if (groupedItems.isEmpty) {
      return Center(
        child: Text(StoreLocalizations.of(context).noItems),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: groupedItems.length,
      itemBuilder: (context, index) {
        final group = groupedItems[index];
        return GestureDetector(
          onTap: () {
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

  List<_ItemGroup> _groupItems(List<UserItem> items) {
    final groups = <String, _ItemGroup>{};

    for (final item in items) {
      final key = '${item.productId}_${item.purchasePrice}';
      if (groups.containsKey(key)) {
        groups[key]!.count++;
      } else {
        groups[key] = _ItemGroup(item: item, count: 1);
      }
    }

    return groups.values.toList();
  }
}

class _ItemGroup {
  final UserItem item;
  int count;

  _ItemGroup({required this.item, required this.count});
}
