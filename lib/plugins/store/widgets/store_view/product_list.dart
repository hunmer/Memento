import 'package:Memento/plugins/store/models/product.dart';
import 'package:Memento/plugins/store/widgets/add_product_page.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/store/widgets/product_card.dart';
import '../../controllers/store_controller.dart';
import 'archived_products.dart';

class ProductList extends StatefulWidget {
  final StoreController controller;

  const ProductList({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  _ProductListState createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  int _sortIndex = 0; // 0:默认, 1:库存, 2:价格, 3:兑换期限

  @override
  Widget build(BuildContext context) {
    // 去重处理
    final uniqueProducts = widget.controller.products.fold<Map<String, Product>>(
      {},
      (map, product) {
        if (!map.containsKey(product.id)) {
          map[product.id] = product;
        }
        return map;
      },
    ).values.toList();

    // 应用排序
    final sortedProducts = _applySort(uniqueProducts);

    return Column(
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
              // 存档按钮
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.archive),
                        label: Text('查看存档商品 (${widget.controller.archivedProducts.length})'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ArchivedProductsPage(
                                controller: widget.controller,
                              ),
                            ),
                          ).then((_) {
                            if (mounted) setState(() {});
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // 排序选项
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('默认'),
                        selected: _sortIndex == 0,
                        onSelected: (selected) {
                          setState(() => _sortIndex = 0);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('库存'),
                        selected: _sortIndex == 1,
                        onSelected: (selected) {
                          setState(() => _sortIndex = 1);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('价格'),
                        selected: _sortIndex == 2,
                        onSelected: (selected) {
                          setState(() => _sortIndex = 2);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('兑换期限'),
                        selected: _sortIndex == 3,
                        onSelected: (selected) {
                          setState(() => _sortIndex = 3);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // 商品列表
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
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
                      builder: (context) => AddProductPage(
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
                        const SnackBar(content: Text('兑换成功')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('兑换失败，请检查积分或库存')),
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