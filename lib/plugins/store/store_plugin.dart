import 'package:get/get.dart';
import 'dart:convert';
import 'package:Memento/plugins/store/widgets/store_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/base_plugin.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/plugins/store/controllers/store_controller.dart';
import 'package:Memento/plugins/store/widgets/point_settings_view.dart';
import 'package:Memento/plugins/store/models/product.dart';
import 'package:Memento/plugins/store/events/point_award_event.dart';

/// 物品兑换插件
class StorePlugin extends BasePlugin with JSBridgePlugin {
  static StorePlugin? _instance;
  static StorePlugin get instance {
    if (_instance == null) {
      _instance = PluginManager.instance.getPlugin('store') as StorePlugin?;
      if (_instance == null) {
        throw StateError('StorePlugin has not been initialized');
      }
    }
    return _instance!;
  }

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
    // 插件已在 initialize() 中完成初始化
    // 这里可以添加额外的应用级注册逻辑
  }

  StoreController? _controller;
  PointAwardEvent? _pointAwardEvent;
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
      _pointAwardEvent = PointAwardEvent(this);

      _isInitialized = true;

      // 注册 JS API（最后一步）
      await registerJSAPI();
    }
  }

  /// 清理资源
  void dispose() {
    // 清理事件订阅
    _pointAwardEvent?.dispose();
    _pointAwardEvent = null;
  }

  @override
  String? getPluginName(context) {
    return 'store_name'.tr;
  }

  @override
  Widget buildMainView(BuildContext context) {
    return StoreBottomBar(plugin: this);
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
                'store_name'.tr,
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
                        'store_productQuantity'.tr,
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
                        'store_itemQuantity'.tr,
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
                        'store_myPoints'.tr,
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
                        'store_expiringIn7Days'.tr,
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
            title: Text('store_pointSettingsTitle'.tr),
            subtitle: Text(
              'store_pointSettingsSubtitle'.tr,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              NavigationHelper.push(context, PointSettingsView(plugin: this),
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

      // 查找方法
      'findProductBy': _jsFindProductBy,
      'findProductById': _jsFindProductById,
      'findProductByName': _jsFindProductByName,
      'findUserItemBy': _jsFindUserItemBy,
      'findUserItemById': _jsFindUserItemById,
    };
  }

  // ==================== 分页控制器 ====================

  /// 分页控制器 - 对列表进行分页处理
  /// @param list 原始数据列表
  /// @param offset 起始位置（默认 0）
  /// @param count 返回数量（默认 100）
  /// @return 分页后的数据，包含 data、total、offset、count、hasMore
  Map<String, dynamic> _paginate<T>(
    List<T> list, {
    int offset = 0,
    int count = 100,
  }) {
    final total = list.length;
    final start = offset.clamp(0, total);
    final end = (start + count).clamp(start, total);
    final data = list.sublist(start, end);

    return {
      'data': data,
      'total': total,
      'offset': start,
      'count': data.length,
      'hasMore': end < total,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取所有商品列表
  /// 支持分页参数: offset, count
  Future<String> _jsGetProducts(Map<String, dynamic> params) async {
    final products = controller.products;
    final productsJson = products.map((p) => p.toJson()).toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        productsJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    // 兼容旧版本：无分页参数时返回全部数据
    return jsonEncode(productsJson);
  }

  /// 获取商品详情
  Future<String> _jsGetProduct(Map<String, dynamic> params) async {
    final String? productId = params['productId'];
    if (productId == null || productId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: productId'});
    }

    final product = controller.products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('商品不存在: $productId'),
    );
    return jsonEncode(product.toJson());
  }

  /// 创建商品
  Future<String> _jsCreateProduct(Map<String, dynamic> params) async {
    // 提取必需参数
    final String? name = params['name'];
    if (name == null || name.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: name'});
    }

    final String? description = params['description'];
    if (description == null || description.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: description'});
    }

    final int? price = params['price'];
    if (price == null) {
      return jsonEncode({'error': '缺少必需参数: price'});
    }

    final int? stock = params['stock'];
    if (stock == null) {
      return jsonEncode({'error': '缺少必需参数: stock'});
    }

    final String? exchangeStart = params['exchangeStart'];
    if (exchangeStart == null || exchangeStart.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: exchangeStart'});
    }

    final String? exchangeEnd = params['exchangeEnd'];
    if (exchangeEnd == null || exchangeEnd.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: exchangeEnd'});
    }

    final int? useDuration = params['useDuration'];
    if (useDuration == null) {
      return jsonEncode({'error': '缺少必需参数: useDuration'});
    }

    // 提取可选参数
    final String? image = params['image'];
    final String? customId = params['id'];

    // 使用自定义ID或生成新ID
    final String productId = customId != null && customId.isNotEmpty
        ? customId
        : const Uuid().v4();

    final product = Product(
      id: productId,
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
  Future<String> _jsUpdateProduct(Map<String, dynamic> params) async {
    // 提取必需参数
    final String? productId = params['productId'];
    if (productId == null || productId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: productId'});
    }

    final String? name = params['name'];
    if (name == null || name.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: name'});
    }

    final String? description = params['description'];
    if (description == null || description.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: description'});
    }

    final int? price = params['price'];
    if (price == null) {
      return jsonEncode({'error': '缺少必需参数: price'});
    }

    final int? stock = params['stock'];
    if (stock == null) {
      return jsonEncode({'error': '缺少必需参数: stock'});
    }

    final String? exchangeStart = params['exchangeStart'];
    if (exchangeStart == null || exchangeStart.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: exchangeStart'});
    }

    final String? exchangeEnd = params['exchangeEnd'];
    if (exchangeEnd == null || exchangeEnd.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: exchangeEnd'});
    }

    final int? useDuration = params['useDuration'];
    if (useDuration == null) {
      return jsonEncode({'error': '缺少必需参数: useDuration'});
    }

    // 提取可选参数
    final String? image = params['image'];

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
  Future<String> _jsDeleteProduct(Map<String, dynamic> params) async {
    try {
      final String? productId = params['productId'];
      if (productId == null || productId.isEmpty) {
        return jsonEncode({'success': false, 'error': '缺少必需参数: productId'});
      }

      final product = controller.products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('商品不存在: $productId'),
      );

      await controller.archiveProduct(product);
      return jsonEncode({'success': true, 'productId': productId});
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// 兑换商品
  Future<String> _jsRedeem(Map<String, dynamic> params) async {
    final String? productId = params['productId'];
    if (productId == null || productId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: productId'});
    }

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
  Future<int> _jsGetPoints(Map<String, dynamic> params) async {
    return controller.currentPoints;
  }

  /// 添加积分
  Future<String> _jsAddPoints(Map<String, dynamic> params) async {
    final int? points = params['points'];
    if (points == null) {
      return jsonEncode({'error': '缺少必需参数: points'});
    }

    final String? reason = params['reason'];
    if (reason == null || reason.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: reason'});
    }

    await controller.addPoints(points, reason);
    return jsonEncode({
      'success': true,
      'currentPoints': controller.currentPoints,
      'message': '积分已${points > 0 ? "增加" : "减少"}: $points',
    });
  }

  /// 获取兑换历史（用户物品）
  /// 支持分页参数: offset, count
  Future<String> _jsGetRedeemHistory(Map<String, dynamic> params) async {
    final items = controller.userItems;
    final itemsJson = items.map((item) => item.toJson()).toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        itemsJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    // 兼容旧版本：无分页参数时返回全部数据
    return jsonEncode(itemsJson);
  }

  /// 获取积分历史
  /// 支持分页参数: offset, count
  Future<String> _jsGetPointsHistory(Map<String, dynamic> params) async {
    final logs = controller.pointsLogs;
    final logsJson = logs.map((log) => log.toJson()).toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        logsJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    // 兼容旧版本：无分页参数时返回全部数据
    return jsonEncode(logsJson);
  }

  /// 获取用户物品
  /// 支持分页参数: offset, count
  Future<String> _jsGetUserItems(Map<String, dynamic> params) async {
    final items = controller.userItems;
    final itemsJson = items.map((item) => item.toJson()).toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        itemsJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    // 兼容旧版本：无分页参数时返回全部数据
    return jsonEncode(itemsJson);
  }

  /// 使用物品
  Future<String> _jsUseItem(Map<String, dynamic> params) async {
    final String? itemId = params['itemId'];
    if (itemId == null || itemId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: itemId'});
    }

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
  Future<String> _jsArchiveProduct(Map<String, dynamic> params) async {
    try {
      final String? productId = params['productId'];
      if (productId == null || productId.isEmpty) {
        return jsonEncode({'success': false, 'error': '缺少必需参数: productId'});
      }

      final product = controller.products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('商品不存在: $productId'),
      );

      await controller.archiveProduct(product);
      return jsonEncode({'success': true, 'productId': productId});
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// 恢复归档商品
  Future<String> _jsRestoreProduct(Map<String, dynamic> params) async {
    try {
      final String? productId = params['productId'];
      if (productId == null || productId.isEmpty) {
        return jsonEncode({'success': false, 'error': '缺少必需参数: productId'});
      }

      final product = controller.archivedProducts.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('归档商品不存在: $productId'),
      );

      await controller.restoreProduct(product);
      return jsonEncode({'success': true, 'productId': productId});
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// 获取归档商品列表
  /// 支持分页参数: offset, count
  Future<String> _jsGetArchivedProducts(Map<String, dynamic> params) async {
    final products = controller.archivedProducts;
    final productsJson = products.map((p) => p.toJson()).toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        productsJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    // 兼容旧版本：无分页参数时返回全部数据
    return jsonEncode(productsJson);
  }

  // ==================== 查找方法 ====================

  /// 通用商品查找
  /// 支持分页参数: offset, count（仅 findAll=true 时有效）
  Future<String> _jsFindProductBy(Map<String, dynamic> params) async {
    final String? field = params['field'];
    if (field == null || field.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: field'});
    }

    final dynamic value = params['value'];
    if (value == null) {
      return jsonEncode({'error': '缺少必需参数: value'});
    }

    final bool findAll = params['findAll'] ?? false;
    final int? offset = params['offset'];
    final int? count = params['count'];

    final products = controller.products;
    final matches = <Product>[];

    for (var product in products) {
      bool isMatch = false;

      switch (field.toLowerCase()) {
        case 'id':
          isMatch = product.id == value;
          break;
        case 'name':
          isMatch = product.name == value;
          break;
        default:
          isMatch = false;
      }

      if (isMatch) {
        if (!findAll) {
          return jsonEncode(product.toJson());
        }
        matches.add(product);
      }
    }

    if (findAll) {
      final matchesJson = matches.map((p) => p.toJson()).toList();

      // 检查是否需要分页
      if (offset != null || count != null) {
        final paginated = _paginate(
          matchesJson,
          offset: offset ?? 0,
          count: count ?? 100,
        );
        return jsonEncode(paginated);
      }

      return jsonEncode(matchesJson);
    }

    return jsonEncode(null);
  }

  /// 根据ID查找商品
  Future<String> _jsFindProductById(Map<String, dynamic> params) async {
    final String? id = params['id'];
    if (id == null || id.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: id'});
    }

    try {
      final product = controller.products.firstWhere(
        (p) => p.id == id,
        orElse: () => throw Exception('商品不存在'),
      );
      return jsonEncode(product.toJson());
    } catch (e) {
      return jsonEncode(null);
    }
  }

  /// 根据名称查找商品
  /// 支持分页参数: offset, count（仅 findAll=true 时有效）
  Future<String> _jsFindProductByName(Map<String, dynamic> params) async {
    final String? name = params['name'];
    if (name == null || name.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: name'});
    }

    final bool fuzzy = params['fuzzy'] ?? false;
    final bool findAll = params['findAll'] ?? false;
    final int? offset = params['offset'];
    final int? count = params['count'];

    final products = controller.products;
    final matches = <Product>[];

    for (var product in products) {
      final isMatch = fuzzy
          ? product.name.toLowerCase().contains(name.toLowerCase())
          : product.name == name;

      if (isMatch) {
        if (!findAll) {
          return jsonEncode(product.toJson());
        }
        matches.add(product);
      }
    }

    if (findAll) {
      final matchesJson = matches.map((p) => p.toJson()).toList();

      // 检查是否需要分页
      if (offset != null || count != null) {
        final paginated = _paginate(
          matchesJson,
          offset: offset ?? 0,
          count: count ?? 100,
        );
        return jsonEncode(paginated);
      }

      return jsonEncode(matchesJson);
    }

    return jsonEncode(null);
  }

  /// 通用用户物品查找
  /// 支持分页参数: offset, count（仅 findAll=true 时有效）
  Future<String> _jsFindUserItemBy(Map<String, dynamic> params) async {
    final String? field = params['field'];
    if (field == null || field.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: field'});
    }

    final dynamic value = params['value'];
    if (value == null) {
      return jsonEncode({'error': '缺少必需参数: value'});
    }

    final bool findAll = params['findAll'] ?? false;
    final int? offset = params['offset'];
    final int? count = params['count'];

    final items = controller.userItems;
    final matches = [];

    for (var item in items) {
      bool isMatch = false;

      switch (field.toLowerCase()) {
        case 'id':
          isMatch = item.id == value;
          break;
        case 'productid':
          isMatch = item.productId == value;
          break;
        default:
          isMatch = false;
      }

      if (isMatch) {
        if (!findAll) {
          return jsonEncode(item.toJson());
        }
        matches.add(item);
      }
    }

    if (findAll) {
      final matchesJson = matches.map((i) => i.toJson()).toList();

      // 检查是否需要分页
      if (offset != null || count != null) {
        final paginated = _paginate(
          matchesJson,
          offset: offset ?? 0,
          count: count ?? 100,
        );
        return jsonEncode(paginated);
      }

      return jsonEncode(matchesJson);
    }

    return jsonEncode(null);
  }

  /// 根据ID查找用户物品
  Future<String> _jsFindUserItemById(Map<String, dynamic> params) async {
    final String? id = params['id'];
    if (id == null || id.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: id'});
    }

    try {
      final item = controller.userItems.firstWhere(
        (i) => i.id == id,
        orElse: () => throw Exception('物品不存在'),
      );
      return jsonEncode(item.toJson());
    } catch (e) {
      return jsonEncode(null);
    }
  }
}
