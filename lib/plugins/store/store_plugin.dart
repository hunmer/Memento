import 'dart:convert';
import 'package:Memento/plugins/store/l10n/store_localizations.dart';
import 'package:Memento/plugins/store/widgets/store_view/store_main.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/base_plugin.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/plugins/store/controllers/store_controller.dart';
import 'package:Memento/plugins/store/widgets/point_settings_view.dart';
import 'package:Memento/plugins/store/models/product.dart';
import 'package:Memento/plugins/store/controls/prompt_controller.dart';

/// 物品兑换插件
class StorePlugin extends BasePlugin with JSBridgePlugin {
  @override
  String get id => 'store';

  @override
  Color get color => Colors.pinkAccent;

  @override
  IconData get icon => Icons.store;

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    await initialize();
  }

  StoreController? _controller;
  StorePromptController? _promptController;
  bool _isInitialized = false;

  /// 获取商店控制器
  StoreController get controller {
    assert(
      _isInitialized,
      'StorePlugin must be initialized before accessing controller',
    );
    return _controller!;
  }

  /// 默认积分配置
  static const Map<String, dynamic> defaultPointSettings = {
    'point_awards': {
      'activity_added': 3, // 添加活动奖励
      'checkin_completed': 10, // 签到完成奖励
      'task_completed': 20, // 完成任务奖励
      'note_added': 10, // 添加笔记奖励
      'goods_added': 5, // 添加物品奖励
      'onMessageSent': 1, // 发送消息奖励
      'onRecordAdded': 2, // 添加记录奖励
      'onDiaryAdded': 5, // 添加日记奖励
      'bill_added': 10, // 添加账单奖励
    },
  };

  /// 获取事件积分配置
  Map<String, int> get pointAwardSettings =>
      (settings['point_awards'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as int),
      );

  @override
  Future<void> initialize() async {
    if (!_isInitialized) {
      await loadSettings(defaultPointSettings);
      _controller = StoreController(this);
      await _controller!.loadFromStorage();

      // 初始化积分奖励事件处理器

      // 初始化 Prompt 控制器
      _promptController = StorePromptController(this);
      _promptController!.initialize();

      _isInitialized = true;

      // 注册 JS API（最后一步）
      await registerJSAPI();
    }
  }

  @override
  String? getPluginName(context) {
    return StoreLocalizations.of(context).name;
  }

  @override
  Widget buildMainView(BuildContext context) {
    return StoreMainView();
  }

  @override
  Widget? buildCardView(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部图标和标题
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                StoreLocalizations.of(context).name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 统计信息卡片
          Column(
            children: [
              // 第一行 - 商品数量和物品数量
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 商品数量
                  Column(
                    children: [
                      Text(
                        StoreLocalizations.of(context).productQuantity,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        controller.getGoodsCount().toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // 物品数量
                  Column(
                    children: [
                      Text(
                        StoreLocalizations.of(context).itemQuantity,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        controller.getItemsCount().toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 第二行 - 我的积分和七天到期
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 我的积分
                  Column(
                    children: [
                      Text(
                        StoreLocalizations.of(context).myPoints,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        controller.currentPoints.toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  // 七天到期
                  Column(
                    children: [
                      Text(
                        StoreLocalizations.of(context).expiringIn7Days,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        controller.getExpiringItemsCount().toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget buildSettingsView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(StoreLocalizations.of(context).pointSettingsTitle),
            subtitle: Text(
              StoreLocalizations.of(context).pointSettingsSubtitle,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PointSettingsView(plugin: this),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 获取事件显示名称
  String getEventDisplayName(String eventKey) {
    switch (eventKey) {
      case 'activity_added':
        return '添加活动';
      case 'checkin_completed':
        return '完成签到';
      case 'task_completed':
        return '完成任务';
      case 'note_added':
        return '添加笔记';
      case 'goods_added':
        return '添加物品';
      case 'onMessageSent':
        return '发送消息';
      case 'onRecordAdded':
        return '添加记录';
      case 'onDiaryAdded':
        return '添加日记';
      case 'bill_added':
        return '添加账单';
      default:
        return eventKey;
    }
  }

  // ==================== JS API 定义 ====================

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 商品相关
      'getProducts': _jsGetProducts,
      'getProduct': _jsGetProduct,
      'createProduct': _jsCreateProduct,
      'updateProduct': _jsUpdateProduct,
      'deleteProduct': _jsDeleteProduct,

      // 兑换相关
      'redeem': _jsRedeem,

      // 积分相关
      'getPoints': _jsGetPoints,
      'addPoints': _jsAddPoints,

      // 历史记录
      'getRedeemHistory': _jsGetRedeemHistory,
      'getPointsHistory': _jsGetPointsHistory,

      // 用户物品
      'getUserItems': _jsGetUserItems,
      'useItem': _jsUseItem,

      // 归档管理
      'archiveProduct': _jsArchiveProduct,
      'restoreProduct': _jsRestoreProduct,
      'getArchivedProducts': _jsGetArchivedProducts,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取所有商品列表
  Future<String> _jsGetProducts() async {
    final products = controller.products;
    return jsonEncode(products.map((p) => p.toJson()).toList());
  }

  /// 获取商品详情
  Future<String> _jsGetProduct(String productId) async {
    final product = controller.products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('商品不存在: $productId'),
    );
    return jsonEncode(product.toJson());
  }

  /// 创建商品
  Future<String> _jsCreateProduct(
    String name,
    String description,
    int price,
    int stock,
    String exchangeStart,
    String exchangeEnd,
    int useDuration, [
    String? image,
  ]) async {
    final product = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      image: image ?? '',
      stock: stock,
      price: price,
      exchangeStart: DateTime.parse(exchangeStart),
      exchangeEnd: DateTime.parse(exchangeEnd),
      useDuration: useDuration,
    );

    await controller.addProduct(product);
    await controller.saveProducts();
    return jsonEncode(product.toJson());
  }

  /// 更新商品
  Future<String> _jsUpdateProduct(
    String productId,
    String name,
    String description,
    int price,
    int stock,
    String exchangeStart,
    String exchangeEnd,
    int useDuration, [
    String? image,
  ]) async {
    final products = controller.products;
    final index = products.indexWhere((p) => p.id == productId);
    if (index == -1) {
      throw Exception('商品不存在: $productId');
    }

    final updatedProduct = Product(
      id: productId,
      name: name,
      description: description,
      image: image ?? products[index].image,
      stock: stock,
      price: price,
      exchangeStart: DateTime.parse(exchangeStart),
      exchangeEnd: DateTime.parse(exchangeEnd),
      useDuration: useDuration,
    );

    products[index] = updatedProduct;
    await controller.saveProducts();
    return jsonEncode(updatedProduct.toJson());
  }

  /// 删除商品（归档）
  Future<bool> _jsDeleteProduct(String productId) async {
    final product = controller.products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('商品不存在: $productId'),
    );

    await controller.archiveProduct(product);
    return true;
  }

  /// 兑换商品
  Future<String> _jsRedeem(String productId) async {
    final product = controller.products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('商品不存在: $productId'),
    );

    final success = await controller.exchangeProduct(product);
    return jsonEncode({
      'success': success,
      'message': success ? '兑换成功' : '兑换失败（积分不足或库存不足）',
      'currentPoints': controller.currentPoints,
    });
  }

  /// 获取当前积分
  Future<int> _jsGetPoints() async {
    return controller.currentPoints;
  }

  /// 添加积分
  Future<String> _jsAddPoints(int points, String reason) async {
    await controller.addPoints(points, reason);
    return jsonEncode({
      'success': true,
      'currentPoints': controller.currentPoints,
      'message': '积分已${points > 0 ? "增加" : "减少"}: $points',
    });
  }

  /// 获取兑换历史（用户物品）
  Future<String> _jsGetRedeemHistory() async {
    final items = controller.userItems;
    return jsonEncode(items.map((item) => item.toJson()).toList());
  }

  /// 获取积分历史
  Future<String> _jsGetPointsHistory() async {
    final logs = controller.pointsLogs;
    return jsonEncode(logs.map((log) => log.toJson()).toList());
  }

  /// 获取用户物品
  Future<String> _jsGetUserItems() async {
    final items = controller.userItems;
    return jsonEncode(items.map((item) => item.toJson()).toList());
  }

  /// 使用物品
  Future<String> _jsUseItem(String itemId) async {
    final item = controller.userItems.firstWhere(
      (i) => i.id == itemId,
      orElse: () => throw Exception('物品不存在: $itemId'),
    );

    final success = await controller.useItem(item);
    return jsonEncode({
      'success': success,
      'message': success ? '使用成功' : '使用失败（物品已过期）',
    });
  }

  /// 归档商品
  Future<bool> _jsArchiveProduct(String productId) async {
    final product = controller.products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('商品不存在: $productId'),
    );

    await controller.archiveProduct(product);
    return true;
  }

  /// 恢复归档商品
  Future<bool> _jsRestoreProduct(String productId) async {
    final product = controller.archivedProducts.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('归档商品不存在: $productId'),
    );

    await controller.restoreProduct(product);
    return true;
  }

  /// 获取归档商品列表
  Future<String> _jsGetArchivedProducts() async {
    final products = controller.archivedProducts;
    return jsonEncode(products.map((p) => p.toJson()).toList());
  }
}
