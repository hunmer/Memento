import 'package:Memento/plugins/store/l10n/store_localizations.dart';
import 'package:Memento/plugins/store/widgets/store_view/badge_icon.dart';
import 'package:Memento/plugins/store/widgets/store_view/product_list.dart';
import 'package:Memento/plugins/store/widgets/store_view/user_items.dart';
import 'package:Memento/plugins/store/widgets/store_view/points_history.dart';
import 'package:Memento/plugins/store/widgets/add_product_page.dart';
import 'package:Memento/plugins/store/store_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

/// Store 插件的底部栏组件
/// 提供商品列表、我的物品和积分历史三个 Tab 的切换功能
class StoreBottomBar extends StatefulWidget {
  final StorePlugin plugin;

  const StoreBottomBar({
    super.key,
    required this.plugin,
  });

  @override
  State<StoreBottomBar> createState() => _StoreBottomBarState();
}

class _StoreBottomBarState extends State<StoreBottomBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _currentPage;

  // 使用插件主题色和辅助色
  final List<Color> _colors = [
    Colors.pinkAccent,        // Tab0 - 商品列表 (插件主色)
    Colors.deepPurpleAccent,  // Tab1 - 我的物品
    Colors.greenAccent,       // Tab2 - 积分历史
  ];

  final PageStorageKey _userItemsKey = const PageStorageKey('user_items');

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

  /// 添加商品
  void _navigateToAddProduct(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddProductPage(
          controller: widget.plugin.controller,
        ),
      ),
    );
  }

  /// 显示添加积分对话框
  void _showAddPointsDialog(BuildContext context) {
    final controller = TextEditingController();
    final reasonController = TextEditingController();
    final l10n = StoreLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addPointsTitle ?? '添加积分'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.pointsAmount ?? '积分数量',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: l10n.pointsReason ?? '原因',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel ?? '取消'),
          ),
          TextButton(
            onPressed: () async {
              final points = int.tryParse(controller.text);
              final reason = reasonController.text.trim();

              if (points != null && reason.isNotEmpty) {
                await widget.plugin.controller.addPoints(points, reason);
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.pointsAdded ?? '积分已添加'),
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('请输入有效的积分数量和原因'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.add ?? '添加'),
          ),
        ],
      ),
    );

    controller.dispose();
    reasonController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color unselectedColor =
        _colors[_currentPage].computeLuminance() < 0.5
            ? Colors.black.withOpacity(0.6)
            : Colors.white.withOpacity(0.6);

    return BottomBar(
      fit: StackFit.expand,
      icon: (width, height) => Center(
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
      barColor: _colors[_currentPage].computeLuminance() > 0.5
          ? Colors.black
          : Colors.white,
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
      hideOnScroll: !kIsWeb && defaultTargetPlatform != TargetPlatform.macOS && defaultTargetPlatform != TargetPlatform.windows && defaultTargetPlatform != TargetPlatform.linux,
      scrollOpposite: false,
      onBottomBarHidden: () {},
      onBottomBarShown: () {},
      body: (context, controller) => TabBarView(
        controller: _tabController,
        dragStartBehavior: DragStartBehavior.start,
        physics: const BouncingScrollPhysics(),
        children: [
          // Tab0: 商品列表
          ProductList(
            controller: widget.plugin.controller,
            key: const PageStorageKey('product_list'),
          ),
          // Tab1: 我的物品
          UserItems(controller: widget.plugin.controller, key: _userItemsKey),
          // Tab2: 积分历史
          PointsHistory(
            controller: widget.plugin.controller,
            key: const PageStorageKey('points_history'),
          ),
        ],
      ),
      child: Stack(
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
                color: _currentPage < 3 ? _colors[_currentPage] : unselectedColor,
                width: 4,
              ),
              insets: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            ),
            labelColor: _currentPage < 3 ? _colors[_currentPage] : unselectedColor,
            unselectedLabelColor: unselectedColor,
            tabs: [
              Tab(
                icon: StreamBuilder<int>(
                  stream: widget.plugin.controller.productsStream,
                  initialData: widget.plugin.controller.products.length,
                  builder: (context, snapshot) {
                    return BadgeIcon(
                      icon: const Icon(Icons.shopping_bag),
                      count: snapshot.data ?? 0,
                    );
                  },
                ),
                text: StoreLocalizations.of(context).productList ?? '商品列表',
              ),
              Tab(
                icon: StreamBuilder<int>(
                  stream: widget.plugin.controller.userItemsStream,
                  initialData: widget.plugin.controller.userItems.length,
                  builder: (context, snapshot) {
                    return BadgeIcon(
                      icon: const Icon(Icons.inventory),
                      count: snapshot.data ?? 0,
                    );
                  },
                ),
                text: StoreLocalizations.of(context).myItems ?? '我的物品',
              ),
              Tab(
                icon: StreamBuilder<int>(
                  stream: widget.plugin.controller.pointsStream,
                  initialData: widget.plugin.controller.currentPoints,
                  builder: (context, snapshot) {
                    return BadgeIcon(
                      icon: const Icon(Icons.history),
                      count: snapshot.data ?? 0,
                      isPoints: true,
                    );
                  },
                ),
                text: StoreLocalizations.of(context).pointsHistory ?? '积分历史',
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
                _currentPage == 0 ? Icons.add_shopping_cart :
                _currentPage == 1 ? Icons.receipt_long :
                Icons.add,
                color: Colors.white,
                size: 32,
              ),
              onPressed: () {
                if (_currentPage == 0) {
                  // Tab0: 添加商品
                  _navigateToAddProduct(context);
                } else if (_currentPage == 1) {
                  // Tab1: 兑换记录 (目前跳转显示为空，实际可以打开兑换记录页面)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(StoreLocalizations.of(context).viewRedeemHistory ?? '查看兑换记录'),
                    ),
                  );
                } else {
                  // Tab2: 添加积分记录
                  _showAddPointsDialog(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}