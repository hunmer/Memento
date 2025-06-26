import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/store/l10n/store_localizations.dart';
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
      appBar: AppBar(
        title: Text(StoreLocalizations.of(context).archivedProductsTitle),
      ),
      body:
          widget.controller.archivedProducts.isEmpty
              ? Center(
                child: Text(StoreLocalizations.of(context).noArchivedProducts),
              )
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.archive, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    StoreLocalizations.of(context).archivedLabel,
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
            title: Text(StoreLocalizations.of(context).confirmRestoreTitle),
            content: Text(StoreLocalizations.of(context).confirmRestoreMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(StoreLocalizations.of(context).restore),
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
