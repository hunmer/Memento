import 'package:Memento/plugins/store/l10n/store_localizations.dart';
import 'package:Memento/plugins/store/models/product.dart';
import 'package:Memento/plugins/store/widgets/add_product_page.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/store/widgets/product_card.dart';
import '../../controllers/store_controller.dart';

class ProductList extends StatefulWidget {
  final StoreController controller;

  const ProductList({super.key, required this.controller});

  @override
  _ProductListState createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final int _sortIndex = 0; // 0:默认, 1:库存, 2:价格, 3:兑换期限

  @override
  Widget build(BuildContext context) {
    // 去重处理
    final uniqueProducts =
        widget.controller.products
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

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          // 排序栏
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 排序选项
                // 排序选项将使用store_main.dart中的对话框
              ],
            ),
          ),
          // 商品列表
          Expanded(
            child: GridView.builder(
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => AddProductPage(
                              controller: widget.controller,
                              product: product,
                            ),
                      ),
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
      ),
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
