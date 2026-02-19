import 'package:flutter/material.dart';
import '../../../../widgets/super_cupertino_navigation_wrapper.dart';
import 'warehouse_list_screen.dart';
import 'goods_list_screen.dart';

class GoodsMainScreen extends StatefulWidget {
  const GoodsMainScreen({
    super.key,
    this.showGoodsTab = false,
    this.initialFilterWarehouseId,
    this.filterTags,
    this.filterStartDate,
    this.filterEndDate,
  });

  /// 是否直接显示物品标签页
  final bool showGoodsTab;

  /// 初始仓库筛选ID
  final String? initialFilterWarehouseId;

  /// 标签筛选列表
  final List<dynamic>? filterTags;

  /// 开始日期筛选
  final String? filterStartDate;

  /// 结束日期筛选
  final String? filterEndDate;

  @override
  State<GoodsMainScreen> createState() => _GoodsMainScreenState();
}

class _GoodsMainScreenState extends State<GoodsMainScreen> {
  late int _currentIndex;
  String? _filterWarehouseId;

  @override
  void initState() {
    super.initState();
    // 根据参数设置初始标签页
    _currentIndex = widget.showGoodsTab ? 1 : 0;
    _filterWarehouseId = widget.initialFilterWarehouseId;
  }

  List<Widget> get _screens => [
    WarehouseListScreen(onWarehouseTap: _handleWarehouseTap),
    GoodsListScreen(
      key: ValueKey('goods_list_${_filterWarehouseId ?? "all"}'),
      initialFilterWarehouseId: _filterWarehouseId,
      initialFilterTags: widget.filterTags,
      initialFilterStartDate: widget.filterStartDate,
      initialFilterEndDate: widget.filterEndDate,
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
      body: IndexedStack(index: _currentIndex, children: _screens),
      enableLargeTitle: true,

      enableBottomBar: true,
      bottomBarHeight: 60,
      bottomBarChild: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
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
            BottomNavigationBarItem(icon: Icon(Icons.warehouse), label: '仓库'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory), label: '物品'),
          ],
        ),
      ),
    );
  }
}
