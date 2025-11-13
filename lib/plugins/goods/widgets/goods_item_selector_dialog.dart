import 'package:flutter/material.dart';
import '../models/goods_item.dart';
import '../goods_plugin.dart';
import '../l10n/goods_localizations.dart';

class GoodsItemSelectorDialog extends StatefulWidget {
  final String? excludeItemId; // 要排除的物品ID（避免选择自己或已选择的子物品）
  final List<String>? excludeItemIds; // 要排除的物品ID列表
  final String? defaultCategory; // 默认选择的分类

  const GoodsItemSelectorDialog({
    super.key,
    this.excludeItemId,
    this.excludeItemIds,
    this.defaultCategory,
  });

  @override
  State<GoodsItemSelectorDialog> createState() =>
      _GoodsItemSelectorDialogState();
}

class _GoodsItemSelectorDialogState extends State<GoodsItemSelectorDialog> {
  String _searchQuery = '';
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  List<String> _availableCategories = [];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.defaultCategory;
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 加载所有可用的分类（从物品的tags中提取）
  void _loadCategories() {
    final Set<String> categories = {};

    // 从所有物品的标签中收集分类
    for (final warehouse in GoodsPlugin.instance.warehouses) {
      for (final item in warehouse.items) {
        categories.addAll(item.tags);

        // 递归获取子物品的标签
        _collectTagsFromSubItems(item, categories);
      }
    }

    setState(() {
      _availableCategories = categories.toList()..sort();
    });
  }

  // 递归收集子物品的标签
  void _collectTagsFromSubItems(GoodsItem item, Set<String> categories) {
    for (final subItem in item.subItems) {
      categories.addAll(subItem.tags);
      _collectTagsFromSubItems(subItem, categories);
    }
  }

  // 获取可选择的物品列表
  List<GoodsItem> _getSelectableItems() {
    final allItems =
        GoodsPlugin.instance.warehouses
            .expand((warehouse) => warehouse.items)
            .where((item) {
              // 排除指定的物品
              if (widget.excludeItemId != null &&
                  item.id == widget.excludeItemId) {
                return false;
              }
              if (widget.excludeItemIds != null &&
                  widget.excludeItemIds!.contains(item.id)) {
                return false;
              }

              // 分类过滤
              if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
                if (!item.tags.contains(_selectedCategory)) {
                  return false;
                }
              }

              // 搜索过滤
              if (_searchQuery.isNotEmpty) {
                final searchLower = _searchQuery.toLowerCase();
                final titleLower = item.title.toLowerCase();
                return titleLower.contains(searchLower);
              }

              return true;
            })
            .toList();

    return allItems;
  }

  // 递归获取所有物品（包括子物品）

  // 递归添加子物品
  // ignore: unused_element
  void _addSubItemsRecursively(GoodsItem item, List<GoodsItem> result) {
    for (final subItem in item.subItems) {
      result.add(subItem);
      _addSubItemsRecursively(subItem, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _getSelectableItems();

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    GoodsLocalizations.of(context).selectItem,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 分类选择器
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: GoodsLocalizations.of(context).filterByCategory,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.category),
              ),
              value: _selectedCategory,
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(GoodsLocalizations.of(context).allCategories),
                ),
                ..._availableCategories.map(
                  (category) => DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: GoodsLocalizations.of(context).searchItems,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    leading:
                        item.icon != null
                            ? Icon(item.icon, color: item.iconColor)
                            : null,
                    title: Text(item.title),
                    subtitle:
                        item.purchasePrice != null
                            ? Text(GoodsLocalizations.of(context).price)
                            : null,
                    onTap: () => Navigator.of(context).pop(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
