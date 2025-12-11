/// Database 插件 - 客户端 Repository 实现
///
/// 通过适配现有的 DatabaseService 和 DatabaseController 来实现 IDatabaseRepository 接口
library;

import 'package:shared_models/shared_models.dart';
import 'package:Memento/plugins/database/services/database_service.dart';
import 'package:Memento/plugins/database/controllers/database_controller.dart';
import 'package:Memento/plugins/database/models/database_model.dart';
import 'package:Memento/plugins/database/models/database_field.dart';
import 'package:Memento/plugins/database/models/record.dart';

/// 客户端 Database Repository 实现
class ClientDatabaseRepository extends IDatabaseRepository {
  final DatabaseService service;
  final DatabaseController controller;

  ClientDatabaseRepository({required this.service, required this.controller});

  // ============ 数据库操作 ============

  @override
  Future<Result<List<DatabaseModelDto>>> getDatabases({
    PaginationParams? pagination,
  }) async {
    try {
      final databases = await service.getAllDatabases();
      final dtos = databases.map(_databaseToDto).toList();

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
      return Result.failure('获取数据库列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<DatabaseModelDto?>> getDatabaseById(String id) async {
    try {
      final databases = await service.getAllDatabases();
      final database = databases.where((db) => db.id == id).firstOrNull;
      if (database == null) {
        return Result.success(null);
      }
      return Result.success(_databaseToDto(database));
    } catch (e) {
      return Result.failure('获取数据库失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<DatabaseModelDto>> createDatabase(DatabaseModelDto dto) async {
    try {
      final database = _dtoToDatabase(dto);
      await service.createDatabase(database);
      return Result.success(_databaseToDto(database));
    } catch (e) {
      return Result.failure('创建数据库失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<DatabaseModelDto>> updateDatabase(
    String id,
    DatabaseModelDto dto,
  ) async {
    try {
      final database = _dtoToDatabase(dto);
      await service.updateDatabase(database);
      return Result.success(_databaseToDto(database));
    } catch (e) {
      return Result.failure('更新数据库失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteDatabase(String id) async {
    try {
      await service.deleteDatabase(id);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除数据库失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<DatabaseModelDto>>> searchDatabases(
    DatabaseQuery query,
  ) async {
    try {
      final databases = await service.getAllDatabases();
      final matches = <DatabaseModel>[];

      for (final database in databases) {
        bool isMatch = true;

        if (query.nameKeyword != null && query.nameKeyword!.isNotEmpty) {
          final keyword = query.nameKeyword!.toLowerCase();
          final name = database.name.toLowerCase();
          isMatch = name.contains(keyword);
        }

        if (isMatch) {
          matches.add(database);
        }
      }

      final dtos = matches.map(_databaseToDto).toList();

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
      return Result.failure('搜索数据库失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 记录操作 ============

  @override
  Future<Result<List<DatabaseRecordDto>>> getRecords(
    String tableId, {
    PaginationParams? pagination,
  }) async {
    try {
      final records = await controller.getRecords(tableId);
      final dtos = records.map(_recordToDto).toList();

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
      return Result.failure('获取记录列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<DatabaseRecordDto?>> getRecordById(String id) async {
    try {
      // 需要通过所有数据库查找记录
      final databases = await service.getAllDatabases();
      for (final db in databases) {
        final records = await controller.getRecords(db.id);
        final record = records.where((r) => r.id == id).firstOrNull;
        if (record != null) {
          return Result.success(_recordToDto(record));
        }
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure('获取记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<DatabaseRecordDto>> createRecord(DatabaseRecordDto dto) async {
    try {
      final record = _dtoToRecord(dto);
      await controller.createRecord(record);
      return Result.success(_recordToDto(record));
    } catch (e) {
      return Result.failure('创建记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<DatabaseRecordDto>> updateRecord(
    String id,
    DatabaseRecordDto dto,
  ) async {
    try {
      final record = _dtoToRecord(dto);
      await controller.updateRecord(record);
      return Result.success(_recordToDto(record));
    } catch (e) {
      return Result.failure('更新记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteRecord(String id) async {
    try {
      // 获取记录所在的数据库
      final databases = await service.getAllDatabases();
      for (final db in databases) {
        final records = await controller.getRecords(db.id);
        final record = records.where((r) => r.id == id).firstOrNull;
        if (record != null) {
          await controller.deleteRecord(id);
          return Result.success(true);
        }
      }
      return Result.failure('记录不存在', code: ErrorCodes.notFound);
    } catch (e) {
      return Result.failure('删除记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<DatabaseRecordDto>>> searchRecords(
    DatabaseRecordQuery query,
  ) async {
    try {
      final records = await controller.getRecords(query.tableId);
      final matches = <Record>[];

      for (final record in records) {
        bool isMatch = true;

        if (query.fieldKeyword != null && query.fieldKeyword!.isNotEmpty) {
          final keyword = query.fieldKeyword!.toLowerCase();
          bool found = false;

          // 搜索所有字段值
          for (final value in record.fields.values) {
            if (value != null &&
                value.toString().toLowerCase().contains(keyword)) {
              found = true;
              break;
            }
          }

          if (!found) {
            isMatch = false;
          }
        }

        if (query.fieldName != null && query.fieldName!.isNotEmpty) {
          if (!record.fields.containsKey(query.fieldName)) {
            isMatch = false;
          }
        }

        if (isMatch) {
          matches.add(record);
        }
      }

      final dtos = matches.map(_recordToDto).toList();

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
      return Result.failure('搜索记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 转换方法 ============

  DatabaseModelDto _databaseToDto(DatabaseModel database) {
    return DatabaseModelDto(
      id: database.id,
      name: database.name,
      description: database.description,
      coverImage: database.coverImage,
      fields: database.fields.map(_fieldToDto).toList(),
      createdAt: database.createdAt,
      updatedAt: database.updatedAt,
    );
  }

  DatabaseFieldDto _fieldToDto(DatabaseField field) {
    return DatabaseFieldDto(
      id: field.id,
      name: field.name,
      type: field.type,
      isRequired: field.isRequired,
    );
  }

  DatabaseRecordDto _recordToDto(Record record) {
    return DatabaseRecordDto(
      id: record.id,
      tableId: record.tableId,
      fields: Map<String, dynamic>.from(record.fields),
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );
  }

  DatabaseModel _dtoToDatabase(DatabaseModelDto dto) {
    return DatabaseModel(
      id: dto.id,
      name: dto.name,
      description: dto.description,
      coverImage: dto.coverImage,
      fields: dto.fields.map(_dtoToField).toList(),
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }

  DatabaseField _dtoToField(DatabaseFieldDto dto) {
    return DatabaseField(
      id: dto.id,
      name: dto.name,
      type: dto.type,
      isRequired: dto.isRequired,
    );
  }

  Record _dtoToRecord(DatabaseRecordDto dto) {
    return Record(
      id: dto.id,
      tableId: dto.tableId,
      fields: Map<String, dynamic>.from(dto.fields),
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }
}
