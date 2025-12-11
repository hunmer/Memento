/// Goods 插件 - Repository 接口定义
///
/// 定义仓库和物品的数据访问抽象接口

import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';

// ============ DTOs ============

/// 仓库 DTO
class WarehouseDto {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WarehouseDto({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WarehouseDto.fromJson(Map<String, dynamic> json) {
    return WarehouseDto(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  WarehouseDto copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WarehouseDto(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 物品 DTO
class GoodsItemDto {
  final String id;
  final String name;
  final String? description;
  final int quantity;
  final String? category;
  final List<String> tags;
  final Map<String, dynamic>? customFields;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoodsItemDto({
    required this.id,
    required this.name,
    this.description,
    this.quantity = 1,
    this.category,
    this.tags = const [],
    this.customFields,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GoodsItemDto.fromJson(Map<String, dynamic> json) {
    return GoodsItemDto(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      category: json['category'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      customFields: json['customFields'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'quantity': quantity,
      'category': category,
      'tags': tags,
      'customFields': customFields,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  GoodsItemDto copyWith({
    String? id,
    String? name,
    String? description,
    int? quantity,
    String? category,
    List<String>? tags,
    Map<String, dynamic>? customFields,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoodsItemDto(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      customFields: customFields ?? this.customFields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============ Query Objects ============

/// 物品查询参数
class GoodsItemQuery {
  final String? warehouseId;
  final String? keyword;
  final String? category;
  final List<String>? tags;
  final String? field;
  final String? value;
  final bool fuzzy;
  final bool findAll;
  final PaginationParams? pagination;

  const GoodsItemQuery({
    this.warehouseId,
    this.keyword,
    this.category,
    this.tags,
    this.field,
    this.value,
    this.fuzzy = false,
    this.findAll = true,
    this.pagination,
  });
}

/// 仓库查询参数
class WarehouseQuery {
  final String? field;
  final String? value;
  final bool fuzzy;
  final bool findAll;
  final PaginationParams? pagination;

  const WarehouseQuery({
    this.field,
    this.value,
    this.fuzzy = false,
    this.findAll = true,
    this.pagination,
  });
}

// ============ Repository Interface ============

/// Goods Repository 接口
///
/// 客户端和服务端都实现此接口，但使用不同的数据源
abstract class IGoodsRepository {
  // ============ 仓库操作 ============

  /// 获取所有仓库
  Future<Result<List<WarehouseDto>>> getWarehouses({
    PaginationParams? pagination,
  });

  /// 根据 ID 获取仓库
  Future<Result<WarehouseDto?>> getWarehouseById(String id);

  /// 创建仓库
  Future<Result<WarehouseDto>> createWarehouse(WarehouseDto warehouse);

  /// 更新仓库
  Future<Result<WarehouseDto>> updateWarehouse(String id, WarehouseDto warehouse);

  /// 删除仓库
  Future<Result<bool>> deleteWarehouse(String id);

  // ============ 物品操作 ============

  /// 获取所有物品
  Future<Result<List<GoodsItemDto>>> getItems({
    String? warehouseId,
    PaginationParams? pagination,
  });

  /// 根据 ID 获取物品
  Future<Result<GoodsItemDto?>> getItemById(String id);

  /// 创建物品
  Future<Result<GoodsItemDto>> createItem(String warehouseId, GoodsItemDto item);

  /// 更新物品
  Future<Result<GoodsItemDto>> updateItem(String warehouseId, String id, GoodsItemDto item);

  /// 删除物品
  Future<Result<bool>> deleteItem(String warehouseId, String id);

  /// 搜索物品
  Future<Result<List<GoodsItemDto>>> searchItems(GoodsItemQuery query);

  // ============ 统计操作 ============

  /// 获取统计信息
  Future<Result<Map<String, dynamic>>> getStats();
}
