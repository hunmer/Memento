import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../widgets/super_cupertino_navigation_wrapper.dart';
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
    return SuperCupertinoNavigationWrapper(
      title: Text(_currentIndex == 0 ? '所有仓库' : '所有物品'),
      largeTitle: '物品管理',
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      enableLargeTitle: true,
      automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
      enableBottomBar: true,
      bottomBarHeight: 60,
      bottomBarChild: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
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
      ),
    );
  }
}
