/// Database 插件 - UseCase 业务逻辑层

import 'package:uuid/uuid.dart';
import 'package:shared_models/repositories/database/database_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:shared_models/utils/validation.dart';

/// Database 插件 UseCase - 封装所有业务逻辑
class DatabaseUseCase {
  final IDatabaseRepository repository;
  final Uuid _uuid = const Uuid();

  DatabaseUseCase(this.repository);

  // ============ 数据库 CRUD 操作 ============

  /// 获取数据库列表
  ///
  /// [params] 可选参数:
  /// - `offset`: 起始偏移量
  /// - `count`: 返回数量
  Future<Result<dynamic>> getDatabases(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getDatabases(pagination: pagination);

      return result.map((databases) {
        final jsonList = databases.map((d) => d.toJson()).toList();

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
      return Result.failure('获取数据库列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取数据库
  Future<Result<Map<String, dynamic>?>> getDatabaseById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getDatabaseById(id);
      return result.map((database) => database?.toJson());
    } catch (e) {
      return Result.failure('获取数据库失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建数据库
  ///
  /// [params] 必需参数:
  /// - `name`: 数据库名称
  Future<Result<Map<String, dynamic>>> createDatabase(
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

    try {
      final now = DateTime.now();
      final database = DatabaseModelDto(
        id: params['id'] as String? ?? _uuid.v4(),
        name: params['name'] as String,
        description: params['description'] as String?,
        coverImage: params['coverImage'] as String?,
        fields: (params['fields'] as List<dynamic>?)
                ?.map((e) => DatabaseFieldDto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        createdAt: now,
        updatedAt: now,
      );

      final result = await repository.createDatabase(database);
      return result.map((d) => d.toJson());
    } catch (e) {
      return Result.failure('创建数据库失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新数据库
  Future<Result<Map<String, dynamic>>> updateDatabase(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有数据
      final existingResult = await repository.getDatabaseById(id);
      if (existingResult.isFailure) {
        return Result.failure('数据库不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('数据库不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        name: params['name'] as String? ?? existing.name,
        description: params['description'] as String?,
        coverImage: params['coverImage'] as String?,
        fields: params.containsKey('fields')
            ? (params['fields'] as List<dynamic>?)
                    ?.map((e) => DatabaseFieldDto.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                existing.fields
            : existing.fields,
        updatedAt: DateTime.now(),
      );

      final result = await repository.updateDatabase(id, updated);
      return result.map((d) => d.toJson());
    } catch (e) {
      return Result.failure('更新数据库失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除数据库
  Future<Result<bool>> deleteDatabase(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteDatabase(id);
    } catch (e) {
      return Result.failure('删除数据库失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索数据库
  Future<Result<dynamic>> searchDatabases(Map<String, dynamic> params) async {
    try {
      final query = DatabaseQuery(
        nameKeyword: params['nameKeyword'] as String?,
        pagination: _extractPagination(params),
      );

      final result = await repository.searchDatabases(query);
      return result.map((databases) {
        final jsonList = databases.map((d) => d.toJson()).toList();

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
      return Result.failure('搜索数据库失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 记录 CRUD 操作 ============

  /// 获取指定数据库的记录列表
  Future<Result<dynamic>> getRecords(Map<String, dynamic> params) async {
    final tableId = params['tableId'] as String?;
    if (tableId == null || tableId.isEmpty) {
      return Result.failure(
        '缺少必需参数: tableId',
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final pagination = _extractPagination(params);
      final result = await repository.getRecords(tableId, pagination: pagination);

      return result.map((records) {
        final jsonList = records.map((r) => r.toJson()).toList();

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
      return Result.failure('获取记录列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取记录
  Future<Result<Map<String, dynamic>?>> getRecordById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getRecordById(id);
      return result.map((record) => record?.toJson());
    } catch (e) {
      return Result.failure('获取记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建记录
  ///
  /// [params] 必需参数:
  /// - `tableId`: 数据库 ID
  /// - `fields`: 记录字段数据
  Future<Result<Map<String, dynamic>>> createRecord(
    Map<String, dynamic> params,
  ) async {
    // 参数验证
    final tableIdValidation = ParamValidator.requireString(params, 'tableId');
    if (!tableIdValidation.isValid) {
      return Result.failure(
        tableIdValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    if (params['fields'] == null || params['fields'] is! Map<String, dynamic>) {
      return Result.failure(
        '缺少必需参数: fields',
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final now = DateTime.now();
      final record = DatabaseRecordDto(
        id: params['id'] as String? ?? _uuid.v4(),
        tableId: params['tableId'] as String,
        fields: params['fields'] as Map<String, dynamic>,
        createdAt: now,
        updatedAt: now,
      );

      final result = await repository.createRecord(record);
      return result.map((r) => r.toJson());
    } catch (e) {
      return Result.failure('创建记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新记录
  Future<Result<Map<String, dynamic>>> updateRecord(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有数据
      final existingResult = await repository.getRecordById(id);
      if (existingResult.isFailure) {
        return Result.failure('记录不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('记录不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        fields: params.containsKey('fields')
            ? params['fields'] as Map<String, dynamic>
            : existing.fields,
        updatedAt: DateTime.now(),
      );

      final result = await repository.updateRecord(id, updated);
      return result.map((r) => r.toJson());
    } catch (e) {
      return Result.failure('更新记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除记录
  Future<Result<bool>> deleteRecord(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteRecord(id);
    } catch (e) {
      return Result.failure('删除记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索记录
  Future<Result<dynamic>> searchRecords(Map<String, dynamic> params) async {
    final tableId = params['tableId'] as String?;
    if (tableId == null || tableId.isEmpty) {
      return Result.failure(
        '缺少必需参数: tableId',
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final query = DatabaseRecordQuery(
        tableId: tableId,
        fieldKeyword: params['fieldKeyword'] as String?,
        fieldName: params['fieldName'] as String?,
        pagination: _extractPagination(params),
      );

      final result = await repository.searchRecords(query);
      return result.map((records) {
        final jsonList = records.map((r) => r.toJson()).toList();

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
      return Result.failure('搜索记录失败: $e', code: ErrorCodes.serverError);
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
