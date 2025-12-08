import 'package:Memento/plugins/store/l10n/store_localizations.dart';
import 'package:Memento/plugins/store/models/product.dart';
import 'package:Memento/plugins/store/widgets/add_product_page.dart';
import 'package:Memento/plugins/store/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/store/controllers/store_controller.dart';
import 'package:Memento/core/services/toast_service.dart';

/// 商品列表内容组件（不包含 Scaffold，用于 TabBarView）
class ProductListContent extends StatefulWidget {
  final StoreController controller;

  const ProductListContent({super.key, required this.controller});

  @override
  State<ProductListContent> createState() => _ProductListContentState();
}

class _ProductListContentState extends State<ProductListContent> {
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

    if (uniqueProducts.isEmpty) {
      return Center(
        child: Text(StoreLocalizations.of(context).noProducts),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: uniqueProducts.length,
      itemBuilder: (context, index) {
        final product = uniqueProducts[index];
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
                Toast.success(
                  StoreLocalizations.of(context).redeemSuccess,
                );
              } else {
                Toast.error(
                  StoreLocalizations.of(context).redeemFailed,
                );
              }
            },
          ),
        );
      },
    );
  }
}
