import 'package:flutter/material.dart';
import '../../controllers/store_controller.dart';
import '../../models/product.dart';
import '../product_card.dart';

class ArchivedProductsPage extends StatefulWidget {
  final StoreController controller;

  const ArchivedProductsPage({super.key, required this.controller});

  @override
  _ArchivedProductsPageState createState() => _ArchivedProductsPageState();
}

class _ArchivedProductsPageState extends State<ArchivedProductsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('存档商品')),
      body:
          widget.controller.archivedProducts.isEmpty
              ? const Center(child: Text('没有存档商品'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.controller.archivedProducts.length,
                itemBuilder: (context, index) {
                  final product = widget.controller.archivedProducts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildArchivedProductCard(product),
                  );
                },
              ),
    );
  }

  Widget _buildArchivedProductCard(Product product) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          ProductCard(
            product: product,
            onExchange: () => _showRestoreConfirmation(product),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.archive, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('已存档', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: FloatingActionButton.small(
              heroTag: 'restore_${product.id}',
              onPressed: () => _showRestoreConfirmation(product),
              child: const Icon(Icons.unarchive),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRestoreConfirmation(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认恢复'),
            content: const Text('确定要恢复这个商品吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('恢复'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await widget.controller.restoreProduct(product);
      if (mounted) setState(() {});
    }
  }
}
