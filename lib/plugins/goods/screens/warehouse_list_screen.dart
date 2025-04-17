import 'package:flutter/material.dart';
import '../goods_plugin.dart';
import '../models/warehouse.dart';
import 'warehouse_detail_screen.dart';
import '../widgets/warehouse_card.dart';
import '../widgets/warehouse_form.dart';

class WarehouseListScreen extends StatefulWidget {
  const WarehouseListScreen({super.key});

  @override
  State<WarehouseListScreen> createState() => _WarehouseListScreenState();
}

class _WarehouseListScreenState extends State<WarehouseListScreen> {
  void _showAddWarehouseDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: WarehouseForm(
          onSave: (Warehouse warehouse) async {
            await GoodsPlugin.instance.saveWarehouse(warehouse);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    GoodsPlugin.instance.addListener(_onWarehousesChanged);
  }

  @override
  void dispose() {
    GoodsPlugin.instance.removeListener(_onWarehousesChanged);
    super.dispose();
  }

  void _onWarehousesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final warehouses = GoodsPlugin.instance.warehouses;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('所有仓库'),
            const SizedBox(width: 8),
            Text(
              '(${warehouses.length})',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddWarehouseDialog,
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: warehouses.length,
        itemBuilder: (context, index) {
          final warehouse = warehouses[index];
          return WarehouseCard(
            warehouse: warehouse,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => WarehouseDetailScreen(
                    warehouse: warehouse,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}