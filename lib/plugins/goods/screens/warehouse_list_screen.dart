import 'dart:io' show Platform;
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/goods/l10n/goods_localizations.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import '../goods_plugin.dart';
import 'warehouse_detail_screen.dart';
import '../widgets/warehouse_card.dart';

class WarehouseListScreen extends StatefulWidget {
  const WarehouseListScreen({super.key, this.onWarehouseTap});

  final Function(String warehouseId)? onWarehouseTap;

  @override
  State<WarehouseListScreen> createState() => _WarehouseListScreenState();
}

class _WarehouseListScreenState extends State<WarehouseListScreen> {

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
        automaticallyImplyLeading: false,
        leading:
            (Platform.isAndroid || Platform.isIOS)
                ? null
                : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => PluginManager.toHomeScreen(context),
                ),
        title: Text(GoodsLocalizations.of(context).allWarehouses),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
        itemCount: warehouses.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final warehouse = warehouses[index];
          return WarehouseCard(
            warehouse: warehouse,
            onTap: () {
              if (widget.onWarehouseTap != null) {
                widget.onWarehouseTap!(warehouse.id);
              } else {
                NavigationHelper.push(context, WarehouseDetailScreen(warehouse: warehouse),
                );
              }
            },
          );
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _showAddWarehouseDialog,
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}
