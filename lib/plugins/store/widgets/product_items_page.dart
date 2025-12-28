import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/store/controllers/store_controller.dart';
import 'package:Memento/plugins/store/models/user_item.dart';
import 'package:Memento/plugins/store/widgets/user_item_card.dart';
import 'package:Memento/plugins/store/widgets/user_item_detail_page.dart';
import 'package:Memento/plugins/store/widgets/add_product_page.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

/// 商品物品列表页面 - 显示特定商品的所有已兑换物品
class ProductItemsPage extends StatefulWidget {
  final String productId;
  final String productName;
  final StoreController controller;

  const ProductItemsPage({
    super.key,
    required this.productId,
    required this.productName,
    required this.controller,
  });

  @override
  State<ProductItemsPage> createState() => _ProductItemsPageState();
}

class _ProductItemsPageState extends State<ProductItemsPage> {
  int _statusIndex = 0; // 0: 全部, 1: 可使用, 2: 已过期

  @override
  void initState() {
    super.initState();
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

  List<UserItem> _getFilteredItems() {
    final now = DateTime.now();
    return widget.controller.userItems.where((item) {
      // 首先按商品ID筛选
      if (item.productId != widget.productId) return false;

      // 然后按状态筛选
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _getFilteredItems();
    final groupedItems = _groupItems(items);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.productName),
            Text(
              '${'store_itemQuantity'.tr}: ${items.length}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          // 查看商品详情
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              final product = widget.controller.products.firstWhereOrNull(
                (p) => p.id == widget.productId,
              );
              if (product != null) {
                NavigationHelper.push(
                  context,
                  AddProductPage(
                    controller: widget.controller,
                    product: product,
                  ),
                );
              } else {
                Toast.warning('store_productNotFound'.tr);
              }
            },
            tooltip: 'store_viewProductInfo'.tr,
          ),
        ],
      ),
      body: Column(
        children: [
          // 状态筛选栏
          _buildStatusFilter(theme),
          const Divider(height: 1),
          // 物品列表
          Expanded(
            child: groupedItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'store_noItems'.tr,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  )
                : MasonryGridView.count(
                    padding: const EdgeInsets.all(8),
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    itemCount: groupedItems.length,
                    itemBuilder: (context, index) {
                      final group = groupedItems[index];
                      return GestureDetector(
                        onTap: () {
                          final sameTypeItems = items
                              .where((item) => item.productId == group.item.productId)
                              .toList();

                          NavigationHelper.push(
                            context,
                            UserItemDetailPage(
                              controller: widget.controller,
                              items: sameTypeItems,
                            ),
                          ).then((_) {
                            if (mounted) setState(() {});
                          });
                        },
                        child: UserItemCard(
                          item: group.item,
                          count: group.count,
                          onUse: () async {
                            final itemToUse = items.firstWhere(
                              (item) => item.productId == group.item.productId,
                            );

                            if (await widget.controller.useItem(itemToUse)) {
                              setState(() {});
                              Toast.success('store_useSuccess'.tr);
                            } else {
                              Toast.error('store_itemExpired'.tr);
                            }
                          },
                          onDelete: () async {
                            final itemToDelete = items.firstWhere(
                              (item) => item.productId == group.item.productId,
                            );
                            await widget.controller.deleteUserItem(itemToDelete);
                            setState(() {});
                            Toast.success('app_deleteSuccess'.tr);
                          },
                          onViewProduct: () {
                            final product = widget.controller.products
                                .firstWhereOrNull(
                              (p) => p.id == group.item.productId,
                            );
                            if (product != null) {
                              NavigationHelper.push(
                                context,
                                AddProductPage(
                                  controller: widget.controller,
                                  product: product,
                                ),
                              ).then((_) {
                                if (mounted) setState(() {});
                              });
                            } else {
                              Toast.warning('store_productNotFound'.tr);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'store_itemStatus'.tr,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusChip(0, 'store_all'.tr, theme),
                  const SizedBox(width: 8),
                  _buildStatusChip(1, 'store_usable'.tr, theme),
                  const SizedBox(width: 8),
                  _buildStatusChip(2, 'store_expired'.tr, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(int index, String label, ThemeData theme) {
    final isSelected = _statusIndex == index;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _statusIndex = index;
          });
        }
      },
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
    );
  }
}

class _ItemGroup {
  final UserItem item;
  int count;

  _ItemGroup({required this.item, required this.count});
}
