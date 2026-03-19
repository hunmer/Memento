/// Goods 插件 - Repository 接口定义
///
/// 定义仓库和物品的数据访问抽象接口
library;

import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';

// ============ DTOs ============

/// 仓库 DTO
class WarehouseDto {
  final String id;
  final String name;
  final String? description;
  final int? iconData;
  final int? iconColor;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WarehouseDto({
    required this.id,
    required this.name,
    this.description,
    this.iconData,
    this.iconColor,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory WarehouseDto.fromJson(Map<String, dynamic> json) {
    return WarehouseDto(
      id: json['id'] as String,
      name: (json['name'] ?? json['title']) as String,
      description: json['description'] as String?,
      iconData: (json['iconData'] ?? json['icon']) as int?,
      iconColor: (json['iconColor'] ?? json['color']) as int?,
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': name,
      'description': description,
      'iconData': iconData,
      'iconColor': iconColor,
      'imageUrl': imageUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  WarehouseDto copyWith({
    String? id,
    String? name,
    String? description,
    int? iconData,
    int? iconColor,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WarehouseDto(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconData: iconData ?? this.iconData,
      iconColor: iconColor ?? this.iconColor,
      imageUrl: imageUrl ?? this.imageUrl,
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
  final int? quantity;
  final String? category;
  final String? imageUrl;
  final String? thumbUrl;
  final int? iconData;
  final int? iconColor;
  final List<String> tags;
  final List<Map<String, dynamic>> customFields;
  final DateTime? purchaseDate;
  final DateTime? expirationDate;
  final double? purchasePrice;
  final String? status;
  final String? notes;
  final List<GoodsItemDto> subItems;
  final List<Map<String, dynamic>> usageRecords;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GoodsItemDto({
    required this.id,
    required this.name,
    this.description,
    this.quantity,
    this.category,
    this.imageUrl,
    this.thumbUrl,
    this.iconData,
    this.iconColor,
    this.tags = const [],
    this.customFields = const [],
    this.purchaseDate,
    this.expirationDate,
    this.purchasePrice,
    this.status,
    this.notes,
    this.subItems = const [],
    this.usageRecords = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory GoodsItemDto.fromJson(Map<String, dynamic> json) {
    return GoodsItemDto(
      id: json['id'] as String,
      name: (json['name'] ?? json['title']) as String,
      description: json['description'] as String?,
      quantity: json['quantity'] as int?,
      category: json['category'] as String?,
      imageUrl: json['imageUrl'] as String?,
      thumbUrl: json['thumbUrl'] as String?,
      iconData: (json['iconData'] ?? json['icon']) as int?,
      iconColor: (json['iconColor'] ?? json['color']) as int?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      customFields: _parseCustomFields(json['customFields']),
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'] as String)
          : null,
      expirationDate: json['expirationDate'] != null
          ? DateTime.parse(json['expirationDate'] as String)
          : null,
      purchasePrice: json['purchasePrice'] != null
          ? (json['purchasePrice'] as num).toDouble()
          : null,
      status: json['status'] as String?,
      notes: json['notes'] as String?,
      subItems: _parseSubItems(json['subItems']),
      usageRecords: _parseUsageRecords(json['usageRecords']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  static List<Map<String, dynamic>> _parseCustomFields(dynamic fields) {
    if (fields == null) return [];
    if (fields is List) {
      return fields.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (fields is Map) {
      return fields.entries
          .map((e) => {'key': e.key, 'value': e.value})
          .toList();
    }
    return [];
  }

  static List<GoodsItemDto> _parseSubItems(dynamic items) {
    if (items == null) return [];
    if (items is List) {
      return items
          .map((e) => GoodsItemDto.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static List<Map<String, dynamic>> _parseUsageRecords(dynamic records) {
    if (records == null) return [];
    if (records is List) {
      return records.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': name,
      'description': description,
      'quantity': quantity,
      'category': category,
      'imageUrl': imageUrl,
      'thumbUrl': thumbUrl,
      'iconData': iconData,
      'iconColor': iconColor,
      'tags': tags,
      'customFields': customFields,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'expirationDate': expirationDate?.toIso8601String(),
      'purchasePrice': purchasePrice,
      'status': status,
      'notes': notes,
      'subItems': subItems.map((e) => e.toJson()).toList(),
      'usageRecords': usageRecords,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  GoodsItemDto copyWith({
    String? id,
    String? name,
    String? description,
    int? quantity,
    String? category,
    String? imageUrl,
    String? thumbUrl,
    int? iconData,
    int? iconColor,
    List<String>? tags,
    List<Map<String, dynamic>>? customFields,
    DateTime? purchaseDate,
    DateTime? expirationDate,
    double? purchasePrice,
    String? status,
    String? notes,
    List<GoodsItemDto>? subItems,
    List<Map<String, dynamic>>? usageRecords,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoodsItemDto(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      iconData: iconData ?? this.iconData,
      iconColor: iconColor ?? this.iconColor,
      tags: tags ?? this.tags,
      customFields: customFields ?? this.customFields,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expirationDate: expirationDate ?? this.expirationDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      subItems: subItems ?? this.subItems,
      usageRecords: usageRecords ?? this.usageRecords,
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
  Future<Result<WarehouseDto>> updateWarehouse(
      String id, WarehouseDto warehouse);

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
  Future<Result<GoodsItemDto>> createItem(
      String warehouseId, GoodsItemDto item);

  /// 更新物品
  Future<Result<GoodsItemDto>> updateItem(
      String warehouseId, String id, GoodsItemDto item);

  /// 删除物品
  Future<Result<bool>> deleteItem(String warehouseId, String id);

  /// 搜索物品
  Future<Result<List<GoodsItemDto>>> searchItems(GoodsItemQuery query);

  // ============ 统计操作 ============

  /// 获取统计信息
  Future<Result<Map<String, dynamic>>> getStats();
}
