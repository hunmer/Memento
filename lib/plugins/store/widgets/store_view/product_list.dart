import 'package:Memento/plugins/store/l10n/store_localizations.dart';
import 'package:Memento/plugins/store/models/product.dart';
import 'package:Memento/plugins/store/widgets/add_product_page.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/store/widgets/product_card.dart';
import '../../controllers/store_controller.dart';
import '../../../../widgets/super_cupertino_navigation_wrapper.dart';

class ProductList extends StatefulWidget {
  final StoreController controller;

  const ProductList({super.key, required this.controller});

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  int _sortIndex = 0; // 0:默认, 1:库存, 2:价格, 3:兑换期限
  String _searchQuery = ''; // 搜索查询关键词

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

  /// 搜索商品（根据名称和描述）
  List<Product> _searchProducts(String query, List<Product> products) {
    if (query.isEmpty) return products;

    final lowercaseQuery = query.toLowerCase();
    return products.where((product) {
      return product.name.toLowerCase().contains(lowercaseQuery) ||
             product.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// 处理搜索文本变化
  void _handleSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 去重处理
    final uniqueProducts = widget.controller.products
        .fold<Map<String, Product>>({}, (map, product) {
          if (!map.containsKey(product.id)) {
            map[product.id] = product;
          }
          return map;
        })
        .values
        .toList();

    // 应用排序
    final sortedProducts = _applySort(uniqueProducts);

    // 应用搜索筛选
    final filteredProducts = _searchProducts(_searchQuery, sortedProducts);

    // 构建商品列表Widget
    Widget _buildProductGrid(List<Product> products) {
      return products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? StoreLocalizations.of(context).noProducts
                        : '未找到匹配的商品',
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
                childAspectRatio: 0.82,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return GestureDetector(
                  onTap: () {
                    NavigationHelper.push(context, AddProductPage(
                          controller: widget.controller,
                          product: product,),
                    ).then((_) {
                      if (mounted) setState(() {});
                    });
                  },
                  child: ProductCard(
                    key: ValueKey(product.id),
                    product: product,
                    onExchange: () async {
                      if (await widget.controller.exchangeProduct(product)) {
                        if (mounted) setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              StoreLocalizations.of(context).redeemSuccess,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              StoreLocalizations.of(context).redeemFailed,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            );
    }

    return SuperCupertinoNavigationWrapper(
      title: Icon(
        Icons.shopping_bag,
        color: Colors.purple,
        size: 24,
      ),
      largeTitle: '商品列表',
      body: _buildProductGrid(filteredProducts),
      searchBody: _buildProductGrid(filteredProducts), // 搜索结果页面
      enableLargeTitle: true,
      enableSearchBar: true,
      searchPlaceholder: '搜索商品名称或描述',
      onSearchChanged: _handleSearchChanged,
      actions: [
        PopupMenuButton<int>(
          icon: const Icon(Icons.sort),
          tooltip: '排序方式',
          onSelected: (index) {
            setState(() {
              _sortIndex = index;
            });
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 0, child: Text('默认排序')),
            const PopupMenuItem(value: 1, child: Text('按库存排序')),
            const PopupMenuItem(value: 2, child: Text('按价格排序')),
            const PopupMenuItem(value: 3, child: Text('按兑换期限')),
          ],
        ),
      ],
    );
  }

  List<Product> _applySort(List<Product> products) {
    switch (_sortIndex) {
      case 1: // 库存
        return products..sort((a, b) => a.stock.compareTo(b.stock));
      case 2: // 价格
        return products..sort((a, b) => b.price.compareTo(a.price));
      case 3: // 兑换期限
        return products..sort((a, b) => b.exchangeEnd.compareTo(a.exchangeEnd));
      default: // 默认
        return products;
    }
  }
}
