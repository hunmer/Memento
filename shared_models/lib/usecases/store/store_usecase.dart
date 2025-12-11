/// Store 插件 - UseCase 业务逻辑层
library;

import 'package:uuid/uuid.dart';
import 'package:shared_models/repositories/store/store_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:shared_models/utils/validation.dart';

/// Store 插件 UseCase - 封装所有业务逻辑
class StoreUseCase {
  final IStoreRepository repository;
  final Uuid _uuid = const Uuid();

  StoreUseCase(this.repository);

  // ============ 商品 CRUD 操作 ============

  /// 获取商品列表
  Future<Result<dynamic>> getProducts(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getProducts(pagination: pagination);

      return result.map((products) {
        final jsonList = products.map((p) => p.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: pagination.offset,
            count: pagination.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取商品列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取商品
  Future<Result<Map<String, dynamic>?>> getProductById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getProductById(id);
      return result.map((product) => product?.toJson());
    } catch (e) {
      return Result.failure('获取商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建商品
  Future<Result<Map<String, dynamic>>> createProduct(
    Map<String, dynamic> params,
  ) async {
    // 参数验证
    final nameValidation = ParamValidator.requireString(params, 'name');
    if (!nameValidation.isValid) {
      return Result.failure(
        nameValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    final descriptionValidation =
        ParamValidator.requireString(params, 'description');
    if (!descriptionValidation.isValid) {
      return Result.failure(
        descriptionValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final now = DateTime.now();
      final product = ProductDto(
        id: params['id'] as String? ?? _uuid.v4(),
        name: params['name'] as String,
        description: params['description'] as String,
        image: params['image'] as String? ?? '',
        stock: params['stock'] as int? ?? 0,
        price: params['price'] as int? ?? 0,
        exchangeStart: params['exchangeStart'] != null
            ? DateTime.parse(params['exchangeStart'] as String)
            : now,
        exchangeEnd: params['exchangeEnd'] != null
            ? DateTime.parse(params['exchangeEnd'] as String)
            : DateTime(now.year + 1, now.month, now.day),
        useDuration: params['useDuration'] as int? ?? 30,
      );

      final result = await repository.createProduct(product);
      return result.map((p) => p.toJson());
    } catch (e) {
      return Result.failure('创建商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新商品
  Future<Result<Map<String, dynamic>>> updateProduct(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有数据
      final existingResult = await repository.getProductById(id);
      if (existingResult.isFailure) {
        return Result.failure('商品不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('商品不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        name: params['name'] as String?,
        description: params['description'] as String?,
        image: params['image'] as String?,
        stock: params['stock'] as int?,
        price: params['price'] as int?,
        exchangeStart: params['exchangeStart'] != null
            ? DateTime.parse(params['exchangeStart'] as String)
            : null,
        exchangeEnd: params['exchangeEnd'] != null
            ? DateTime.parse(params['exchangeEnd'] as String)
            : null,
        useDuration: params['useDuration'] as int?,
      );

      final result = await repository.updateProduct(id, updated);
      return result.map((p) => p.toJson());
    } catch (e) {
      return Result.failure('更新商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除商品
  Future<Result<bool>> deleteProduct(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteProduct(id);
    } catch (e) {
      return Result.failure('删除商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 归档商品
  Future<Result<bool>> archiveProduct(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.archiveProduct(id);
    } catch (e) {
      return Result.failure('归档商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 恢复商品
  Future<Result<bool>> restoreProduct(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.restoreProduct(id);
    } catch (e) {
      return Result.failure('恢复商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取归档商品
  Future<Result<dynamic>> getArchivedProducts(
    Map<String, dynamic> params,
  ) async {
    try {
      final pagination = _extractPagination(params);
      final result =
          await repository.getArchivedProducts(pagination: pagination);

      return result.map((products) {
        final jsonList = products.map((p) => p.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: pagination.offset,
            count: pagination.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取归档商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索商品
  Future<Result<dynamic>> searchProducts(Map<String, dynamic> params) async {
    try {
      final query = ProductQuery(
        nameKeyword: params['nameKeyword'] as String?,
        minPrice: params['minPrice'] as int?,
        maxPrice: params['maxPrice'] as int?,
        includeArchived: params['includeArchived'] as bool?,
        pagination: _extractPagination(params),
      );

      final result = await repository.searchProducts(query);
      return result.map((products) {
        final jsonList = products.map((p) => p.toJson()).toList();

        if (query.pagination != null && query.pagination!.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: query.pagination!.offset,
            count: query.pagination!.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('搜索商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 积分操作 ============

  /// 获取积分信息
  Future<Result<dynamic>> getPointsInfo(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getPointsInfo(pagination: pagination);

      return result.map((info) {
        final json = info.toJson();

        if (pagination != null && pagination.hasPagination) {
          json['logs'] = PaginationUtils.toMap(
            info.logs.map((l) => l.toJson()).toList(),
            offset: pagination.offset,
            count: pagination.count,
          );
        }

        return json;
      });
    } catch (e) {
      return Result.failure('获取积分信息失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 添加积分
  Future<Result<Map<String, dynamic>>> addPoints(
    Map<String, dynamic> params,
  ) async {
    final value = params['value'] as int?;
    final reason = params['reason'] as String?;

    if (value == null) {
      return Result.failure('缺少必需参数: value', code: ErrorCodes.invalidParams);
    }

    if (reason == null || reason.isEmpty) {
      return Result.failure('缺少必需参数: reason', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.addPoints(value, reason);
      return result.map((info) => info.toJson());
    } catch (e) {
      return Result.failure('添加积分失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 清空积分记录
  Future<Result<bool>> clearPointsLogs(Map<String, dynamic> params) async {
    try {
      return repository.clearPointsLogs();
    } catch (e) {
      return Result.failure('清空积分记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索积分记录
  Future<Result<dynamic>> searchPointsLogs(Map<String, dynamic> params) async {
    try {
      final query = PointsLogQuery(
        pagination: _extractPagination(params),
      );

      final result = await repository.searchPointsLogs(query);
      return result.map((logs) {
        final jsonList = logs.map((l) => l.toJson()).toList();

        if (query.pagination != null && query.pagination!.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: query.pagination!.offset,
            count: query.pagination!.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('搜索积分记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 用户物品操作 ============

  /// 获取用户物品列表
  Future<Result<dynamic>> getUserItems(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getUserItems(pagination: pagination);

      return result.map((items) {
        final jsonList = items.map((i) => i.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: pagination.offset,
            count: pagination.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取用户物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取用户物品
  Future<Result<Map<String, dynamic>?>> getUserItemById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getUserItemById(id);
      return result.map((item) => item?.toJson());
    } catch (e) {
      return Result.failure('获取用户物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 兑换商品
  Future<Result<Map<String, dynamic>>> exchangeProduct(
    Map<String, dynamic> params,
  ) async {
    final productId = params['productId'] as String?;
    if (productId == null || productId.isEmpty) {
      return Result.failure('缺少必需参数: productId',
          code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.exchangeProduct(productId);
      return result.map((item) => item.toJson());
    } catch (e) {
      return Result.failure('兑换商品失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 使用物品
  Future<Result<Map<String, dynamic>>> useItem(
      Map<String, dynamic> params) async {
    final itemId = params['itemId'] as String?;
    if (itemId == null || itemId.isEmpty) {
      return Result.failure('缺少必需参数: itemId', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.useItem(itemId);
      return result.map((item) => item.toJson());
    } catch (e) {
      return Result.failure('使用物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 清空用户物品
  Future<Result<bool>> clearUserItems(Map<String, dynamic> params) async {
    try {
      return repository.clearUserItems();
    } catch (e) {
      return Result.failure('清空用户物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索用户物品
  Future<Result<dynamic>> searchUserItems(Map<String, dynamic> params) async {
    try {
      final query = UserItemQuery(
        productId: params['productId'] as String?,
        includeExpired: params['includeExpired'] as bool?,
        pagination: _extractPagination(params),
      );

      final result = await repository.searchUserItems(query);
      return result.map((items) {
        final jsonList = items.map((i) => i.toJson()).toList();

        if (query.pagination != null && query.pagination!.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: query.pagination!.offset,
            count: query.pagination!.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('搜索用户物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 已使用物品操作 ============

  /// 获取已使用物品列表
  Future<Result<dynamic>> getUsedItems(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getUsedItems(pagination: pagination);

      return result.map((items) {
        final jsonList = items.map((i) => i.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: pagination.offset,
            count: pagination.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取已使用物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 统计查询 ============

  /// 获取商品总数
  Future<Result<int>> getProductsCount(Map<String, dynamic> params) async {
    try {
      return repository.getProductsCount();
    } catch (e) {
      return Result.failure('获取商品总数失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取用户物品总数
  Future<Result<int>> getUserItemsCount(Map<String, dynamic> params) async {
    try {
      return repository.getUserItemsCount();
    } catch (e) {
      return Result.failure('获取用户物品总数失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取七天内到期的物品数量
  Future<Result<int>> getExpiringItemsCount(Map<String, dynamic> params) async {
    try {
      return repository.getExpiringItemsCount();
    } catch (e) {
      return Result.failure('获取到期物品数量失败: $e', code: ErrorCodes.serverError);
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
