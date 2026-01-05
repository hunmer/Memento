part of 'database_plugin.dart';

// ==================== JS API 定义 ====================

Map<String, Function> _defineJSAPI() {
  return {
    // 数据库管理
    'getDatabases': _jsGetDatabases,
    'createDatabase': _jsCreateDatabase,
    'updateDatabase': _jsUpdateDatabase,
    'deleteDatabase': _jsDeleteDatabase,

    // 记录管理
    'getRecords': _jsGetRecords,
    'createRecord': _jsCreateRecord,
    'updateRecord': _jsUpdateRecord,
    'deleteRecord': _jsDeleteRecord,

    // 查询功能
    'query': _jsQuery,

    // 统计功能
    'getCount': _jsGetCount,

    // 数据库查找方法
    'findDatabaseBy': _jsFindDatabaseBy,
    'findDatabaseById': _jsFindDatabaseById,
    'findDatabaseByName': _jsFindDatabaseByName,

    // 记录查找方法
    'findRecordBy': _jsFindRecordBy,
    'findRecordById': _jsFindRecordById,
  };
}

// ==================== JS API 实现 ====================

/// 获取所有数据库
/// 支持分页参数: offset, count
Future<String> _jsGetDatabases(Map<String, dynamic> params) async {
  final result = await DatabasePlugin.instance.useCase.getDatabases(params);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message});
  }

  return jsonEncode(result.dataOrNull);
}

/// 创建数据库
Future<String> _jsCreateDatabase(Map<String, dynamic> params) async {
  final result = await DatabasePlugin.instance.useCase.createDatabase(params);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message});
  }

  return jsonEncode(result.dataOrNull);
}

/// 更新数据库
Future<String> _jsUpdateDatabase(Map<String, dynamic> params) async {
  final result = await DatabasePlugin.instance.useCase.updateDatabase(params);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message});
  }

  return jsonEncode(result.dataOrNull);
}

/// 删除数据库
Future<String> _jsDeleteDatabase(Map<String, dynamic> params) async {
  final result = await DatabasePlugin.instance.useCase.deleteDatabase(params);

  if (result.isFailure) {
    return jsonEncode({'success': false, 'error': result.errorOrNull?.message});
  }

  return jsonEncode({'success': true});
}

/// 获取数据库的所有记录
/// 支持分页参数: offset, count
Future<String> _jsGetRecords(Map<String, dynamic> params) async {
  final result = await DatabasePlugin.instance.useCase.getRecords(params);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message});
  }

  return jsonEncode(result.dataOrNull);
}

/// 创建记录
Future<String> _jsCreateRecord(Map<String, dynamic> params) async {
  final result = await DatabasePlugin.instance.useCase.createRecord(params);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message});
  }

  return jsonEncode(result.dataOrNull);
}

/// 更新记录
Future<String> _jsUpdateRecord(Map<String, dynamic> params) async {
  final result = await DatabasePlugin.instance.useCase.updateRecord(params);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message});
  }

  return jsonEncode(result.dataOrNull);
}

/// 删除记录
Future<String> _jsDeleteRecord(Map<String, dynamic> params) async {
  final result = await DatabasePlugin.instance.useCase.deleteRecord(params);

  if (result.isFailure) {
    return jsonEncode({'success': false, 'error': result.errorOrNull?.message});
  }

  return jsonEncode({'success': true});
}

/// 查询记录
/// 支持分页参数: offset, count
Future<String> _jsQuery(Map<String, dynamic> params) async {
  final result = await DatabasePlugin.instance.useCase.searchRecords(params);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message});
  }

  return jsonEncode(result.dataOrNull);
}

/// 获取数据库或记录数量
Future<int> _jsGetCount(Map<String, dynamic> params) async {
  // 必需参数
  final String? type = params['type'];
  if (type == null) {
    return 0;
  }

  // 可选参数
  final String? databaseId = params['databaseId'];

  if (type == 'databases') {
    return await DatabasePlugin.instance.service.getDatabaseCount();
  } else if (type == 'records' && databaseId != null) {
    final records = await DatabasePlugin.instance.controller.getRecords(databaseId);
    return records.length;
  }
  return 0;
}

// ==================== 数据库查找方法 ====================

