// ignore_for_file: library_private_types_in_public_api

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/store/controllers/store_controller.dart';
import 'package:Memento/plugins/store/models/product.dart';
import 'package:Memento/plugins/store/widgets/product_card.dart';

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
      appBar: AppBar(title: Text('store_archivedProductsTitle'.tr)),
      body:
          widget.controller.archivedProducts.isEmpty
              ? Center(child: Text('store_noArchivedProducts'.tr))
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
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.archive, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'store_archivedLabel'.tr,
                    style: TextStyle(color: Colors.white),
                  ),
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
            title: Text('store_confirmRestoreTitle'.tr),
            content: Text('store_confirmRestoreMessage'.tr),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('app_cancel'.tr),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('store_restore'.tr),
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
