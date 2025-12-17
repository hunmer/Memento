import 'package:get/get.dart';
import 'package:Memento/plugins/store/widgets/store_view/product_list.dart';
import 'package:Memento/plugins/store/widgets/store_view/user_items.dart';
import 'package:Memento/plugins/store/widgets/store_view/points_history.dart';
import 'package:Memento/plugins/store/widgets/add_product_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/plugins/store/store_plugin.dart';

/// Store 插件的底部栏组件
/// 提供商品列表、用户物品和积分历史三个 Tab 的切换功能
class StoreBottomBar extends StatefulWidget {
  final StorePlugin plugin;

  const StoreBottomBar({super.key, required this.plugin});

  @override
  State<StoreBottomBar> createState() => _StoreBottomBarState();
}

class _StoreBottomBarState extends State<StoreBottomBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _currentPage;
  double _bottomBarHeight = 60; // 默认底部栏高度
  final GlobalKey _bottomBarKey = GlobalKey();

  // 使用插件主题色和辅助色
  final List<Color> _colors = [
    Colors.purple, // Tab0 - 商品列表 (插件主色)
    Colors.blue.shade600, // Tab1 - 用户物品
    Colors.green.shade600, // Tab2 - 积分历史
  ];

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    _tabController = TabController(length: 3, vsync: this);
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
        final RenderBox renderBox =
            _bottomBarKey.currentContext!.findRenderObject() as RenderBox;
        final newHeight = renderBox.size.height;
        if (_bottomBarHeight != newHeight) {
          setState(() {
            _bottomBarHeight = newHeight;
          });
        }
      }
    });
  }

  /// 显示添加积分对话框
  void _showAddPointsDialog() {
    final TextEditingController pointsController = TextEditingController();
    final TextEditingController reasonController = TextEditingController(text: 'store_pointsAdjustmentDefaultReason'.tr);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('store_addPointsDialogTitle'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pointsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'store_pointsAmountLabel'.tr,
                hintText: '请输入积分数量',
                prefixIcon: const Icon(Icons.add),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'store_reasonLabel'.tr,
                hintText: '请输入添加原因',
                prefixIcon: const Icon(Icons.note_alt_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('store_cancel'.tr),
          ),
          TextButton(
            onPressed: () async {
              final points = int.tryParse(pointsController.text);
              if (points == null || points <= 0) {
                Toast.error('store_priceInvalid'.tr);
                return;
              }

              final reason = reasonController.text.isEmpty
                  ? 'store_pointsAdjustmentDefaultReason'.tr
                  : reasonController.text;

              Navigator.pop(context);
              await widget.plugin.controller.addPoints(points, reason);

              if (mounted) {
                Toast.success('${'store_pointsAdded'.tr}: +$points');
              }
            },
            child: Text('store_add'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _scheduleBottomBarHeightMeasurement();
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color unselectedColor = colorScheme.onSurface.withOpacity(0.6);
    final Color bottomAreaColor = colorScheme.surface;

    return Scaffold(
      body: BottomBar(
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
      barColor:
          Theme.of(context).bottomAppBarTheme.color ??
          Theme.of(context).scaffoldBackgroundColor,
      start: 3,
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
                      // Tab0: 商品列表 - 使用完整页面组件
                      ProductList(controller: widget.plugin.controller),
                      // Tab1: 用户物品 - 使用完整页面组件
                      UserItems(controller: widget.plugin.controller),
                      // Tab2: 积分历史 - 使用完整页面组件
                      PointsHistory(controller: widget.plugin.controller),
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
                    _currentPage < 3 ? _colors[_currentPage] : unselectedColor,
                width: 4,
              ),
              insets: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            ),
            labelColor:
                _currentPage < 3 ? _colors[_currentPage] : unselectedColor,
            unselectedLabelColor: unselectedColor,
            tabs: [
              Tab(
                icon: Icon(Icons.shopping_bag),
                text: 'store_productList'.tr,
              ),
              Tab(
                icon: Icon(Icons.inventory),
                text: 'store_myItems'.tr,
              ),
              Tab(
                icon: Icon(Icons.history),
                text: 'store_pointsHistory'.tr,
              ),
            ],
          ),
          // 只有在非【我的物品】页面才显示浮动按钮
          if (_currentPage != 1) ...[
            Positioned(
              top: -25,
              right: MediaQuery.of(context).size.width *
                  0.15 *
                  0.25, // 向右偏移底部栏宽度的1/4
              child: FloatingActionButton(
                backgroundColor: widget.plugin.color, // 使用插件主题色
                elevation: 4,
                shape: const CircleBorder(),
                child: Icon(
                  _currentPage == 0
                      ? Icons.add_shopping_cart
                      : Icons.add_chart,
                  color: widget.plugin.color.computeLuminance() < 0.5
                      ? Colors.white
                      : Colors.black,
                  size: 32,
                ),
                onPressed: () {
                  if (_currentPage == 0) {
                    // Tab0: 添加商品
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: AddProductPage(controller: widget.plugin.controller),
                      ),
                    );
                  } else if (_currentPage == 2) {
                    // Tab2: 添加积分
                    _showAddPointsDialog();
                  }
                },
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }
}
