import 'package:Memento/plugins/store/models/product.dart';
import 'package:Memento/plugins/store/widgets/add_product_page.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/store/widgets/product_card.dart';
import '../../controllers/store_controller.dart';

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

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: uniqueProducts.length,
      itemBuilder: (context, index) {
        final product = uniqueProducts[index];
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
    );
  }
}
