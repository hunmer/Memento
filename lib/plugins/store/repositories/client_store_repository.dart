// Store 插件 - 客户端 Repository 实现
// 通过适配现有的 StoreController 来实现 IStoreRepository 接口

import 'package:shared_models/shared_models.dart';
import 'package:Memento/plugins/store/controllers/store_controller.dart';
import 'package:Memento/plugins/store/models/product.dart';
import 'package:Memento/plugins/store/models/user_item.dart';
import 'package:Memento/plugins/store/models/points_log.dart';
import 'package:Memento/plugins/store/models/used_item.dart';

/// 客户端 Store Repository 实现
class ClientStoreRepository implements IStoreRepository {
  final StoreController controller;

  ClientStoreRepository({
    required this.controller,
  });

  // ============ 商品操作 ============

  @override
  Future<Result<List<ProductDto>>> getProducts({
    PaginationParams? pagination,
  }) async {
    try {
      final products = controller.products;
      final dtos = products.map(_productToDto).toList();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('获取商品列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ProductDto?>> getProductById(String id) async {
    try {
      final product = controller.products.where((p) => p.id == id).firstOrNull;
      if (product == null) {
        return Result.success(null);
      }
      return Result.success(_productToDto(product));
    } catch (e) {
      return Result.failure('获取商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ProductDto>> createProduct(ProductDto dto) async {
    try {
      final product = Product(
        id: dto.id,
        name: dto.name,
        description: dto.description,
        image: dto.image,
        stock: dto.stock,
        price: dto.price,
        exchangeStart: dto.exchangeStart,
        exchangeEnd: dto.exchangeEnd,
        useDuration: dto.useDuration,
      );

      await controller.addProduct(product);
      return Result.success(_productToDto(product));
    } catch (e) {
      return Result.failure('创建商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ProductDto>> updateProduct(String id, ProductDto dto) async {
    try {
      // 获取现有商品
      final existingProduct = controller.products.where((p) => p.id == id).firstOrNull;
      if (existingProduct == null) {
        return Result.failure('商品不存在', code: ErrorCodes.notFound);
      }

      // 更新商品（使用新的 Product 对象替换旧的）
      final updated = Product(
        id: dto.id,
        name: dto.name,
        description: dto.description,
        image: dto.image,
        stock: dto.stock,
        price: dto.price,
        exchangeStart: dto.exchangeStart,
        exchangeEnd: dto.exchangeEnd,
        useDuration: dto.useDuration,
      );

      // 从列表中移除旧商品，添加新商品
      final index = controller.products.indexOf(existingProduct);
      controller.products.removeAt(index);
      controller.products.insert(index, updated);

      await controller.saveProducts();
      return Result.success(_productToDto(updated));
    } catch (e) {
      return Result.failure('更新商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteProduct(String id) async {
    try {
      final product = controller.products.where((p) => p.id == id).firstOrNull;
      if (product == null) {
        return Result.failure('商品不存在', code: ErrorCodes.notFound);
      }

      await controller.archiveProduct(product);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> archiveProduct(String id) async {
    try {
      final product = controller.products.where((p) => p.id == id).firstOrNull;
      if (product == null) {
        return Result.failure('商品不存在', code: ErrorCodes.notFound);
      }

      await controller.archiveProduct(product);
      return Result.success(true);
    } catch (e) {
      return Result.failure('归档商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> restoreProduct(String id) async {
    try {
      final product = controller.archivedProducts.where((p) => p.id == id).firstOrNull;
      if (product == null) {
        return Result.failure('归档商品不存在', code: ErrorCodes.notFound);
      }

      await controller.restoreProduct(product);
      return Result.success(true);
    } catch (e) {
      return Result.failure('恢复商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<ProductDto>>> getArchivedProducts({
    PaginationParams? pagination,
  }) async {
    try {
      final products = controller.archivedProducts;
      final dtos = products.map(_productToDto).toList();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('获取归档商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<ProductDto>>> searchProducts(ProductQuery query) async {
    try {
      var products = controller.products;

      // 按名称关键字筛选
      if (query.nameKeyword != null && query.nameKeyword!.isNotEmpty) {
        final keyword = query.nameKeyword!.toLowerCase();
        products = products.where((p) => p.name.toLowerCase().contains(keyword)).toList();
      }

      // 按价格范围筛选
      if (query.minPrice != null) {
        products = products.where((p) => p.price >= query.minPrice!).toList();
      }
      if (query.maxPrice != null) {
        products = products.where((p) => p.price <= query.maxPrice!).toList();
      }

      // 是否包含归档商品
      if (query.includeArchived == true) {
        products = [...products, ...controller.archivedProducts];
      }

      final dtos = products.map(_productToDto).toList();

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('搜索商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 积分操作 ============

  @override
  Future<Result<PointsInfoDto>> getPointsInfo({
    PaginationParams? pagination,
  }) async {
    try {
      final logs = controller.pointsLogs;
      final info = PointsInfoDto(
        currentPoints: controller.currentPoints,
        logs: logs.map(_pointsLogToDto).toList(),
      );

      if (pagination != null && pagination.hasPagination) {
        final paginatedLogs = PaginationUtils.paginate(
          info.logs,
          offset: pagination.offset,
          count: pagination.count,
        );
        final result = PointsInfoDto(
          currentPoints: info.currentPoints,
          logs: paginatedLogs.data,
        );
        return Result.success(result);
      }

      return Result.success(info);
    } catch (e) {
      return Result.failure('获取积分信息失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<PointsInfoDto>> addPoints(int value, String reason) async {
    try {
      await controller.addPoints(value, reason);
      final info = PointsInfoDto(
        currentPoints: controller.currentPoints,
        logs: controller.pointsLogs.map(_pointsLogToDto).toList(),
      );
      return Result.success(info);
    } catch (e) {
      return Result.failure('添加积分失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> clearPointsLogs() async {
    try {
      await controller.clearPointsLogs();
      return Result.success(true);
    } catch (e) {
      return Result.failure('清空积分记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<PointsLogDto>>> searchPointsLogs(PointsLogQuery query) async {
    try {
      final logs = controller.pointsLogs;
      final dtos = logs.map(_pointsLogToDto).toList();

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('搜索积分记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 用户物品操作 ============

  @override
  Future<Result<List<UserItemDto>>> getUserItems({
    PaginationParams? pagination,
  }) async {
    try {
      final items = controller.userItems;
      final dtos = items.map(_userItemToDto).toList();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('获取用户物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<UserItemDto?>> getUserItemById(String id) async {
    try {
      final item = controller.userItems.where((i) => i.id == id).firstOrNull;
      if (item == null) {
        return Result.success(null);
      }
      return Result.success(_userItemToDto(item));
    } catch (e) {
      return Result.failure('获取用户物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<UserItemDto>> exchangeProduct(String productId) async {
    try {
      final product = controller.products.where((p) => p.id == productId).firstOrNull;
      if (product == null) {
        return Result.failure('商品不存在', code: ErrorCodes.notFound);
      }

      final success = await controller.exchangeProduct(product);
      if (!success) {
        return Result.failure('兑换失败（积分不足或库存不足）', code: ErrorCodes.invalidParams);
      }

      // 获取新创建的用户物品
      final newItem = controller.userItems.last;
      return Result.success(_userItemToDto(newItem));
    } catch (e) {
      return Result.failure('兑换商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<UserItemDto>> useItem(String itemId) async {
    try {
      final item = controller.userItems.where((i) => i.id == itemId).firstOrNull;
      if (item == null) {
        return Result.failure('用户物品不存在', code: ErrorCodes.notFound);
      }

      final success = await controller.useItem(item);
      if (!success) {
        return Result.failure('使用失败（物品已过期）', code: ErrorCodes.invalidParams);
      }

      // 如果物品被移除了（remaining <= 0），返回 null
      // 否则返回更新后的物品
      final updatedItem = controller.userItems.where((i) => i.id == itemId).firstOrNull;
      if (updatedItem == null) {
        return Result.success(_userItemToDto(item));
      }
      return Result.success(_userItemToDto(updatedItem));
    } catch (e) {
      return Result.failure('使用物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> clearUserItems() async {
    try {
      await controller.clearUserItems();
      return Result.success(true);
    } catch (e) {
      return Result.failure('清空用户物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<UserItemDto>>> searchUserItems(UserItemQuery query) async {
    try {
      var items = controller.userItems;

      // 按商品ID筛选
      if (query.productId != null) {
        items = items.where((i) => i.productId == query.productId).toList();
      }

      // 是否包含过期物品
      if (query.includeExpired != true) {
        final now = DateTime.now();
        items = items.where((i) => i.expireDate.isAfter(now)).toList();
      }

      final dtos = items.map(_userItemToDto).toList();

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('搜索用户物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 已使用物品操作 ============

  @override
  Future<Result<List<UsedItemDto>>> getUsedItems({
    PaginationParams? pagination,
  }) async {
    try {
      final items = controller.usedItems;
      final dtos = items.map(_usedItemToDto).toList();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('获取已使用物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 统计查询 ============

  @override
  Future<Result<int>> getProductsCount() async {
    try {
      return Result.success(controller.getGoodsCount());
    } catch (e) {
      return Result.failure('获取商品总数失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<int>> getUserItemsCount() async {
    try {
      return Result.success(controller.getItemsCount());
    } catch (e) {
      return Result.failure('获取用户物品总数失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<int>> getExpiringItemsCount() async {
    try {
      return Result.success(controller.getExpiringItemsCount());
    } catch (e) {
      return Result.failure('获取到期物品数量失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 转换方法 ============

  ProductDto _productToDto(Product product) {
    return ProductDto(
      id: product.id,
      name: product.name,
      description: product.description,
      image: product.image,
      stock: product.stock,
      price: product.price,
      exchangeStart: product.exchangeStart,
      exchangeEnd: product.exchangeEnd,
      useDuration: product.useDuration,
    );
  }

  UserItemDto _userItemToDto(UserItem item) {
    return UserItemDto(
      id: item.id,
      productId: item.productId,
      remaining: item.remaining,
      expireDate: item.expireDate,
      purchaseDate: item.purchaseDate,
      purchasePrice: item.purchasePrice,
      productSnapshot: item.productSnapshot,
    );
  }

  PointsLogDto _pointsLogToDto(PointsLog log) {
    return PointsLogDto(
      id: log.id,
      type: log.type,
      value: log.value,
      reason: log.reason,
      timestamp: log.timestamp,
    );
  }

  UsedItemDto _usedItemToDto(UsedItem item) {
    return UsedItemDto(
      id: item.id,
      productId: item.productId,
      useDate: item.useDate,
      productSnapshot: item.productSnapshot,
    );
  }
}

