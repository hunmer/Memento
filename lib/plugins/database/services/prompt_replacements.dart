import 'dart:convert';
import 'package:flutter/material.dart';
import '../database_plugin.dart';
import '../../../core/analysis/analysis_mode.dart';
import '../../../core/analysis/field_utils.dart';

/// Database插件的Prompt替换服务
///
/// 遵循 Memento Prompt 数据格式规范 v2.0
/// 详见: docs/PROMPT_DATA_SPEC.md
class DatabasePromptReplacements {
  final DatabasePlugin _plugin;

  DatabasePromptReplacements(this._plugin);

  /// 获取数据库列表
  ///
  /// 参数:
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total, fieldCnt } }
  /// - compact: 简化数据库信息 { sum: {...}, recs: [...] } (无fields详情)
  /// - full: 完整数据 (包含所有字段定义)
  Future<String> getDatabases(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);

      // 2. 获取所有数据库
      final databases = await _plugin.service.getAllDatabases();

      // 3. 根据模式转换数据
      final result = _convertDatabasesByMode(databases, mode);

      // 4. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取数据库列表失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取数据库列表时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取数据库记录
  ///
  /// 参数:
  /// - databaseId: 数据库ID (可选，留空则获取所有数据库的记录)
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  /// - fields: 自定义返回字段列表 (可选, 优先级高于 mode)
  /// - limit: 记录数量限制 (默认100)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total, timeRange } }
  /// - compact: 简化记录 { sum: {...}, recs: [...] } (仅关键字段)
  /// - full: 完整记录数据
  /// - fields: 自定义字段 { recs: [...] } (仅包含指定字段)
  Future<String> getRecords(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final customFields = params['fields'] as List<dynamic>?;
      final databaseId = params['databaseId'] as String?;
      final limit = (params['limit'] as num?)?.toInt() ?? 100;

      // 2. 获取记录
      List<Map<String, dynamic>> records;
      if (databaseId != null && databaseId.isNotEmpty) {
        // 获取指定数据库的记录
        final recordList = await _plugin.controller.getRecords(databaseId);
        records = recordList.map((r) => r.toMap()).toList();
      } else {
        // 获取所有数据库的记录
        records = await _getAllRecords();
      }

      // 3. 应用限制
      if (records.length > limit) {
        records = records.sublist(records.length - limit);
      }

      // 4. 应用字段过滤
      Map<String, dynamic> result;

      if (customFields != null && customFields.isNotEmpty) {
        // 优先使用 fields 参数（白名单模式）
        final fieldList = customFields.map((e) => e.toString()).toList();
        final filteredRecords = FieldUtils.simplifyRecords(
          records,
          keepFields: fieldList,
        );
        result = FieldUtils.buildCompactResponse(
          {'total': filteredRecords.length},
          filteredRecords,
        );
      } else {
        // 使用 mode 参数
        result = _convertRecordsByMode(records, mode);
      }

      // 5. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取记录失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取记录时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取统计信息
  ///
  /// 参数:
  /// - databaseId: 数据库ID (可选，留空则统计所有数据库)
  ///
  /// 返回格式: { sum: { dbCnt, totalRecords, avgRecordsPerDb, fieldTypes } }
  Future<String> getStatistics(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final databaseId = params['databaseId'] as String?;

      // 2. 获取数据库
      final databases = await _plugin.service.getAllDatabases();

      // 3. 计算统计信息
      Map<String, dynamic> statistics;
      if (databaseId != null && databaseId.isNotEmpty) {
        // 统计指定数据库
        final database = databases.firstWhere((db) => db.id == databaseId);
        final records = await _plugin.controller.getRecords(databaseId);
        statistics = _buildDatabaseStatistics(database, records.length);
      } else {
        // 统计所有数据库
        statistics = await _buildAllDatabasesStatistics(databases);
      }

      // 4. 返回 JSON 字符串
      return FieldUtils.toJsonString(FieldUtils.buildSummaryResponse(statistics));
    } catch (e) {
      debugPrint('获取统计信息失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取统计信息时出错',
        'details': e.toString(),
      });
    }
  }

  /// 查询记录
  ///
  /// 参数:
  /// - databaseId: 数据库ID (必需)
  /// - filters: 过滤条件 (JSON格式，例如：{"字段名": "值"})
  /// - mode: 数据模式 (summary/compact/full, 默认compact)
  /// - fields: 自定义返回字段列表 (可选, 优先级高于 mode)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total } }
  /// - compact: 简化记录 { sum: {...}, recs: [...] }
  /// - full: 完整记录数据
  /// - fields: 自定义字段 { recs: [...] } (仅包含指定字段)
  Future<String> queryRecords(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final customFields = params['fields'] as List<dynamic>?;
      final databaseId = params['databaseId'] as String?;
      final filtersStr = params['filters'] as String? ?? '{}';

      if (databaseId == null || databaseId.isEmpty) {
        return FieldUtils.toJsonString({
          'error': 'databaseId 参数不能为空',
        });
      }

      // 2. 解析过滤条件
      Map<String, dynamic> filters;
      try {
        filters = jsonDecode(filtersStr) as Map<String, dynamic>;
      } catch (e) {
        return FieldUtils.toJsonString({
          'error': '无效的 filters 参数格式，应为 JSON 字符串',
          'details': e.toString(),
        });
      }

      // 3. 获取记录
      var recordList = await _plugin.controller.getRecords(databaseId);
      var records = recordList.map((r) => r.toMap()).toList();

      // 4. 应用过滤
      if (filters.isNotEmpty) {
        records = _filterRecords(records, filters);
      }

      // 5. 应用字段过滤
      Map<String, dynamic> result;

      if (customFields != null && customFields.isNotEmpty) {
        // 优先使用 fields 参数（白名单模式）
        final fieldList = customFields.map((e) => e.toString()).toList();
        final filteredRecords = FieldUtils.simplifyRecords(
          records,
          keepFields: fieldList,
        );
        result = FieldUtils.buildCompactResponse(
          {'total': filteredRecords.length},
          filteredRecords,
        );
      } else {
        // 使用 mode 参数
        result = _convertRecordsByMode(records, mode);
      }

      // 6. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('查询记录失败: $e');
      return FieldUtils.toJsonString({
        'error': '查询记录时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取字段统计
  ///
  /// 参数:
  /// - databaseId: 数据库ID (必需)
  /// - fieldName: 字段名称 (必需)
  ///
  /// 返回格式: { sum: { fieldName, type, uniqueValues, distribution } }
  Future<String> getFieldStatistics(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final databaseId = params['databaseId'] as String?;
      final fieldName = params['fieldName'] as String?;

      if (databaseId == null || databaseId.isEmpty) {
        return FieldUtils.toJsonString({
          'error': 'databaseId 参数不能为空',
        });
      }

      if (fieldName == null || fieldName.isEmpty) {
        return FieldUtils.toJsonString({
          'error': 'fieldName 参数不能为空',
        });
      }

      // 2. 获取数据库和记录
      final databases = await _plugin.service.getAllDatabases();
      final database = databases.firstWhere((db) => db.id == databaseId);
      final records = await _plugin.controller.getRecords(databaseId);

      // 3. 查找字段定义
      final field = database.fields.firstWhere(
        (f) => f.name == fieldName,
        orElse: () => throw Exception('字段 "$fieldName" 不存在'),
      );

      // 4. 计算字段统计
      final statistics = _buildFieldStatistics(field, records, fieldName);

      // 5. 返回 JSON 字符串
      return FieldUtils.toJsonString(FieldUtils.buildSummaryResponse(statistics));
    } catch (e) {
      debugPrint('获取字段统计失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取字段统计时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取时间范围内的记录
  ///
  /// 参数:
  /// - databaseId: 数据库ID (必需)
  /// - startDate: 开始日期 (可选，格式：YYYY-MM-DD)
  /// - endDate: 结束日期 (可选，格式：YYYY-MM-DD)
  /// - mode: 数据模式 (summary/compact/full, 默认compact)
  /// - fields: 自定义返回字段列表 (可选, 优先级高于 mode)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total, dateRange } }
  /// - compact: 简化记录 { sum: {...}, recs: [...] }
  /// - full: 完整记录数据
  /// - fields: 自定义字段 { recs: [...] } (仅包含指定字段)
  Future<String> getRecordsByDateRange(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final customFields = params['fields'] as List<dynamic>?;
      final databaseId = params['databaseId'] as String?;
      final startDateStr = params['startDate'] as String?;
      final endDateStr = params['endDate'] as String?;

      if (databaseId == null || databaseId.isEmpty) {
        return FieldUtils.toJsonString({
          'error': 'databaseId 参数不能为空',
        });
      }

      // 2. 解析日期范围
      DateTime? startDate;
      DateTime? endDate;

      if (startDateStr != null && startDateStr.isNotEmpty) {
        startDate = DateTime.tryParse(startDateStr);
        if (startDate == null) {
          return FieldUtils.toJsonString({
            'error': '无效的 startDate 格式，应为 YYYY-MM-DD',
          });
        }
      }

      if (endDateStr != null && endDateStr.isNotEmpty) {
        endDate = DateTime.tryParse(endDateStr);
        if (endDate == null) {
          return FieldUtils.toJsonString({
            'error': '无效的 endDate 格式，应为 YYYY-MM-DD',
          });
        }
        // 包含结束日期的全天
        endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      }

      // 3. 获取记录
      var recordList = await _plugin.controller.getRecords(databaseId);
      var records = recordList.map((r) => r.toMap()).toList();

      // 4. 应用日期过滤
      if (startDate != null || endDate != null) {
        records = _filterRecordsByDateRange(records, startDate, endDate);
      }

      // 5. 应用字段过滤
      Map<String, dynamic> result;

      if (customFields != null && customFields.isNotEmpty) {
        // 优先使用 fields 参数（白名单模式）
        final fieldList = customFields.map((e) => e.toString()).toList();
        final filteredRecords = FieldUtils.simplifyRecords(
          records,
          keepFields: fieldList,
        );
        result = FieldUtils.buildCompactResponse(
          {'total': filteredRecords.length},
          filteredRecords,
        );
      } else {
        // 使用 mode 参数
        result = _convertRecordsByMode(records, mode);
      }

      // 6. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取时间范围内的记录失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取时间范围内的记录时出错',
        'details': e.toString(),
      });
    }
  }

  // ==================== 私有辅助方法 ====================

  /// 获取所有数据库的记录
  Future<List<Map<String, dynamic>>> _getAllRecords() async {
    final allRecords = <Map<String, dynamic>>[];
    final databases = await _plugin.service.getAllDatabases();

    for (final database in databases) {
      final records = await _plugin.controller.getRecords(database.id);
      allRecords.addAll(records.map((r) => r.toMap()).toList());
    }

    return allRecords;
  }

  /// 根据模式转换数据库列表
  Map<String, dynamic> _convertDatabasesByMode(
    List<dynamic> databases,
    AnalysisMode mode,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildDatabasesSummary(databases);
      case AnalysisMode.compact:
        return _buildDatabasesCompact(databases);
      case AnalysisMode.full:
        return _buildDatabasesFull(databases);
    }
  }

  /// 构建数据库摘要数据
  Map<String, dynamic> _buildDatabasesSummary(List<dynamic> databases) {
    // 计算总字段数
    int totalFields = 0;
    for (final db in databases) {
      totalFields += (db.fields as List).length;
    }

    return FieldUtils.buildSummaryResponse({
      'total': databases.length,
      'fieldCnt': totalFields,
    });
  }

  /// 构建数据库紧凑数据
  Map<String, dynamic> _buildDatabasesCompact(List<dynamic> databases) {
    final compactDatabases = databases.map((db) {
      return {
        'id': db.id,
        'name': db.name,
        if (db.description != null && (db.description as String).isNotEmpty)
          'desc': FieldUtils.truncateText(db.description, 100),
        'fieldCnt': (db.fields as List).length,
        'created': FieldUtils.formatDateTime(db.createdAt),
        'updated': FieldUtils.formatDateTime(db.updatedAt),
      };
    }).toList();

    return FieldUtils.buildCompactResponse(
      {
        'total': databases.length,
      },
      compactDatabases,
    );
  }

  /// 构建数据库完整数据
  Map<String, dynamic> _buildDatabasesFull(List<dynamic> databases) {
    return FieldUtils.buildFullResponse(
      databases.map((db) => db.toMap()).toList(),
    );
  }

  /// 根据模式转换记录列表
  Map<String, dynamic> _convertRecordsByMode(
    List<Map<String, dynamic>> records,
    AnalysisMode mode,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildRecordsSummary(records);
      case AnalysisMode.compact:
        return _buildRecordsCompact(records);
      case AnalysisMode.full:
        return _buildRecordsFull(records);
    }
  }

  /// 构建记录摘要数据
  Map<String, dynamic> _buildRecordsSummary(List<Map<String, dynamic>> records) {
    if (records.isEmpty) {
      return FieldUtils.buildSummaryResponse({
        'total': 0,
      });
    }

    // 计算时间范围
    final dates = records
        .map((r) => DateTime.parse(r['createdAt'] as String))
        .toList()
      ..sort();

    return FieldUtils.buildSummaryResponse({
      'total': records.length,
      'timeRange': {
        'start': FieldUtils.formatDateTime(dates.first),
        'end': FieldUtils.formatDateTime(dates.last),
      },
    });
  }

  /// 构建记录紧凑数据
  Map<String, dynamic> _buildRecordsCompact(List<Map<String, dynamic>> records) {
    final compactRecords = records.map((record) {
      final fields = record['fields'] as Map<String, dynamic>;

      // 提取关键字段（最多3个）
      final keyFields = <String, dynamic>{};
      int count = 0;
      for (final entry in fields.entries) {
        if (count >= 3) break;
        keyFields[entry.key] = entry.value;
        count++;
      }

      return {
        'id': record['id'],
        'tableId': record['tableId'],
        'fields': keyFields,
        'created': FieldUtils.formatDateTime(DateTime.parse(record['createdAt'] as String)),
        'updated': FieldUtils.formatDateTime(DateTime.parse(record['updatedAt'] as String)),
      };
    }).toList();

    return FieldUtils.buildCompactResponse(
      {
        'total': records.length,
      },
      compactRecords,
    );
  }

  /// 构建记录完整数据
  Map<String, dynamic> _buildRecordsFull(List<Map<String, dynamic>> records) {
    return FieldUtils.buildFullResponse(records);
  }

  /// 构建数据库统计信息
  Map<String, dynamic> _buildDatabaseStatistics(dynamic database, int recordCount) {
    // 统计字段类型分布
    final fieldTypes = <String, int>{};
    for (final field in database.fields) {
      final type = field.type as String;
      fieldTypes[type] = (fieldTypes[type] ?? 0) + 1;
    }

    return {
      'dbName': database.name,
      'fieldCnt': (database.fields as List).length,
      'recordCnt': recordCount,
      'fieldTypes': fieldTypes,
    };
  }

  /// 构建所有数据库统计信息
  Future<Map<String, dynamic>> _buildAllDatabasesStatistics(List<dynamic> databases) async {
    int totalRecords = 0;
    final fieldTypes = <String, int>{};

    for (final database in databases) {
      // 获取记录数
      final records = await _plugin.controller.getRecords(database.id);
      totalRecords += records.length;

      // 统计字段类型
      for (final field in database.fields) {
        final type = field.type as String;
        fieldTypes[type] = (fieldTypes[type] ?? 0) + 1;
      }
    }

    return {
      'dbCnt': databases.length,
      'totalRecords': totalRecords,
      'avgRecordsPerDb': databases.isEmpty ? 0 : (totalRecords / databases.length).round(),
      'fieldTypes': fieldTypes,
    };
  }

  /// 构建字段统计信息
  Map<String, dynamic> _buildFieldStatistics(
    dynamic field,
    List<dynamic> records,
    String fieldName,
  ) {
    // 收集字段值
    final values = <dynamic>[];
    for (final record in records) {
      final fieldValue = record.fields[fieldName];
      if (fieldValue != null) {
        values.add(fieldValue);
      }
    }

    // 计算唯一值
    final uniqueValues = values.toSet().toList();

    // 计算分布（对于字符串和数字类型）
    final distribution = <dynamic, int>{};
    for (final value in values) {
      distribution[value] = (distribution[value] ?? 0) + 1;
    }

    // 按出现次数排序
    final sortedDistribution = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'fieldName': field.name,
      'type': field.type,
      'totalValues': values.length,
      'uniqueValues': uniqueValues.length,
      'distribution': Map.fromEntries(sortedDistribution.take(10)), // 只取前10个
    };
  }

  /// 过滤记录
  List<Map<String, dynamic>> _filterRecords(
    List<Map<String, dynamic>> records,
    Map<String, dynamic> filters,
  ) {
    return records.where((record) {
      final fields = record['fields'] as Map<String, dynamic>;

      // 检查所有过滤条件是否匹配
      for (final entry in filters.entries) {
        final fieldName = entry.key;
        final expectedValue = entry.value;

        if (!fields.containsKey(fieldName) || fields[fieldName] != expectedValue) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// 按日期范围过滤记录
  List<Map<String, dynamic>> _filterRecordsByDateRange(
    List<Map<String, dynamic>> records,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    return records.where((record) {
      final createdAt = DateTime.parse(record['createdAt'] as String);

      if (startDate != null && createdAt.isBefore(startDate)) {
        return false;
      }

      if (endDate != null && createdAt.isAfter(endDate)) {
        return false;
      }

      return true;
    }).toList();
  }

  /// 释放资源
  void dispose() {}
}
