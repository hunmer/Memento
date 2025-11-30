import 'dart:async';

import 'package:Memento/plugins/store/models/used_item.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/base_plugin.dart';
import 'package:Memento/core/services/plugin_widget_sync_helper.dart';
import '../models/product.dart';
import '../models/user_item.dart';
import '../models/points_log.dart';

class StoreController with ChangeNotifier {
  List<Product> _products = [];
  final List<Product> _archivedProducts = [];
  List<UserItem> _userItems = [];
  List<PointsLog> _pointsLogs = [];
  int _userPoints = 0;
  late final BasePlugin plugin;

  // 添加流控制器
  final _productsStreamController = StreamController<int>.broadcast();
  final _userItemsStreamController = StreamController<int>.broadcast();
  final _pointsStreamController = StreamController<int>.broadcast();

  // 获取流
  Stream<int> get productsStream => _productsStreamController.stream;
  Stream<int> get userItemsStream => _userItemsStreamController.stream;
  Stream<int> get pointsStream => _pointsStreamController.stream;

  StoreController([BasePlugin? plugin]) {
    if (plugin != null) {
      this.plugin = plugin;
    } else {
      final pluginInstance = PluginManager.instance.getPlugin('store_plugin');
      if (pluginInstance == null) {
        throw FlutterError('StorePlugin not registered in PluginManager');
      }
      this.plugin = pluginInstance as BasePlugin;
    }

    // 初始化流数据
    _updateStreams();
  }

  @override
  void dispose() {
    _productsStreamController.close();
    _userItemsStreamController.close();
    _pointsStreamController.close();
    super.dispose();
  }

  // 更新所有流
  void _updateStreams() {
    _productsStreamController.add(_products.length);
    _userItemsStreamController.add(_userItems.length);
    _pointsStreamController.add(_userPoints);
  }

  // 获取商品列表
  List<Product> get products => _products;

  // 获取存档商品列表
  List<Product> get archivedProducts => _archivedProducts;

  // 获取可序列化的商品列表
  List<Map<String, dynamic>> get productsJson =>
      _products.map((p) => p.toJson()).toList();

  // 获取可序列化的存档商品列表
  List<Map<String, dynamic>> get archivedProductsJson =>
      _archivedProducts.map((p) => p.toJson()).toList();

  // 获取用户物品
  List<UserItem> get userItems => _userItems;

  // 获取积分记录
  List<PointsLog> get pointsLogs => _pointsLogs;
  final List<UsedItem> _usedItems = [];
  List<UsedItem> get usedItems => _usedItems;

  // 获取用户积分
  int get userPoints => _userPoints;
  int get currentPoints => _userPoints;

  // 获取按过期时间排序的物品列表
  List<UserItem> get sortedUserItems {
    return _userItems..sort((a, b) => a.expireDate.compareTo(b.expireDate));
  }

  // 获取商品总数
  int getGoodsCount() {
    return _products.length;
  }

  // 获取用户物品总数
  int getItemsCount() {
    return _userItems.length;
  }

  // 获取七天内到期的物品数量
  int getExpiringItemsCount() {
    final now = DateTime.now();
    final sevenDaysLater = now.add(const Duration(days: 7));
    return _userItems
        .where(
          (item) =>
              item.expireDate.isAfter(now) &&
              item.expireDate.isBefore(sevenDaysLater),
        )
        .length;
  }

