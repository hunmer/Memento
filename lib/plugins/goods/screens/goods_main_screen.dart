import 'package:flutter/material.dart';
import 'warehouse_list_screen.dart';
import 'goods_list_screen.dart';

class GoodsMainScreen extends StatefulWidget {
  const GoodsMainScreen({super.key});

  @override
  State<GoodsMainScreen> createState() => _GoodsMainScreenState();
}

class _GoodsMainScreenState extends State<GoodsMainScreen> {
  int _currentIndex = 0;
  String? _filterWarehouseId;

  List<Widget> get _screens => [
    WarehouseListScreen(
      onWarehouseTap: _handleWarehouseTap,
    ),
    GoodsListScreen(
      key: ValueKey('goods_list_${_filterWarehouseId ?? "all"}'),
      initialFilterWarehouseId: _filterWarehouseId,
    ),
  ];

  void _handleWarehouseTap(String warehouseId) {
    setState(() {
      _filterWarehouseId = warehouseId;
      _currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.warehouse),
            label: '仓库',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: '物品',
          ),
        ],
      ),
    );
  }
}