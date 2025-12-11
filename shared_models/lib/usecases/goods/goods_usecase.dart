/// Goods 插件 - UseCase 业务逻辑层
///
/// 此文件包含共享的业务逻辑，客户端和服务端都使用此层

import 'package:uuid/uuid.dart';

import 'package:shared_models/repositories/goods/goods_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:shared_models/utils/validation.dart';

/// Goods UseCase - 封装所有业务逻辑
class GoodsUseCase {
  final IGoodsRepository repository;
  final Uuid _uuid = const Uuid();

  GoodsUseCase(this.repository);

  // ============ 仓库操作 ============

  /// 获取仓库列表
  ///
  /// [params] 可选参数:
  /// - `offset`: 起始偏移量
  /// - `count`: 返回数量
  Future<Result<dynamic>> getWarehouses(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getWarehouses(
        pagination: pagination,
      );

      return result.map((warehouses) {
        final jsonList = warehouses.map((w) => w.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList, offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取仓库失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取仓库
  Future<Result<Map<String, dynamic>?>> getWarehouseById(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getWarehouseById(id);
      return result.map((w) => w?.toJson());
    } catch (e) {
      return Result.failure('获取仓库失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建仓库
  ///
  /// [params] 必需参数:
  /// - `name`: 仓库名称
  /// 可选参数:
  /// - `description`: 描述
  /// - `icon`: 图标
  /// - `color`: 颜色
  Future<Result<Map<String, dynamic>>> createWarehouse(Map<String, dynamic> params) async {
    final nameValidation = ParamValidator.requireString(params, 'name');
    if (!nameValidation.isValid) {
      return Result.failure(nameValidation.errorMessage!, code: ErrorCodes.invalidParams);
    }

    try {
      final now = DateTime.now();
      final warehouse = WarehouseDto(
        id: params['id'] as String? ?? _uuid.v4(),
        name: params['name'] as String,
        description: params['description'] as String?,
        icon: params['icon'] as String?,
        color: params['color'] as String?,
        createdAt: now,
        updatedAt: now,
      );

      final result = await repository.createWarehouse(warehouse);
      return result.map((w) => w.toJson());
    } catch (e) {
      return Result.failure('创建仓库失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新仓库
  Future<Result<Map<String, dynamic>>> updateWarehouse(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有仓库
      final existingResult = await repository.getWarehouseById(id);
      if (existingResult.isFailure) {
        return Result.failure('仓库不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('仓库不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        name: params['name'] as String? ?? existing.name,
        description: params.containsKey('description') ? params['description'] as String? : existing.description,
        icon: params.containsKey('icon') ? params['icon'] as String? : existing.icon,
        color: params.containsKey('color') ? params['color'] as String? : existing.color,
        updatedAt: DateTime.now(),
      );

      final result = await repository.updateWarehouse(id, updated);
      return result.map((w) => w.toJson());
    } catch (e) {
      return Result.failure('更新仓库失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除仓库
  Future<Result<bool>> deleteWarehouse(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteWarehouse(id);
    } catch (e) {
      return Result.failure('删除仓库失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 物品操作 ============

  /// 获取物品列表
  ///
  /// [params] 可选参数:
  /// - `warehouseId`: 按仓库过滤
  /// - `offset`: 起始偏移量
  /// - `count`: 返回数量
  Future<Result<dynamic>> getItems(Map<String, dynamic> params) async {
    try {
      final warehouseId = params['warehouseId'] as String?;
      final pagination = _extractPagination(params);
      final result = await repository.getItems(
        warehouseId: warehouseId,
        pagination: pagination,
      );

      return result.map((items) {
        final jsonList = items.map((i) => i.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList, offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取物品
  Future<Result<Map<String, dynamic>?>> getItemById(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getItemById(id);
      return result.map((i) => i?.toJson());
    } catch (e) {
      return Result.failure('获取物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建物品
  ///
  /// [params] 必需参数:
  /// - `name`: 物品名称
  /// - `warehouseId`: 所属仓库 ID
  /// 可选参数:
  /// - `description`: 描述
  /// - `quantity`: 数量（默认1）
  /// - `category`: 分类
  /// - `tags`: 标签列表
  /// - `customFields`: 自定义字段
  Future<Result<Map<String, dynamic>>> createItem(Map<String, dynamic> params) async {
    final nameValidation = ParamValidator.requireString(params, 'name');
    if (!nameValidation.isValid) {
      return Result.failure(nameValidation.errorMessage!, code: ErrorCodes.invalidParams);
    }

    final warehouseIdValidation = ParamValidator.requireString(params, 'warehouseId');
    if (!warehouseIdValidation.isValid) {
      return Result.failure(warehouseIdValidation.errorMessage!, code: ErrorCodes.invalidParams);
    }

    try {
      final warehouseId = params['warehouseId'] as String;
      final now = DateTime.now();
      final item = GoodsItemDto(
        id: params['id'] as String? ?? _uuid.v4(),
        name: params['name'] as String,
        description: params['description'] as String?,
        quantity: params['quantity'] as int? ?? 1,
        category: params['category'] as String?,
        tags: (params['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        customFields: params['customFields'] as Map<String, dynamic>?,
        createdAt: now,
        updatedAt: now,
      );

      final result = await repository.createItem(warehouseId, item);
      return result.map((i) => i.toJson());
    } catch (e) {
      return Result.failure('创建物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新物品
  Future<Result<Map<String, dynamic>>> updateItem(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    final warehouseId = params['warehouseId'] as String?;
    if (warehouseId == null || warehouseId.isEmpty) {
      return Result.failure('缺少必需参数: warehouseId', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有物品
      final existingResult = await repository.getItemById(id);
      if (existingResult.isFailure) {
        return Result.failure('物品不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('物品不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        name: params['name'] as String? ?? existing.name,
        description: params.containsKey('description') ? params['description'] as String? : existing.description,
        quantity: params['quantity'] as int? ?? existing.quantity,
        category: params.containsKey('category') ? params['category'] as String? : existing.category,
        tags: params['tags'] != null ? (params['tags'] as List<dynamic>).cast<String>() : existing.tags,
        customFields: params.containsKey('customFields') ? params['customFields'] as Map<String, dynamic>? : existing.customFields,
        updatedAt: DateTime.now(),
      );

      final result = await repository.updateItem(warehouseId, id, updated);
      return result.map((i) => i.toJson());
    } catch (e) {
      return Result.failure('更新物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除物品
  Future<Result<bool>> deleteItem(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    final warehouseId = params['warehouseId'] as String?;
    if (warehouseId == null || warehouseId.isEmpty) {
      return Result.failure('缺少必需参数: warehouseId', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteItem(warehouseId, id);
    } catch (e) {
      return Result.failure('删除物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索物品
  ///
  /// [params] 可选参数:
  /// - `keyword`: 搜索关键词（名称和描述）
  /// - `warehouseId`: 仓库过滤
  /// - `category`: 分类过滤
  /// - `tags`: 标签列表（逗号分隔）
  /// - `offset`: 分页偏移
  /// - `count`: 分页数量
  Future<Result<dynamic>> searchItems(Map<String, dynamic> params) async {
    try {
      final keyword = params['keyword'] as String?;
      final warehouseId = params['warehouseId'] as String?;
      final category = params['category'] as String?;
      final tagsStr = params['tags'] as String?;
      final tags = tagsStr?.split(',').where((t) => t.isNotEmpty).toList();
      final pagination = _extractPagination(params);

      final query = GoodsItemQuery(
        warehouseId: warehouseId,
        keyword: keyword,
        category: category,
        tags: tags,
        pagination: pagination,
      );

      final result = await repository.searchItems(query);

      return result.map((items) {
        final jsonList = items.map((i) => i.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList, offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('搜索物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 统计操作 ============

  /// 获取统计信息
  Future<Result<Map<String, dynamic>>> getStats(Map<String, dynamic> params) async {
    try {
      return repository.getStats();
    } catch (e) {
      return Result.failure('获取统计失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 辅助方法 ============

  PaginationParams? _extractPagination(Map<String, dynamic> params) {
    final offset = params['offset'] as int?;
    final count = params['count'] as int?;

    if (offset == null && count == null) return null;

    return PaginationParams(
      offset: offset ?? 0,
      count: count ?? 100,
    );
  }
}