  // 获取今日兑换次数
  int getTodayRedeemCount() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _userItems
        .where(
          (item) =>
              item.purchaseDate.isAfter(startOfDay) &&
              item.purchaseDate.isBefore(endOfDay),
        )
        .length;
  }

  // 添加商品
  Future<void> addProduct(Product product) async {
    _products.add(product);
    _updateStreams();

    // 同步小组件数据
    await _syncWidget();
  }

  // 从JSON添加商品
  Future<void> addProductFromJson(Map<String, dynamic> json) async {
    _products.add(Product.fromJson(json));
  }

  // 兑换商品
  Future<bool> exchangeProduct(Product product) async {
    // 校验积分和库存
    if (_userPoints < product.price) return false;
    if (product.stock <= 0) return false;
    if (DateTime.now().isBefore(product.exchangeStart) ||
        DateTime.now().isAfter(product.exchangeEnd)) {
      return false;
    }

    // 执行兑换
    _userPoints -= product.price;
    final index = _products.indexOf(product);
    _products[index] = Product(
      id: product.id,
      name: product.name,
      description: product.description,
      image: product.image,
      stock: product.stock - 1,
      price: product.price,
      exchangeStart: product.exchangeStart,
      exchangeEnd: product.exchangeEnd,
      useDuration: product.useDuration,
    );

    // 添加用户物品(保存购买时的商品快照)
    final newItem = UserItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: product.id,
      remaining: 1,
      expireDate: DateTime.now().add(Duration(days: product.useDuration)),
      purchaseDate: DateTime.now(),
      purchasePrice: product.price,
      productSnapshot: product.toJson(),
    );
    _userItems.add(newItem);

    // 添加积分记录
    _pointsLogs.add(
      PointsLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: '消耗',
        value: product.price,
        reason: '兑换商品: ${product.name}',
        timestamp: DateTime.now(),
      ),
    );

    await saveProducts();
    await savePoints();
    await saveUserItems();
    _updateStreams(); // 更新badge显示
    notifyListeners(); // 通知UI更新

    // 同步小组件数据
    await _syncWidget();

    return true;
  }

  // 使用物品
  Future<bool> useItem(UserItem item) async {
    if (DateTime.now().isAfter(item.expireDate)) return false;

    // 记录使用历史
    _usedItems.add(
      UsedItem(
        id: item.id,
        productId: item.productId,
        useDate: DateTime.now(),
        productSnapshot: item.productSnapshot,
      ),
    );

    item.use();
    if (item.remaining <= 0) {
      _userItems.remove(item);
    }
    await saveProducts();
    await savePoints();
    await saveUserItems();
    _updateStreams(); // 更新badge显示
    notifyListeners(); // 通知UI更新
    return true;
  }

  // 保存已使用物品
  Future<void> saveUsedItems() async {
    await plugin.storage.write('store/used_items', {
      'items': _usedItems.map((item) => item.toJson()).toList(),
    });
  }

  // 加载已使用物品
  Future<void> loadUsedItems() async {
    final storedUsedItems = await plugin.storage.read('store/used_items');
    if (storedUsedItems is Map<String, dynamic>) {
      final itemsData = storedUsedItems['items'];
      if (itemsData is List) {
        _usedItems.clear();
        _usedItems.addAll(
          (itemsData)
              .whereType<Map<String, dynamic>>()
              .map((item) => UsedItem.fromJson(item))
              .toList(),
        );
      }
    }
  }

  // 添加积分
  Future<void> addPoints(int value, String reason) async {
    _userPoints += value;
    _pointsLogs.add(
      PointsLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: value > 0 ? '获得' : '失去',
        value: value,
        reason: reason,
        timestamp: DateTime.now(),
      ),
    );
    await savePoints();
    _updateStreams();
    notifyListeners();

    // 同步小组件数据
    await _syncWidget();
  }

  // 排序商品
  Future<void> sortProducts(String field, {bool ascending = true}) async {
    _products.sort((a, b) {
      int compareResult;
      switch (field) {
        case 'stock':
          compareResult = a.stock.compareTo(b.stock);
          break;
        case 'price':
          compareResult = a.price.compareTo(b.price);
          break;
        case 'exchangeEnd':
          compareResult = a.exchangeEnd.compareTo(b.exchangeEnd);
          break;
        default:
          compareResult = 0;
      }
      return ascending ? compareResult : -compareResult;
    });
    await saveProducts();
  }

  // 排序用户物品
  Future<void> sortUserItems(String field, {bool ascending = true}) async {
    _userItems.sort((a, b) {
      int compareResult;
      switch (field) {
        case 'remaining':
          compareResult = a.remaining.compareTo(b.remaining);
          break;
        case 'expireDate':
          compareResult = a.expireDate.compareTo(b.expireDate);
          break;
        default:
          compareResult = 0;
      }
      return ascending ? compareResult : -compareResult;
    });
    await saveUserItems();
  }

  // 存档产品
  Future<void> archiveProduct(Product product) async {
    // 从产品列表中移除
    _products.removeWhere((p) => p.id == product.id);
    // 添加到存档列表
    _archivedProducts.add(product);
    await saveProducts();
    await saveArchivedProducts();
    notifyListeners();
  }

  // 恢复存档产品
  Future<void> restoreProduct(Product product) async {
    // 从存档列表中移除
    _archivedProducts.removeWhere((p) => p.id == product.id);
    // 添加到产品列表
    _products.add(product);
    await saveProducts();
    await saveArchivedProducts();
    notifyListeners();
  }

  // 从存储加载数据
  Future<void> loadFromStorage() async {
    final storedProducts = await plugin.storage.read('store/products');
    final storedArchivedProducts = await plugin.storage.read(
      'store/archived_products',
    );
    final storedPoints = await plugin.storage.read('store/points');
    final storedUserItems = await plugin.storage.read('store/user_items');
    await loadUsedItems();

    _products.clear();
    _pointsLogs.clear();
    _userItems.clear();
    try {
      final productsData = storedProducts as Map<String, dynamic>;
      final productsList =
          productsData['products'] is List
              ? productsData['products'] as List
              : [];
      for (final productData in productsList) {
        if (productData is Map<String, dynamic>) {
          addProductFromJson(productData);
        }
      }

      // 加载存档产品
      if (storedArchivedProducts is Map<String, dynamic>) {
        final archivedList =
            storedArchivedProducts['products'] is List
                ? storedArchivedProducts['products'] as List
                : [];
        _archivedProducts.clear();
        for (final productData in archivedList) {
          if (productData is Map<String, dynamic>) {
            _archivedProducts.add(Product.fromJson(productData));
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load products: $e');
      await initializeDefaultData();
    }

    if (storedPoints is Map<String, dynamic>) {
      _userPoints =
          storedPoints['value'] is int ? storedPoints['value'] as int : 0;
      final logsData = storedPoints['logs'];
      if (logsData is List) {
        _pointsLogs =
            (logsData)
                .whereType<Map<String, dynamic>>()
                .map((log) => PointsLog.fromJson(log))
                .toList();
      }
    }

    if (storedUserItems is Map<String, dynamic>) {
      final itemsData = storedUserItems['items'];
      if (itemsData is List) {
        _userItems =
            (itemsData)
                .whereType<Map<String, dynamic>>()
                .map((item) => UserItem.fromJson(item))
                .toList();
      }
    }

    // 更新流数据
    _updateStreams();
  }

  // 保存商品数据
  Future<void> saveProducts() async {
    await plugin.storage.write('store/products', {'products': productsJson});
  }

  // 保存存档商品数据
  Future<void> saveArchivedProducts() async {
    await plugin.storage.write('store/archived_products', {
      'products': archivedProductsJson,
    });
  }

  // 保存积分数据
  Future<void> savePoints() async {
    await plugin.storage.write('store/points', {
      'value': _userPoints,
      'logs': _pointsLogs.map((log) => log.toJson()).toList(),
    });
  }

  // 保存用户物品数据
  Future<void> saveUserItems() async {
    await plugin.storage.write('store/user_items', {
      'items': _userItems.map((item) => item.toJson()).toList(),
    });
  }

  // 完整保存所有数据
  Future<void> saveToStorage() async {
    await saveProducts();
    await saveArchivedProducts();
    await savePoints();
    await saveUserItems();
    await saveUsedItems();
    _updateStreams();
  }

  // 初始化默认数据
  Future<void> initializeDefaultData() async {
    _products.clear();
    _archivedProducts.clear();
    _userPoints = 0;
    await saveToStorage();
  }

  // 清空用户物品
  Future<void> clearUserItems() async {
    _userItems.clear();
    await saveUserItems();
    _updateStreams();
    notifyListeners();
  }

  // 清空积分记录
  Future<void> clearPointsLogs() async {
    _pointsLogs.clear();
    await savePoints();
    _updateStreams();
    notifyListeners();
  }

  // 应用价格筛选
  void applyPriceFilter(double minPrice, double maxPrice) {
    _products =
        _products
            .where((p) => p.price >= minPrice && p.price <= maxPrice)
            .toList();
    notifyListeners();
  }

  // 应用筛选条件
  void applyFilters({
    String? name,
    String? priceRange,
    DateTimeRange? dateRange,
  }) {
    if (name != null && name.isNotEmpty) {
      _products =
          _products
              .where((p) => p.name.toLowerCase().contains(name.toLowerCase()))
              .toList();
    }

    if (priceRange != null && priceRange.isNotEmpty) {
      final parts = priceRange.split('-');
      if (parts.length == 2) {
        final min = int.tryParse(parts[0]);
        final max = int.tryParse(parts[1]);
        if (min != null && max != null) {
          _products =
              _products.where((p) => p.price >= min && p.price <= max).toList();
        }
      }
    }

    if (dateRange != null) {
      _products =
          _products
              .where(
                (p) =>
                    !p.exchangeEnd.isBefore(dateRange.start) &&
                    !p.exchangeStart.isAfter(dateRange.end),
              )
              .toList();
    }
    notifyListeners();
  }

  // 同步小组件数据
  Future<void> _syncWidget() async {
    await PluginWidgetSyncHelper.instance.syncStore();
  }
}
