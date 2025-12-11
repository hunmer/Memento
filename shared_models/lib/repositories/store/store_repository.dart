/// Store 插件 - Repository 接口定义

import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';

// ============ DTOs ============

/// 商品 DTO
class ProductDto {
  final String id;
  final String name;
  final String description;
  final String image;
  final int stock;
  final int price;
  final DateTime exchangeStart;
  final DateTime exchangeEnd;
  final int useDuration;

  const ProductDto({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.stock,
    required this.price,
    required this.exchangeStart,
    required this.exchangeEnd,
    required this.useDuration,
  });

  /// 从 JSON 构造
  factory ProductDto.fromJson(Map<String, dynamic> json) {
    return ProductDto(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      image: json['image'] as String,
      stock: json['stock'] as int,
      price: json['price'] as int,
      exchangeStart: DateTime.parse(json['exchangeStart'] as String),
      exchangeEnd: DateTime.parse(json['exchangeEnd'] as String),
      useDuration: json['useDuration'] as int,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'stock': stock,
      'price': price,
      'exchangeStart': exchangeStart.toIso8601String(),
      'exchangeEnd': exchangeEnd.toIso8601String(),
      'useDuration': useDuration,
    };
  }

  /// 复制并修改
  ProductDto copyWith({
    String? id,
    String? name,
    String? description,
    String? image,
    int? stock,
    int? price,
    DateTime? exchangeStart,
    DateTime? exchangeEnd,
    int? useDuration,
  }) {
    return ProductDto(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      image: image ?? this.image,
      stock: stock ?? this.stock,
      price: price ?? this.price,
      exchangeStart: exchangeStart ?? this.exchangeStart,
      exchangeEnd: exchangeEnd ?? this.exchangeEnd,
      useDuration: useDuration ?? this.useDuration,
    );
  }
}

/// 用户物品 DTO
class UserItemDto {
  final String id;
  final String productId;
  final int remaining;
  final DateTime expireDate;
  final DateTime purchaseDate;
  final int purchasePrice;
  final Map<String, dynamic> productSnapshot;

  const UserItemDto({
    required this.id,
    required this.productId,
    required this.remaining,
    required this.expireDate,
    required this.purchaseDate,
    required this.purchasePrice,
    required this.productSnapshot,
  });