/// 通用数据库查找
/// 支持分页参数: offset, count (仅 findAll=true 时有效)
Future<String> _jsFindDatabaseBy(Map<String, dynamic> params) async {
  try {
    final String? field = params['field'];
    if (field == null || field.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: field'});
    }

    final dynamic value = params['value'];
    if (value == null) {
      return jsonEncode({'error': '缺少必需参数: value'});
    }

    final bool findAll = params['findAll'] ?? false;

    // 使用 UseCase 搜索数据库
    final searchParams = <String, dynamic>{};
    if (field == 'name') {
      searchParams['nameKeyword'] = value.toString();
    }

    final result = await DatabasePlugin.instance.useCase.searchDatabases(searchParams);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    var databases = result.dataOrNull as List;
    // 过滤匹配字段
    databases = databases.where((db) {
      final dbMap = db as Map<String, dynamic>;
      return dbMap.containsKey(field) && dbMap[field] == value;
    }).toList();

    if (findAll) {
      return jsonEncode(databases);
    } else {
      return databases.isEmpty
          ? jsonEncode(null)
          : jsonEncode(databases.first);
    }
  } catch (e) {
    return jsonEncode({'error': '查找数据库失败: $e'});
  }
}

/// 根据 ID 查找数据库
Future<String> _jsFindDatabaseById(Map<String, dynamic> params) async {
  final result = await DatabasePlugin.instance.useCase.getDatabaseById(params);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message});
  }

  return jsonEncode(result.dataOrNull);
}

/// 根据名称查找数据库
/// 支持分页参数: offset, count (仅 findAll=true 时有效)
Future<String> _jsFindDatabaseByName(Map<String, dynamic> params) async {
  try {
    final String? name = params['name'];
    if (name == null || name.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: name'});
    }

    final bool fuzzy = params['fuzzy'] ?? false;
    final bool findAll = params['findAll'] ?? false;

    // 使用 UseCase 搜索数据库
    final searchParams = <String, dynamic>{'nameKeyword': name};

    final result = await DatabasePlugin.instance.useCase.searchDatabases(searchParams);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    var databases = result.dataOrNull as List;
    // 如果不是模糊搜索，进一步过滤精确匹配
    if (!fuzzy) {
      databases = databases.where((db) {
        final dbMap = db as Map<String, dynamic>;
        return dbMap['name'] == name;
      }).toList();
    }

    if (findAll) {
      return jsonEncode(databases);
    } else {
      return databases.isEmpty
          ? jsonEncode(null)
          : jsonEncode(databases.first);
    }
  } catch (e) {
    return jsonEncode({'error': '查找数据库失败: $e'});
  }
}

// ==================== 记录查找方法 ====================

/// 通用记录查找
/// 支持分页参数: offset, count (仅 findAll=true 时有效)
Future<String> _jsFindRecordBy(Map<String, dynamic> params) async {
  try {
    final String? databaseId = params['databaseId'];
    if (databaseId == null || databaseId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: databaseId'});
    }

    final String? field = params['field'];
    if (field == null || field.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: field'});
    }

    final dynamic value = params['value'];
    if (value == null) {
      return jsonEncode({'error': '缺少必需参数: value'});
    }

    final bool findAll = params['findAll'] ?? false;

    // 使用 UseCase 搜索记录
    final searchParams = <String, dynamic>{
      'tableId': databaseId,
      'fieldKeyword': value.toString(),
    };

    final result = await DatabasePlugin.instance.useCase.searchRecords(searchParams);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    var records = result.dataOrNull as List;
    // 进一步过滤匹配字段
    records = records.where((record) {
      final recordMap = record as Map<String, dynamic>;
      // 检查内置字段
      if (recordMap.containsKey(field) && recordMap[field] == value) {
        return true;
      }
      // 检查自定义字段
      final fields = recordMap['fields'] as Map<String, dynamic>?;
      return fields?.containsKey(field) == true && fields![field] == value;
    }).toList();

    if (findAll) {
      return jsonEncode(records);
    } else {
      return records.isEmpty
          ? jsonEncode(null)
          : jsonEncode(records.first);
    }
  } catch (e) {
    return jsonEncode({'error': '查找记录失败: $e'});
  }
}

/// 根据 ID 查找记录
Future<String> _jsFindRecordById(Map<String, dynamic> params) async {
  final result = await DatabasePlugin.instance.useCase.getRecordById(params);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message});
  }

  return jsonEncode(result.dataOrNull);
}
