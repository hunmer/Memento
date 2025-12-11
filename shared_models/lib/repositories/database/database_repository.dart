/// Database 插件 - Repository 接口定义
library;

import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';

// ============ DTOs ============

/// 数据库模型 DTO
class DatabaseModelDto {
  final String id;
  final String name;
  final String? description;
  final String? coverImage;
  final List<DatabaseFieldDto> fields;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DatabaseModelDto({
    required this.id,
    required this.name,
    this.description,
    this.coverImage,
    this.fields = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从 JSON 构造
  factory DatabaseModelDto.fromJson(Map<String, dynamic> json) {
    return DatabaseModelDto(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      coverImage: json['coverImage'] as String?,
      fields: (json['fields'] as List<dynamic>?)
              ?.map((e) => DatabaseFieldDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coverImage': coverImage,
      'fields': fields.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改
  DatabaseModelDto copyWith({
    String? id,
    String? name,
    String? description,
    String? coverImage,
    List<DatabaseFieldDto>? fields,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DatabaseModelDto(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      fields: fields ?? this.fields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 数据库字段 DTO
class DatabaseFieldDto {
  final String id;
  final String name;
  final String type;
  final bool isRequired;

  const DatabaseFieldDto({
    required this.id,
    required this.name,
    required this.type,
    this.isRequired = false,
  });

  factory DatabaseFieldDto.fromJson(Map<String, dynamic> json) {
    return DatabaseFieldDto(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      isRequired: json['isRequired'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'isRequired': isRequired,
    };
  }

  DatabaseFieldDto copyWith({
    String? id,
    String? name,
    String? type,
    bool? isRequired,
  }) {
    return DatabaseFieldDto(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isRequired: isRequired ?? this.isRequired,
    );
  }
}

/// 记录 DTO
class DatabaseRecordDto {
  final String id;
  final String tableId;
  final Map<String, dynamic> fields;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DatabaseRecordDto({
    required this.id,
    required this.tableId,
    required this.fields,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DatabaseRecordDto.fromJson(Map<String, dynamic> json) {
    return DatabaseRecordDto(
      id: json['id'] as String,
      tableId: json['tableId'] as String,
      fields: Map<String, dynamic>.from(json['fields'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableId': tableId,
      'fields': fields,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  DatabaseRecordDto copyWith({
    String? id,
    String? tableId,
    Map<String, dynamic>? fields,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DatabaseRecordDto(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      fields: fields ?? this.fields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============ Query Objects ============

/// 数据库查询参数对象
class DatabaseQuery {
  final String? nameKeyword;
  final PaginationParams? pagination;

  const DatabaseQuery({
    this.nameKeyword,
    this.pagination,
  });
}

/// 记录查询参数对象
class DatabaseRecordQuery {
  final String tableId;
  final String? fieldKeyword;
  final String? fieldName;
  final PaginationParams? pagination;

  const DatabaseRecordQuery({
    required this.tableId,
    this.fieldKeyword,
    this.fieldName,
    this.pagination,
  });
}

// ============ Repository Interface ============

/// Database 插件 Repository 接口
abstract class IDatabaseRepository {
  // ============ 数据库操作 ============

  /// 获取所有数据库
  Future<Result<List<DatabaseModelDto>>> getDatabases(
      {PaginationParams? pagination});

  /// 根据 ID 获取
  Future<Result<DatabaseModelDto?>> getDatabaseById(String id);

  /// 创建数据库
  Future<Result<DatabaseModelDto>> createDatabase(DatabaseModelDto database);

  /// 更新数据库
  Future<Result<DatabaseModelDto>> updateDatabase(
      String id, DatabaseModelDto database);

  /// 删除数据库
  Future<Result<bool>> deleteDatabase(String id);

  /// 搜索数据库
  Future<Result<List<DatabaseModelDto>>> searchDatabases(DatabaseQuery query);

  // ============ 记录操作 ============

  /// 获取指定数据库的所有记录
  Future<Result<List<DatabaseRecordDto>>> getRecords(String tableId,
      {PaginationParams? pagination});

  /// 根据 ID 获取记录
  Future<Result<DatabaseRecordDto?>> getRecordById(String id);

  /// 创建记录
  Future<Result<DatabaseRecordDto>> createRecord(DatabaseRecordDto record);

  /// 更新记录
  Future<Result<DatabaseRecordDto>> updateRecord(
      String id, DatabaseRecordDto record);

  /// 删除记录
  Future<Result<bool>> deleteRecord(String id);

  /// 搜索记录
  Future<Result<List<DatabaseRecordDto>>> searchRecords(
      DatabaseRecordQuery query);
}
