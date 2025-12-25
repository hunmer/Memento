import 'package:get/get.dart';
import 'package:Memento/plugins/store/widgets/store_view/product_list.dart';
import 'package:Memento/plugins/store/widgets/store_view/user_items.dart';
import 'package:Memento/plugins/store/widgets/store_view/points_history.dart';
import 'package:Memento/plugins/store/widgets/add_product_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/widgets/custom_bottom_bar.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/plugins/store/store_plugin.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';

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

  /// 构建 FAB
  Widget _buildFab() {
    return FloatingActionButton(
      backgroundColor: widget.plugin.color,
      elevation: 4,
      shape: const CircleBorder(),
      child: Icon(
        _currentPage == 0 ? Icons.add_shopping_cart : Icons.add_chart,
        color: widget.plugin.color.computeLuminance() < 0.5
            ? Colors.white
            : Colors.black,
        size: 32,
      ),
      onPressed: () {
        if (_currentPage == 0) {
          NavigationHelper.push(
            context,
            AddProductPage(controller: widget.plugin.controller),
          );
        } else if (_currentPage == 2) {
          _showAddPointsDialog();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomBar(
      colors: _colors,
      currentIndex: _currentPage,
      tabController: _tabController,
      bottomBarKey: _bottomBarKey,
      body: (context, controller) => TabBarView(
        controller: _tabController,
        dragStartBehavior: DragStartBehavior.start,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          ProductList(controller: widget.plugin.controller),
          UserItems(controller: widget.plugin.controller),
          PointsHistory(controller: widget.plugin.controller),
        ],
      ),
      fab: _buildFab(),
      children: [
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
    );
  }
}
