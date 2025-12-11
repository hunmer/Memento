/// Store 插件 - 服务端 Repository 实现

import 'package:shared_models/shared_models.dart';
import '../services/plugin_data_service.dart';

class ServerStoreRepository implements IStoreRepository {
  final PluginDataService dataService;
  final String userId;

  static const String _pluginId = 'store';

  ServerStoreRepository({
    required this.dataService,
    required this.userId,
  });

  // ============ 内部方法 ============

  Future<List<ProductDto>> _readAllProducts() async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      'products.json',
    );
    if (data == null) return [];

    final products = data['products'] as List<dynamic>? ?? [];
    return products
        .map((e) => ProductDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAllProducts(List<ProductDto> products) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'products.json',
      {'products': products.map((p) => p.toJson()).toList()},
    );
  }

  Future<List<ProductDto>> _readAllArchivedProducts() async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      'archived_products.json',
    );
    if (data == null) return [];

    final products = data['products'] as List<dynamic>? ?? [];
    return products
        .map((e) => ProductDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAllArchivedProducts(List<ProductDto> products) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'archived_products.json',
      {'products': products.map((p) => p.toJson()).toList()},
    );
  }

  Future<PointsInfoDto> _readPointsInfo() async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      'points.json',
    );
    if (data == null) {
      return const PointsInfoDto(currentPoints: 0);
    }

    return PointsInfoDto.fromJson(data);
  }

  Future<void> _savePointsInfo(PointsInfoDto info) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'points.json',
      info.toJson(),
    );
  }

  Future<List<UserItemDto>> _readAllUserItems() async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      'user_items.json',
    );
    if (data == null) return [];

    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => UserItemDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAllUserItems(List<UserItemDto> items) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'user_items.json',
      {'items': items.map((i) => i.toJson()).toList()},
    );
  }

  Future<List<UsedItemDto>> _readAllUsedItems() async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      'used_items.json',
    );
    if (data == null) return [];

    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => UsedItemDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAllUsedItems(List<UsedItemDto> items) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'used_items.json',
      {'items': items.map((i) => i.toJson()).toList()},
    );
  }

  // ============ 商品操作实现 ============

  @override
  Future<Result<List<ProductDto>>> getProducts(
      {PaginationParams? pagination}) async {
    try {
      var products = await _readAllProducts();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          products,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(products);
    } catch (e) {
      return Result.failure('获取商品列表失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ProductDto?>> getProductById(String id) async {
    try {
      final products = await _readAllProducts();
      final product = products.where((p) => p.id == id).firstOrNull;
      return Result.success(product);
    } catch (e) {
      return Result.failure('获取商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ProductDto>> createProduct(ProductDto product) async {
    try {
      final products = await _readAllProducts();
      products.add(product);
      await _saveAllProducts(products);
      return Result.success(product);
    } catch (e) {
      return Result.failure('创建商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ProductDto>> updateProduct(
      String id, ProductDto product) async {
    try {
      final products = await _readAllProducts();
      final index = products.indexWhere((p) => p.id == id);

      if (index == -1) {
        return Result.failure('商品不存在', code: ErrorCodes.notFound);
      }

      products[index] = product;
      await _saveAllProducts(products);
      return Result.success(product);
    } catch (e) {
      return Result.failure('更新商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteProduct(String id) async {
    try {
      final products = await _readAllProducts();
      final initialLength = products.length;
      products.removeWhere((p) => p.id == id);

      if (products.length == initialLength) {
        return Result.failure('商品不存在', code: ErrorCodes.notFound);
      }

      await _saveAllProducts(products);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> archiveProduct(String id) async {
    try {
      final products = await _readAllProducts();
      final archivedProducts = await _readAllArchivedProducts();

      final product = products.where((p) => p.id == id).firstOrNull;
      if (product == null) {
        return Result.failure('商品不存在', code: ErrorCodes.notFound);
      }

      products.removeWhere((p) => p.id == id);
      archivedProducts.add(product);

      await _saveAllProducts(products);
      await _saveAllArchivedProducts(archivedProducts);

      return Result.success(true);
    } catch (e) {
      return Result.failure('归档商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> restoreProduct(String id) async {
    try {
      final products = await _readAllProducts();
      final archivedProducts = await _readAllArchivedProducts();

      final product =
          archivedProducts.where((p) => p.id == id).firstOrNull;
      if (product == null) {
        return Result.failure('归档商品不存在', code: ErrorCodes.notFound);
      }

      archivedProducts.removeWhere((p) => p.id == id);
      products.add(product);

      await _saveAllProducts(products);
      await _saveAllArchivedProducts(archivedProducts);

      return Result.success(true);
    } catch (e) {
      return Result.failure('恢复商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<ProductDto>>> getArchivedProducts(
      {PaginationParams? pagination}) async {
    try {
      var products = await _readAllArchivedProducts();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          products,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(products);
    } catch (e) {
      return Result.failure('获取归档商品失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<ProductDto>>> searchProducts(ProductQuery query) async {
    try {
      var products = await _readAllProducts();

      if (query.nameKeyword != null) {
        products = products.where((product) {
          return product.name.toLowerCase().contains(
            query.nameKeyword!.toLowerCase(),
          );
        }).toList();
      }

      if (query.minPrice != null) {
        products = products.where((p) => p.price >= query.minPrice!).toList();
      }

      if (query.maxPrice != null) {
        products = products.where((p) => p.price <= query.maxPrice!).toList();
      }

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          products,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(products);
    } catch (e) {
      return Result.failure('搜索商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 积分操作实现 ============

  @override
  Future<Result<PointsInfoDto>> getPointsInfo(
      {PaginationParams? pagination}) async {
    try {
      final info = await _readPointsInfo();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          info.logs,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(
          info.copyWith(logs: paginated.data),
        );
      }

      return Result.success(info);
    } catch (e) {
      return Result.failure('获取积分信息失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<PointsInfoDto>> addPoints(int value, String reason) async {
    try {
      final info = await _readPointsInfo();
      final newPoints = info.currentPoints + value;

      // 添加积分记录
      final newLog = PointsLogDto(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: value > 0 ? '获得' : '消耗',
        value: value,
        reason: reason,
        timestamp: DateTime.now(),
      );

      final updatedLogs = List<PointsLogDto>.from(info.logs)..add(newLog);
      final updatedInfo = info.copyWith(
        currentPoints: newPoints,
        logs: updatedLogs,
      );

      await _savePointsInfo(updatedInfo);
      return Result.success(updatedInfo);
    } catch (e) {
      return Result.failure('添加积分失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> clearPointsLogs() async {
    try {
      final info = await _readPointsInfo();
      final updatedInfo = info.copyWith(logs: const []);
      await _savePointsInfo(updatedInfo);
      return Result.success(true);
    } catch (e) {
      return Result.failure('清空积分记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<PointsLogDto>>> searchPointsLogs(
      PointsLogQuery query) async {
    try {
      final info = await _readPointsInfo();
      var logs = info.logs;

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          logs,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(logs);
    } catch (e) {
      return Result.failure('搜索积分记录失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  // ============ 用户物品操作实现 ============

  @override
  Future<Result<List<UserItemDto>>> getUserItems(
      {PaginationParams? pagination}) async {
    try {
      var items = await _readAllUserItems();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          items,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(items);
    } catch (e) {
      return Result.failure('获取用户物品失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<UserItemDto?>> getUserItemById(String id) async {
    try {
      final items = await _readAllUserItems();
      final item = items.where((i) => i.id == id).firstOrNull;
      return Result.success(item);
    } catch (e) {
      return Result.failure('获取用户物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<UserItemDto>> exchangeProduct(String productId) async {
    try {
      // 获取商品信息
      final products = await _readAllProducts();
      final product = products.where((p) => p.id == productId).firstOrNull;
      if (product == null) {
        return Result.failure('商品不存在', code: ErrorCodes.notFound);
      }

      // 检查库存
      if (product.stock <= 0) {
        return Result.failure('商品库存不足', code: ErrorCodes.validationError);
      }

      // 检查兑换时间
      final now = DateTime.now();
      if (now.isBefore(product.exchangeStart) ||
          now.isAfter(product.exchangeEnd)) {
        return Result.failure('不在兑换时间内', code: ErrorCodes.validationError);
      }

      // 获取积分信息
      final pointsInfo = await _readPointsInfo();
      if (pointsInfo.currentPoints < product.price) {
        return Result.failure('积分不足', code: ErrorCodes.validationError);
      }

      // 扣除积分
      final updatedPointsInfo = pointsInfo.copyWith(
        currentPoints: pointsInfo.currentPoints - product.price,
      );
      await _savePointsInfo(updatedPointsInfo);

      // 减少库存
      final updatedProduct = product.copyWith(stock: product.stock - 1);
      final productIndex = products.indexWhere((p) => p.id == productId);
      if (productIndex != -1) {
        products[productIndex] = updatedProduct;
        await _saveAllProducts(products);
      }

      // 创建用户物品
      final newItem = UserItemDto(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: productId,
        remaining: 1,
        expireDate: now.add(Duration(days: product.useDuration)),
        purchaseDate: now,
        purchasePrice: product.price,
        productSnapshot: product.toJson(),
      );

      final items = await _readAllUserItems();
      items.add(newItem);
      await _saveAllUserItems(items);

      return Result.success(newItem);
    } catch (e) {
      return Result.failure('兑换商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<UserItemDto>> useItem(String itemId) async {
    try {
      final items = await _readAllUserItems();
      final item = items.where((i) => i.id == itemId).firstOrNull;
      if (item == null) {
        return Result.failure('用户物品不存在', code: ErrorCodes.notFound);
      }

      // 检查是否过期
      if (DateTime.now().isAfter(item.expireDate)) {
        return Result.failure('物品已过期', code: ErrorCodes.validationError);
      }

      // 使用物品
      final usedItem = UsedItemDto(
        id: item.id,
        productId: item.productId,
        useDate: DateTime.now(),
        productSnapshot: item.productSnapshot,
      );

      // 保存已使用物品
      final usedItems = await _readAllUsedItems();
      usedItems.add(usedItem);
      await _saveAllUsedItems(usedItems);

      // 减少剩余次数
      final updatedItem = item.copyWith(remaining: item.remaining - 1);

      // 如果次数用完，移除物品
      if (updatedItem.remaining <= 0) {
        items.removeWhere((i) => i.id == itemId);
      } else {
        final index = items.indexWhere((i) => i.id == itemId);
        if (index != -1) {
          items[index] = updatedItem;
        }
      }

      await _saveAllUserItems(items);

      return Result.success(updatedItem.remaining > 0 ? updatedItem : item);
    } catch (e) {
      return Result.failure('使用物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> clearUserItems() async {
    try {
      await dataService.writePluginData(
        userId,
        _pluginId,
        'user_items.json',
        {'items': []},
      );
      return Result.success(true);
    } catch (e) {
      return Result.failure('清空用户物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<UserItemDto>>> searchUserItems(
      UserItemQuery query) async {
    try {
      var items = await _readAllUserItems();

      if (query.productId != null) {
        items = items.where((item) => item.productId == query.productId!).toList();
      }

      if (query.includeExpired == false) {
        final now = DateTime.now();
        items = items.where((item) => item.expireDate.isAfter(now)).toList();
      }

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          items,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(items);
    } catch (e) {
      return Result.failure('搜索用户物品失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  // ============ 已使用物品操作实现 ============

  @override
  Future<Result<List<UsedItemDto>>> getUsedItems(
      {PaginationParams? pagination}) async {
    try {
      var items = await _readAllUsedItems();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          items,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(items);
    } catch (e) {
      return Result.failure('获取已使用物品失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  // ============ 统计查询实现 ============

  @override
  Future<Result<int>> getProductsCount() async {
    try {
      final products = await _readAllProducts();
      return Result.success(products.length);
    } catch (e) {
      return Result.failure('获取商品总数失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<int>> getUserItemsCount() async {
    try {
      final items = await _readAllUserItems();
      return Result.success(items.length);
    } catch (e) {
      return Result.failure('获取用户物品总数失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<int>> getExpiringItemsCount() async {
    try {
      final items = await _readAllUserItems();
      final now = DateTime.now();
      final sevenDaysLater = now.add(const Duration(days: 7));

      final count = items
          .where((item) =>
              item.expireDate.isAfter(now) &&
              item.expireDate.isBefore(sevenDaysLater))
          .length;

      return Result.success(count);
    } catch (e) {
      return Result.failure('获取到期物品数量失败: $e',
          code: ErrorCodes.serverError);
    }
  }
}
