import 'package:Memento/plugins/store/l10n/store_localizations.dart';
import 'package:Memento/plugins/store/models/product.dart';
import 'package:Memento/plugins/store/widgets/add_product_page.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/store/widgets/product_card.dart';
import '../../controllers/store_controller.dart';

class ProductList extends StatefulWidget {
  final StoreController controller;

  const ProductList({super.key, required this.controller});

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  int _sortIndex = 0; // 0:默认, 1:库存, 2:价格, 3:兑换期限

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
                Icons.shopping_bag,
                color: Colors.purple,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '商品列表',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '共 ${sortedProducts.length} 件商品',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
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
          ),
        ),
        // 商品列表
        Expanded(
          child: sortedProducts.isEmpty
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
                        StoreLocalizations.of(context).noProducts,
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
                    childAspectRatio: 0.6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: sortedProducts.length,
                  itemBuilder: (context, index) {
                    final product = sortedProducts[index];
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
                ),
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
