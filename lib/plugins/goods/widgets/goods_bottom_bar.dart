import 'package:get/get.dart';
import 'package:Memento/plugins/goods/screens/warehouse_list_screen.dart';
import 'package:Memento/plugins/goods/screens/goods_list_screen.dart';
import 'package:Memento/plugins/goods/widgets/warehouse_form.dart';
import 'package:Memento/plugins/goods/widgets/goods_item_form/index.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';

/// Goods 插件的底部栏组件
/// 提供仓库视图和物品视图的切换功能
class GoodsBottomBar extends StatefulWidget {
  final GoodsPlugin plugin;

  const GoodsBottomBar({super.key, required this.plugin});

  @override
  State<GoodsBottomBar> createState() => _GoodsBottomBarState();
}

class _GoodsBottomBarState extends State<GoodsBottomBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _currentPage;
  String? _filterWarehouseId;
  double _bottomBarHeight = 60; // 默认底部栏高度
  final GlobalKey _bottomBarKey = GlobalKey();

  // 使用插件主题色和辅助色
  final List<Color> _colors = [
    const Color.fromARGB(255, 207, 77, 116), // Tab0 - 仓库视图 (插件主色)
    Colors.pink.shade400, // Tab1 - 物品视图
  ];

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.animation?.addListener(() {
      final value = _tabController.animation!.value.round();
      if (value != _currentPage && mounted) {
        setState(() {
          _currentPage = value;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 调度底部栏高度测量
  void _scheduleBottomBarHeightMeasurement() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _bottomBarKey.currentContext != null) {
        final RenderBox renderBox = _bottomBarKey.currentContext!.findRenderObject() as RenderBox;
        final newHeight = renderBox.size.height;
        if (_bottomBarHeight != newHeight) {
          setState(() {
            _bottomBarHeight = newHeight;
          });
        }
      }
    });
  }

  /// 创建新仓库
  Future<void> _createWarehouse() async {

    await NavigationHelper.push(context, WarehouseForm(
              onSave: (warehouse) async {
                try {
                  await widget.plugin.saveWarehouse(warehouse);
                  if (mounted) {
              Toast.success('goods_warehouseCreated'.tr);
                  }
                } catch (e) {
                  if (mounted) {
              Toast.error('${'goods_createWarehouseFailed'.tr}: $e');
                  }
                }
              },
      )
    );
  }

  /// 处理仓库点击事件
  void _handleWarehouseTap(String warehouseId) {
    setState(() {
      _filterWarehouseId = warehouseId;
    });
    // 切换到物品视图 (tab index 1)
    _tabController.animateTo(1);
  }

  /// 添加物品
  Future<void> _addItem() async {

    // 如果没有仓库，提示先创建仓库
    if (widget.plugin.warehouses.isEmpty) {
      Toast.info('goods_createWarehouseFirst'.tr);
      return;
    }

    // 跳转到物品创建表单
    NavigationHelper.push(context, GoodsItemForm(
              onSubmit: (item) async {
                try {
                  // 选择第一个仓库（实际应用中应该让用户选择）
                  final warehouseId = widget.plugin.warehouses.first.id;
                  await widget.plugin.saveGoodsItem(warehouseId, item);
                  if (mounted) {
              Toast.success('goods_itemCreated'.tr);
                  }
                } catch (e) {
                  if (mounted) {
              Toast.error('${'goods_createItemFailed'.tr}: $e');
                  }
                }
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _scheduleBottomBarHeightMeasurement();
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color unselectedColor = colorScheme.onSurface.withOpacity(0.6);
    final Color bottomAreaColor = colorScheme.surface;

    return BottomBar(
      fit: StackFit.expand,
      icon:
          (width, height) => Center(
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                // 滚动到顶部功能
                if (_tabController.indexIsChanging) return;

                // 切换到第一个tab
                if (_currentPage != 0) {
                  _tabController.animateTo(0);
                }
              },
              icon: Icon(
                Icons.keyboard_arrow_up,
                color: _colors[_currentPage],
                size: width,
              ),
            ),
          ),
      borderRadius: BorderRadius.circular(25),
      duration: const Duration(milliseconds: 300),
      curve: Curves.decelerate,
      showIcon: true,
      width: MediaQuery.of(context).size.width * 0.85,
      barColor: colorScheme.surface,
      start: 2,
      end: 0,
      offset: 12,
      barAlignment: Alignment.bottomCenter,
      iconHeight: 35,
      iconWidth: 35,
      reverse: false,
      barDecoration: BoxDecoration(
        color: _colors[_currentPage].withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: _colors[_currentPage].withOpacity(0.3),
          width: 1,
        ),
      ),
      iconDecoration: BoxDecoration(
        color: _colors[_currentPage].withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _colors[_currentPage].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      hideOnScroll:
          !kIsWeb &&
          defaultTargetPlatform != TargetPlatform.macOS &&
          defaultTargetPlatform != TargetPlatform.windows &&
          defaultTargetPlatform != TargetPlatform.linux,
      scrollOpposite: false,
      onBottomBarHidden: () {},
      onBottomBarShown: () {},
      body:
          (context, controller) => Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(bottom: _bottomBarHeight),
                  child: TabBarView(
                    controller: _tabController,
                    dragStartBehavior: DragStartBehavior.start,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Tab0: 仓库视图
                      WarehouseListScreen(onWarehouseTap: _handleWarehouseTap),
                      // Tab1: 物品视图
                      GoodsListScreen(
                        key: ValueKey('goods_list_${_filterWarehouseId ?? "all"}'),
                        initialFilterWarehouseId: _filterWarehouseId,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: _bottomBarHeight,
                  color: bottomAreaColor,
                ),
              ),
            ],
          ),
      child: Stack(
        key: _bottomBarKey,
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            indicatorPadding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                color:
                    _currentPage < 2 ? _colors[_currentPage] : unselectedColor,
                width: 4,
              ),
              insets: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            ),
            labelColor:
                _currentPage < 2 ? _colors[_currentPage] : unselectedColor,
            unselectedLabelColor: unselectedColor,
            tabs: [
              Tab(
                icon: const Icon(Icons.warehouse),
                text: 'goods_warehouseTab'.tr,
              ),
              Tab(
                icon: const Icon(Icons.inventory_2),
                text: 'goods_itemsTab'.tr,
              ),
            ],
          ),
          Positioned(
            top: -25,
            child: FloatingActionButton(
              backgroundColor: widget.plugin.color, // 使用插件主题色
              elevation: 4,
              shape: const CircleBorder(),
              child: Icon(
                _currentPage == 0 ? Icons.add_business : Icons.add,
                color: widget.plugin.color.computeLuminance() < 0.5
                    ? Colors.white
                    : Colors.black,
                size: 32,
              ),
              onPressed: () {
                if (_currentPage == 0) {
                  // Tab0: 添加仓库
                  _createWarehouse();
                } else {
                  // Tab1: 添加物品
                  _addItem();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
