import 'package:Memento/plugins/store/l10n/store_localizations.dart';
import 'package:Memento/plugins/store/widgets/store_view/product_list_page.dart';
import 'package:Memento/plugins/store/widgets/store_view/user_items_page.dart';
import 'package:Memento/plugins/store/widgets/store_view/points_history_page.dart';
import 'package:Memento/plugins/store/widgets/store_view/badge_icon.dart';
import 'package:Memento/plugins/store/store_plugin.dart';
import 'package:flutter/material.dart';

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

class _StoreBottomBarState extends State<StoreBottomBar> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = StoreLocalizations.of(context);

    return Stack(
      children: [
        // 主内容区域：三个独立的页面
        IndexedStack(
          index: _currentIndex,
          children: [
            // Tab0: 商品列表
            ProductListPage(
              controller: widget.plugin.controller,
              key: const PageStorageKey('product_list_page'),
            ),
            // Tab1: 我的物品
            UserItemsPage(
              controller: widget.plugin.controller,
              key: const PageStorageKey('user_items_page'),
            ),
            // Tab2: 积分历史
            PointsHistoryPage(
              controller: widget.plugin.controller,
              key: const PageStorageKey('points_history_page'),
            ),
          ],
        ),
        // 底部导航栏
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() => _currentIndex = index);
                },
                elevation: 0,
                backgroundColor: Colors.transparent,
                items: [
                  BottomNavigationBarItem(
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
                    label: l10n.productList,
                  ),
                  BottomNavigationBarItem(
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
                    label: l10n.myItems,
                  ),
                  BottomNavigationBarItem(
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
                    label: l10n.pointsHistory,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
