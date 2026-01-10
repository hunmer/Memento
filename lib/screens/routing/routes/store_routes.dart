import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/routing/route_definition.dart';
import 'package:Memento/screens/routing/route_helpers.dart';
import 'package:Memento/plugins/store/widgets/store_view/store_main.dart';
import 'package:Memento/plugins/store/widgets/store_view/points_history_page.dart';
import 'package:Memento/plugins/store/widgets/product_items_page.dart';
import 'package:Memento/plugins/store/widgets/user_item_detail_page.dart';
import 'package:Memento/plugins/store/store_plugin.dart';

/// Store 插件路由注册表
class StoreRoutes implements RouteRegistry {
  @override
  String get name => 'StoreRoutes';

  @override
  List<RouteDefinition> get routes => [
        // Store 主页面
        RouteDefinition(
          path: '/store',
          handler: (settings) {
            String? itemId;
            bool autoUse = false;
            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              itemId = args['itemId'] as String?;
              autoUse = args['autoUse'] as bool? ?? false;
            }
            debugPrint('[Route] /store: itemId=$itemId, autoUse=$autoUse');
            if (itemId != null) {
              return RouteHelpers.createRoute(
                _StoreUserItemRoute(itemId: itemId, autoUse: autoUse),
              );
            }
            return RouteHelpers.createRoute(const StoreMainView());
          },
          description: '积分商城主页面',
        ),
        RouteDefinition(
          path: 'store',
          handler: (settings) {
            String? itemId;
            bool autoUse = false;
            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              itemId = args['itemId'] as String?;
              autoUse = args['autoUse'] as bool? ?? false;
            }
            debugPrint('[Route] /store: itemId=$itemId, autoUse=$autoUse');
            if (itemId != null) {
              return RouteHelpers.createRoute(
                _StoreUserItemRoute(itemId: itemId, autoUse: autoUse),
              );
            }
            return RouteHelpers.createRoute(const StoreMainView());
          },
          description: '积分商城主页面（别名）',
        ),

        // 商品物品列表页面
        RouteDefinition(
          path: '/store/product_items',
          handler: (settings) => _handleProductItemsRoute(settings),
          description: '商品物品列表页面',
        ),
        RouteDefinition(
          path: 'store/product_items',
          handler: (settings) => _handleProductItemsRoute(settings),
          description: '商品物品列表页面（别名）',
        ),

        // 用户物品详情页面
        RouteDefinition(
          path: '/store/user_item',
          handler: (settings) => _handleUserItemRoute(settings),
          description: '用户物品详情页面',
        ),
        RouteDefinition(
          path: 'store/user_item',
          handler: (settings) => _handleUserItemRoute(settings),
          description: '用户物品详情页面（别名）',
        ),

        // 积分历史页面
        RouteDefinition(
          path: '/store/points_history',
          handler: (settings) => RouteHelpers.createRoute(const PointsHistoryPage()),
          description: '积分历史页面',
        ),
        RouteDefinition(
          path: 'store/points_history',
          handler: (settings) => RouteHelpers.createRoute(const PointsHistoryPage()),
          description: '积分历史页面（别名）',
        ),
      ];

  static Route<dynamic> _handleProductItemsRoute(RouteSettings settings) {
    String? productId;
    String? productName;
    bool autoUse = false;
    bool autoBuy = false;

    if (settings.arguments is Map<String, dynamic>) {
      final args = settings.arguments as Map<String, dynamic>;
      productId = args['productId'] as String?;
      productName = args['productName'] as String?;
      autoUse = args['autoUse'] as bool? ?? false;
      autoBuy = args['autoBuy'] as bool? ?? false;
    }

    if (productId == null) {
      debugPrint('错误: 缺少必需参数 productId');
      return RouteHelpers.createRoute(
        const Scaffold(
          body: Center(child: Text('参数错误：缺少商品ID')),
        ),
      );
    }

    debugPrint('打开商品物品列表: productId=$productId, productName=$productName, autoUse=$autoUse, autoBuy=$autoBuy');

    final storePlugin = PluginManager.instance.getPlugin('store') as StorePlugin?;
    if (storePlugin == null) {
      debugPrint('错误: Store 插件未初始化');
      return RouteHelpers.createRoute(
        const Scaffold(
          body: Center(child: Text('Store 插件未初始化')),
        ),
      );
    }

    return RouteHelpers.createRoute(
      ProductItemsPage(
        productId: productId,
        productName: productName ?? '商品',
        controller: storePlugin.controller,
        autoUse: autoUse,
        autoBuy: autoBuy,
      ),
    );
  }

  static Route<dynamic> _handleUserItemRoute(RouteSettings settings) {
    String? itemId;
    bool autoUse = false;
    if (settings.arguments is Map<String, dynamic>) {
      final args = settings.arguments as Map<String, dynamic>;
      itemId = args['itemId'] as String?;
      autoUse = args['autoUse'] as bool? ?? false;
    }

    if (itemId == null) {
      debugPrint('错误: 缺少必需参数 itemId');
      return RouteHelpers.createRoute(
        const Scaffold(
          body: Center(child: Text('参数错误：缺少物品ID')),
        ),
      );
    }

    debugPrint('[Route] /store/user_item: itemId=$itemId, autoUse=$autoUse');

    final storePlugin = PluginManager.instance.getPlugin('store') as StorePlugin?;
    if (storePlugin == null) {
      debugPrint('错误: Store 插件未初始化');
      return RouteHelpers.createRoute(
        const Scaffold(
          body: Center(child: Text('Store 插件未初始化')),
        ),
      );
    }

    debugPrint('[Route] 当前 userItems 数量: ${storePlugin.controller.userItems.length}');
    for (var item in storePlugin.controller.userItems) {
      debugPrint('[Route]  - item.id: ${item.id} (类型: ${item.id.runtimeType})');
    }

    final userItem = storePlugin.controller.userItems.firstWhereOrNull(
      (item) => item.id.toString() == itemId.toString(),
    );

    if (userItem == null) {
      debugPrint('[Route] 物品不存在: itemId=$itemId');
      return RouteHelpers.createRoute(
        const Scaffold(
          body: Center(child: Text('物品不存在')),
        ),
      );
    }

    debugPrint('[Route] 创建 UserItemDetailPage: autoUse=$autoUse, itemName=${userItem.productName}');
    return RouteHelpers.createRoute(
      UserItemDetailPage(
        controller: storePlugin.controller,
        items: [userItem],
        initialIndex: 0,
        autoUse: autoUse,
      ),
    );
  }
}

/// Store 插件用户物品详情路由
class _StoreUserItemRoute extends StatelessWidget {
  final String itemId;
  final bool autoUse;

  const _StoreUserItemRoute({required this.itemId, this.autoUse = false});

  @override
  Widget build(BuildContext context) {
    debugPrint('[Route] _StoreUserItemRoute.build: itemId=$itemId, autoUse=$autoUse');
    final storePlugin = PluginManager.instance.getPlugin('store') as StorePlugin?;
    if (storePlugin == null) {
      debugPrint('[Route] Store 插件未初始化');
      return const Scaffold(
        body: Center(child: Text('Store 插件未初始化')),
      );
    }

    final userItem = storePlugin.controller.userItems.firstWhereOrNull(
      (item) => item.id == itemId,
    );

    if (userItem == null) {
      debugPrint('[Route] 物品不存在: itemId=$itemId');
      return const Scaffold(
        body: Center(child: Text('物品不存在')),
      );
    }

    debugPrint('[Route] 创建 UserItemDetailPage: autoUse=$autoUse');
    return UserItemDetailPage(
      controller: storePlugin.controller,
      items: [userItem],
      initialIndex: 0,
      autoUse: autoUse,
    );
  }
}