  factory UserItemDto.fromJson(Map<String, dynamic> json) {
    return UserItemDto(
      id: json['id'] as String,
      productId: json['productId'] as String,
      remaining: json['remaining'] as int,
      expireDate: DateTime.parse(json['expireDate'] as String),
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      purchasePrice: json['purchasePrice'] as int,
      productSnapshot: Map<String, dynamic>.from(json['productSnapshot'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'remaining': remaining,
      'expireDate': expireDate.toIso8601String(),
      'purchaseDate': purchaseDate.toIso8601String(),
      'purchasePrice': purchasePrice,
      'productSnapshot': productSnapshot,
    };
  }

  UserItemDto copyWith({
    String? id,
    String? productId,
    int? remaining,
    DateTime? expireDate,
    DateTime? purchaseDate,
    int? purchasePrice,
    Map<String, dynamic>? productSnapshot,
  }) {
    return UserItemDto(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      remaining: remaining ?? this.remaining,
      expireDate: expireDate ?? this.expireDate,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      productSnapshot: productSnapshot ?? this.productSnapshot,
    );
  }
}

/// 积分记录 DTO
class PointsLogDto {
  final String id;
  final String type; // '获得' 或 '消耗'
  final int value;
  final String reason;
  final DateTime timestamp;

  const PointsLogDto({
    required this.id,
    required this.type,
    required this.value,
    required this.reason,
    required this.timestamp,
  });

  factory PointsLogDto.fromJson(Map<String, dynamic> json) {
    return PointsLogDto(
      id: json['id'] as String,
      type: json['type'] as String,
      value: json['value'] as int,
      reason: json['reason'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'value': value,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  PointsLogDto copyWith({
    String? id,
    String? type,
    int? value,
    String? reason,
    DateTime? timestamp,
  }) {
    return PointsLogDto(
      id: id ?? this.id,
      type: type ?? this.type,
      value: value ?? this.value,
      reason: reason ?? this.reason,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

/// 已使用物品 DTO
class UsedItemDto {
  final String id;
  final String productId;
  final DateTime useDate;
  final Map<String, dynamic> productSnapshot;

  const UsedItemDto({
    required this.id,
    required this.productId,
    required this.useDate,
    required this.productSnapshot,
  });

  factory UsedItemDto.fromJson(Map<String, dynamic> json) {
    return UsedItemDto(
      id: json['id'] as String,
      productId: json['productId'] as String,
      useDate: DateTime.parse(json['useDate'] as String),
      productSnapshot: Map<String, dynamic>.from(json['productSnapshot'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'useDate': useDate.toIso8601String(),
      'productSnapshot': productSnapshot,
    };
  }

  UsedItemDto copyWith({
    String? id,
    String? productId,
    DateTime? useDate,
    Map<String, dynamic>? productSnapshot,
  }) {
    return UsedItemDto(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      useDate: useDate ?? this.useDate,
      productSnapshot: productSnapshot ?? this.productSnapshot,
    );
  }
}

/// 积分信息 DTO（包含余额和记录）
class PointsInfoDto {
  final int currentPoints;
  final List<PointsLogDto> logs;

  const PointsInfoDto({
    required this.currentPoints,
    this.logs = const [],
  });

  factory PointsInfoDto.fromJson(Map<String, dynamic> json) {
    return PointsInfoDto(
      currentPoints: json['currentPoints'] as int,
      logs: (json['logs'] as List<dynamic>?)
              ?.map((e) => PointsLogDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPoints': currentPoints,
      'logs': logs.map((e) => e.toJson()).toList(),
    };
  }

  PointsInfoDto copyWith({
    int? currentPoints,
    List<PointsLogDto>? logs,
  }) {
    return PointsInfoDto(
      currentPoints: currentPoints ?? this.currentPoints,
      logs: logs ?? this.logs,
    );
  }
}

// ============ Query Objects ============

/// 商品查询参数对象
class ProductQuery {
  final String? nameKeyword;
  final int? minPrice;
  final int? maxPrice;
  final bool? includeArchived;
  final PaginationParams? pagination;

  const ProductQuery({
    this.nameKeyword,
    this.minPrice,
    this.maxPrice,
    this.includeArchived,
    this.pagination,
  });
}

/// 积分记录查询参数对象
class PointsLogQuery {
  final PaginationParams? pagination;

  const PointsLogQuery({
    this.pagination,
  });
}

/// 用户物品查询参数对象
class UserItemQuery {
  final String? productId;
  final bool? includeExpired;
  final PaginationParams? pagination;

  const UserItemQuery({
    this.productId,
    this.includeExpired,
    this.pagination,
  });
}

// ============ Repository Interface ============

/// Store 插件 Repository 接口
abstract class IStoreRepository {
  // ============ 商品操作 ============

  /// 获取所有商品
  Future<Result<List<ProductDto>>> getProducts({PaginationParams? pagination});

  /// 根据 ID 获取商品
  Future<Result<ProductDto?>> getProductById(String id);

  /// 创建商品
  Future<Result<ProductDto>> createProduct(ProductDto product);

  /// 更新商品
  Future<Result<ProductDto>> updateProduct(String id, ProductDto product);

  /// 删除商品
  Future<Result<bool>> deleteProduct(String id);

  /// 归档商品
  Future<Result<bool>> archiveProduct(String id);

  /// 恢复商品
  Future<Result<bool>> restoreProduct(String id);

  /// 获取归档商品
  Future<Result<List<ProductDto>>> getArchivedProducts({PaginationParams? pagination});

  /// 搜索商品
  Future<Result<List<ProductDto>>> searchProducts(ProductQuery query);

  // ============ 积分操作 ============

  /// 获取积分信息（余额 + 记录）
  Future<Result<PointsInfoDto>> getPointsInfo({PaginationParams? pagination});

  /// 添加积分
  Future<Result<PointsInfoDto>> addPoints(int value, String reason);

  /// 清空积分记录
  Future<Result<bool>> clearPointsLogs();

  /// 搜索积分记录
  Future<Result<List<PointsLogDto>>> searchPointsLogs(PointsLogQuery query);

  // ============ 用户物品操作 ============

  /// 获取用户物品列表
  Future<Result<List<UserItemDto>>> getUserItems({PaginationParams? pagination});

  /// 根据 ID 获取用户物品
  Future<Result<UserItemDto?>> getUserItemById(String id);

  /// 兑换商品
  Future<Result<UserItemDto>> exchangeProduct(String productId);

  /// 使用物品
  Future<Result<UserItemDto>> useItem(String itemId);

  /// 清空用户物品
  Future<Result<bool>> clearUserItems();

  /// 搜索用户物品
  Future<Result<List<UserItemDto>>> searchUserItems(UserItemQuery query);

  // ============ 已使用物品操作 ============

  /// 获取已使用物品列表
  Future<Result<List<UsedItemDto>>> getUsedItems({PaginationParams? pagination});

  // ============ 统计查询 ============

  /// 获取商品总数
  Future<Result<int>> getProductsCount();

  /// 获取用户物品总数
  Future<Result<int>> getUserItemsCount();

  /// 获取七天内到期的物品数量
  Future<Result<int>> getExpiringItemsCount();
}
