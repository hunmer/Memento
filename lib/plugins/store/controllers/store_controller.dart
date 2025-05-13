
import 'package:Memento/plugins/store/models/used_item.dart';
import 'package:flutter/foundation.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/base_plugin.dart';
import '../models/product.dart';
import '../models/user_item.dart';
import '../models/points_log.dart';

class StoreController {
  List<Product> _products = [];
  List<UserItem> _userItems = [];
  List<PointsLog> _pointsLogs = [];
  int _userPoints = 0;
  late final BasePlugin plugin;
  
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
  }

  // 获取商品列表
  List<Product> get products => _products;

  // 获取可序列化的商品列表
  List<Map<String, dynamic>> get productsJson => 
      _products.map((p) => p.toJson()).toList();

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

  // 添加商品
  Future<void> addProduct(Product product) async {
    _products.add(product);
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
    _pointsLogs.add(PointsLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: '消耗',
      value: product.price,
      reason: '兑换商品: ${product.name}',
      timestamp: DateTime.now(),
    ));

    await saveProducts();
    await savePoints();
    await saveUserItems();
    return true;
  }

  // 使用物品
  Future<bool> useItem(UserItem item) async {
    if (DateTime.now().isAfter(item.expireDate)) return false;
    
    // 记录使用历史
    _usedItems.add(UsedItem(
      id: item.id,
      productId: item.productId,
      useDate: DateTime.now(),
      productSnapshot: item.productSnapshot,
    ));
    
    item.use();
    if (item.remaining <= 0) {
      _userItems.remove(item);
    }
    await saveUserItems();
    await saveUsedItems();
    return true;
  }

  // 保存已使用物品
  Future<void> saveUsedItems() async {
    await plugin.storage.write('store/used_items', {
      'items': _usedItems.map((item) => item.toJson()).toList()
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
          (itemsData as List).whereType<Map<String, dynamic>>()
            .map((item) => UsedItem.fromJson(item))
            .toList()
        );
      }
    }
  }

  // 添加积分
  Future<void> addPoints(int value, String reason) async {
    _userPoints += value;
    _pointsLogs.add(PointsLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: '获得',
      value: value,
      reason: reason,
      timestamp: DateTime.now(),
    ));
    await savePoints();
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

  // 从存储加载数据
  Future<void> loadFromStorage() async {
    final storedProducts = await plugin.storage.read('store/products');
    final storedPoints = await plugin.storage.read('store/points');
    final storedUserItems = await plugin.storage.read('store/user_items');
    await loadUsedItems();
    try {
      final productsData = storedProducts as Map<String, dynamic>;
      final productsList = productsData['products'] is List 
          ? productsData['products'] as List 
          : [];
      for (final productData in productsList) {
        if (productData is Map<String, dynamic>) {
          addProductFromJson(productData);
        }
      }
    } catch (e) {
      debugPrint('Failed to load products: $e');
      await initializeDefaultData();
    }

    if (storedPoints is Map<String, dynamic>) {
        _userPoints = storedPoints['value'] is int 
            ? storedPoints['value'] as int 
            : 2000;
        final logsData = storedPoints['logs'];
        if (logsData is List) {
          _pointsLogs = (logsData as List).whereType<Map<String, dynamic>>().map((log) => PointsLog.fromJson(log)).toList();
        }
    }

    if (storedUserItems is Map<String, dynamic>) {
      final itemsData = storedUserItems['items'];
      if (itemsData is List) {
        _userItems = (itemsData as List).whereType<Map<String, dynamic>>().map((item) => UserItem.fromJson(item)).toList();
      }
    }
  }

  // 保存商品数据
  Future<void> saveProducts() async {
    await plugin.storage.write('store/products', {'products': productsJson});
  }

  // 保存积分数据
  Future<void> savePoints() async {
    await plugin.storage.write('store/points', {
      'value': _userPoints,
      'logs': _pointsLogs.map((log) => log.toJson()).toList()
    });
  }

  // 保存用户物品数据
  Future<void> saveUserItems() async {
    await plugin.storage.write('store/user_items', {
      'items': _userItems.map((item) => item.toJson()).toList()
    });
  }

  // 完整保存所有数据
  Future<void> saveToStorage() async {
    await saveProducts();
    await savePoints();
    await saveUserItems();
    await saveUsedItems();
  }

  // 初始化默认数据
  Future<void> initializeDefaultData() async {
    _products.clear();
    _userPoints = 0;
    await saveToStorage();
  }

  // 清空用户物品
  Future<void> clearUserItems() async {
    _userItems.clear();
    await saveUserItems();
  }
}
