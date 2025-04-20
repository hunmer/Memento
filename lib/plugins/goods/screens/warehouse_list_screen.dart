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
      builder:
          (context) => Dialog(
            child: WarehouseForm(
              onSave: (Warehouse warehouse) async {
                await GoodsPlugin.instance.saveWarehouse(warehouse);
                // 移除多余的pop，因为WarehouseForm中已经有pop操作
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 根据屏幕宽度决定布局
          final isWideScreen = constraints.maxWidth > 600; // 平板或桌面端阈值

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWideScreen ? 2 : 1, // 宽屏显示两列，窄屏显示一列
              childAspectRatio: isWideScreen ? 1.5 : 2.5, // 调整长宽比
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
                      builder:
                          (context) =>
                              WarehouseDetailScreen(warehouse: warehouse),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
