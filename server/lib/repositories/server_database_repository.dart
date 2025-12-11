/// Database 插件 - 服务端 Repository 实现
library;

import 'package:shared_models/shared_models.dart';
import '../services/plugin_data_service.dart';

class ServerDatabaseRepository implements IDatabaseRepository {
  final PluginDataService dataService;
  final String userId;

  static const String _pluginId = 'database';

  ServerDatabaseRepository({
    required this.dataService,
    required this.userId,
  });

  // ============ 内部方法 ============

  Future<List<DatabaseModelDto>> _readAllDatabases() async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      'databases.json',
    );
    if (data == null) return [];

    final databases = data['databases'] as List<dynamic>? ?? [];
    return databases
        .map((e) => DatabaseModelDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAllDatabases(List<DatabaseModelDto> databases) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'databases.json',
      {'databases': databases.map((d) => d.toJson()).toList()},
    );
  }

  Future<List<DatabaseRecordDto>> _readAllRecords(String tableId) async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      'records_$tableId.json',
    );
    if (data == null) return [];

    final records = data['records'] as List<dynamic>? ?? [];
    return records
        .map((e) => DatabaseRecordDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAllRecords(
      String tableId, List<DatabaseRecordDto> records) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'records_$tableId.json',
      {'records': records.map((r) => r.toJson()).toList()},
    );
  }

  // ============ 数据库操作实现 ============

  @override
  Future<Result<List<DatabaseModelDto>>> getDatabases(
      {PaginationParams? pagination}) async {
    try {
      var databases = await _readAllDatabases();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          databases,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(databases);
    } catch (e) {
      return Result.failure('获取数据库列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<DatabaseModelDto?>> getDatabaseById(String id) async {
    try {
      final databases = await _readAllDatabases();
      final database = databases.where((d) => d.id == id).firstOrNull;
      return Result.success(database);
    } catch (e) {
      return Result.failure('获取数据库失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<DatabaseModelDto>> createDatabase(
      DatabaseModelDto database) async {
    try {
      final databases = await _readAllDatabases();
      databases.add(database);
      await _saveAllDatabases(databases);
      return Result.success(database);
    } catch (e) {
      return Result.failure('创建数据库失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<DatabaseModelDto>> updateDatabase(
      String id, DatabaseModelDto database) async {
    try {
      final databases = await _readAllDatabases();
      final index = databases.indexWhere((d) => d.id == id);

      if (index == -1) {
        return Result.failure('数据库不存在', code: ErrorCodes.notFound);
      }

      databases[index] = database;
      await _saveAllDatabases(databases);
      return Result.success(database);
    } catch (e) {
      return Result.failure('更新数据库失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteDatabase(String id) async {
    try {
      final databases = await _readAllDatabases();
      final initialLength = databases.length;
      databases.removeWhere((d) => d.id == id);

      if (databases.length == initialLength) {
        return Result.failure('数据库不存在', code: ErrorCodes.notFound);
      }

      await _saveAllDatabases(databases);

      // 同时删除所有相关记录
      await dataService.writePluginData(
        userId,
        _pluginId,
        'records_$id.json',
        {'records': []},
      );

      return Result.success(true);
    } catch (e) {
      return Result.failure('删除数据库失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<DatabaseModelDto>>> searchDatabases(
      DatabaseQuery query) async {
    try {
      var databases = await _readAllDatabases();

      if (query.nameKeyword != null) {
        databases = databases.where((database) {
          return database.name.toLowerCase().contains(
                query.nameKeyword!.toLowerCase(),
              );
        }).toList();
      }

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          databases,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(databases);
    } catch (e) {
      return Result.failure('搜索数据库失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 记录操作实现 ============

  @override
  Future<Result<List<DatabaseRecordDto>>> getRecords(String tableId,
      {PaginationParams? pagination}) async {
    try {
      var records = await _readAllRecords(tableId);

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          records,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(records);
    } catch (e) {
      return Result.failure('获取记录列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<DatabaseRecordDto?>> getRecordById(String id) async {
    try {
      // 需要遍历所有数据库的记录
      final databases = await _readAllDatabases();
      for (final database in databases) {
        final records = await _readAllRecords(database.id);
        final record = records.where((r) => r.id == id).firstOrNull;
        if (record != null) {
          return Result.success(record);
        }
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure('获取记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<DatabaseRecordDto>> createRecord(
      DatabaseRecordDto record) async {
    try {
      final records = await _readAllRecords(record.tableId);
      records.add(record);
      await _saveAllRecords(record.tableId, records);
      return Result.success(record);
    } catch (e) {
      return Result.failure('创建记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<DatabaseRecordDto>> updateRecord(
      String id, DatabaseRecordDto record) async {
    try {
      final records = await _readAllRecords(record.tableId);
      final index = records.indexWhere((r) => r.id == id);

      if (index == -1) {
        return Result.failure('记录不存在', code: ErrorCodes.notFound);
      }

      records[index] = record;
      await _saveAllRecords(record.tableId, records);
      return Result.success(record);
    } catch (e) {
      return Result.failure('更新记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteRecord(String id) async {
    try {
      // 需要遍历所有数据库的记录
      final databases = await _readAllDatabases();
      for (final database in databases) {
        final records = await _readAllRecords(database.id);
        final initialLength = records.length;
        records.removeWhere((r) => r.id == id);

        if (records.length < initialLength) {
          await _saveAllRecords(database.id, records);
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
      DatabaseRecordQuery query) async {
    try {
      var records = await _readAllRecords(query.tableId);

      if (query.fieldKeyword != null && query.fieldName != null) {
        records = records.where((record) {
          final fieldValue = record.fields[query.fieldName!]?.toString() ?? '';
          return fieldValue.toLowerCase().contains(
                query.fieldKeyword!.toLowerCase(),
              );
        }).toList();
      } else if (query.fieldKeyword != null) {
        // 在所有字段中搜索
        records = records.where((record) {
          return record.fields.values.any((value) {
            return value.toString().toLowerCase().contains(
                  query.fieldKeyword!.toLowerCase(),
                );
          });
        }).toList();
      }

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          records,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(records);
    } catch (e) {
      return Result.failure('搜索记录失败: $e', code: ErrorCodes.serverError);
    }
  }
}
