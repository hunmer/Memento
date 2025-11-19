/// Memento 插件字段过滤混入
///
/// 提供统一的字段过滤逻辑，插件可以混入此类以快速实现字段精简功能。
/// 支持两种过滤模式：
/// 1. **mode 参数**: 使用预定义的数据模式 (summary/compact/full)
/// 2. **fields 参数**: 直接指定返回字段列表（白名单模式，优先级高于 mode）
library;

import 'analysis_mode.dart';
import 'field_utils.dart';

/// 插件字段过滤混入
///
/// 使用示例：
/// ```dart
/// class MyPluginPromptReplacements with PluginFieldFilterMixin {
///   Future<String> getData(Map<String, dynamic> params) async {
///     final data = await _fetchData();
///
///     // 方式 1: 使用辅助方法
///     return applyFieldFilter(
///       data: data,
///       params: params,
///       summaryBuilder: (records) => _buildSummary(records),
///       compactBuilder: (records) => _buildCompact(records),
///     );
///
///     // 方式 2: 手动处理
///     final mode = AnalysisModeUtils.parseFromParams(params);
///     final customFields = params['fields'] as List<dynamic>?;
///
///     if (customFields != null && customFields.isNotEmpty) {
///       return applyCustomFieldsFilter(data, customFields);
///     } else {
///       return applyModeFilter(data, mode, ...);
///     }
///   }
/// }
/// ```
mixin PluginFieldFilterMixin {
  /// 应用字段过滤（统一入口）
  ///
  /// [data] 原始数据（List<Map> 或 Map）
  /// [params] 参数（包含 mode 和 fields）
  /// [summaryBuilder] summary 模式的数据构建器（必需）
  /// [compactBuilder] compact 模式的数据构建器（必需）
  /// [fullBuilder] full 模式的数据构建器（可选，默认使用 FieldUtils.buildFullResponse）
  ///
  /// 返回过滤后的 JSON 字符串
  String applyFieldFilter({
    required dynamic data,
    required Map<String, dynamic> params,
    required Map<String, dynamic> Function(List<Map<String, dynamic>> records) summaryBuilder,
    required Map<String, dynamic> Function(List<Map<String, dynamic>> records) compactBuilder,
    Map<String, dynamic> Function(List<Map<String, dynamic>> records)? fullBuilder,
  }) {
    // 1. 解析参数
    final mode = AnalysisModeUtils.parseFromParams(params);
    final customFields = params['fields'] as List<dynamic>?;

    // 2. 标准化数据为 List<Map>
    final List<Map<String, dynamic>> records = _normalizeData(data);

    // 3. 应用过滤
    Map<String, dynamic> result;

    if (customFields != null && customFields.isNotEmpty) {
      // 优先使用 fields 参数（白名单模式）
      result = applyCustomFieldsFilter(records, customFields);
    } else {
      // 使用 mode 参数
      result = applyModeFilter(
        records,
        mode,
        summaryBuilder: summaryBuilder,
        compactBuilder: compactBuilder,
        fullBuilder: fullBuilder,
      );
    }

    // 4. 返回 JSON 字符串
    return FieldUtils.toJsonString(result);
  }

  /// 应用自定义字段过滤（白名单模式）
  ///
  /// [records] 原始记录列表
  /// [customFields] 自定义字段列表
  ///
  /// 返回格式:
  /// ```json
  /// {
  ///   "sum": { "total": 10 },
  ///   "recs": [{ "field1": "value1", "field2": "value2" }]
  /// }
  /// ```
  Map<String, dynamic> applyCustomFieldsFilter(
    List<Map<String, dynamic>> records,
    List<dynamic> customFields,
  ) {
    final fieldList = customFields.map((e) => e.toString()).toList();
    final filteredRecords = FieldUtils.simplifyRecords(
      records,
      keepFields: fieldList,
    );
    return FieldUtils.buildCompactResponse(
      {'total': filteredRecords.length},
      filteredRecords,
    );
  }

  /// 应用模式过滤
  ///
  /// [records] 原始记录列表
  /// [mode] 分析模式
  /// [summaryBuilder] summary 模式的数据构建器
  /// [compactBuilder] compact 模式的数据构建器
  /// [fullBuilder] full 模式的数据构建器（可选）
  Map<String, dynamic> applyModeFilter(
    List<Map<String, dynamic>> records,
    AnalysisMode mode, {
    required Map<String, dynamic> Function(List<Map<String, dynamic>> records) summaryBuilder,
    required Map<String, dynamic> Function(List<Map<String, dynamic>> records) compactBuilder,
    Map<String, dynamic> Function(List<Map<String, dynamic>> records)? fullBuilder,
  }) {
    switch (mode) {
      case AnalysisMode.summary:
        return summaryBuilder(records);
      case AnalysisMode.compact:
        return compactBuilder(records);
      case AnalysisMode.full:
        if (fullBuilder != null) {
          return fullBuilder(records);
        }
        return FieldUtils.buildFullResponse(records);
    }
  }

  /// 标准化数据为 List of Map
  ///
  /// 支持的输入类型：
  /// - List of Map (String -> dynamic): 直接返回
  /// - List of dynamic: 转换为 List of Map
  /// - Map (String -> dynamic): 包装为单元素列表
  /// - 其他: 返回空列表
  List<Map<String, dynamic>> _normalizeData(dynamic data) {
    if (data is List<Map<String, dynamic>>) {
      return data;
    } else if (data is List) {
      return data.map((e) {
        if (e is Map<String, dynamic>) {
          return e;
        } else if (e is Map) {
          return Map<String, dynamic>.from(e);
        } else {
          return <String, dynamic>{};
        }
      }).toList();
    } else if (data is Map<String, dynamic>) {
      return [data];
    } else if (data is Map) {
      return [Map<String, dynamic>.from(data)];
    } else {
      return [];
    }
  }

  /// 从参数中提取字段列表
  ///
  /// 支持的参数格式：
  /// - params['fields']: List of String 或 List of dynamic
  /// - 返回 null 表示未指定字段
  List<String>? extractFieldsFromParams(Map<String, dynamic> params) {
    final customFields = params['fields'];
    if (customFields == null) {
      return null;
    }

    if (customFields is List) {
      if (customFields.isEmpty) {
        return null;
      }
      return customFields.map((e) => e.toString()).toList();
    }

    return null;
  }

  /// 验证字段名是否有效
  ///
  /// [fieldName] 字段名
  /// [validFields] 有效字段列表（可选）
  ///
  /// 如果提供了 validFields，则检查 fieldName 是否在列表中；
  /// 否则只检查 fieldName 是否为非空字符串。
  bool isValidField(String fieldName, [List<String>? validFields]) {
    if (fieldName.isEmpty) {
      return false;
    }

    if (validFields != null) {
      return validFields.contains(fieldName);
    }

    return true;
  }

  /// 构建紧凑记录的辅助方法
  ///
  /// [records] 原始记录列表
  /// [removeFields] 要移除的字段列表
  ///
  /// 返回移除指定字段后的记录列表
  List<Map<String, dynamic>> buildCompactRecords(
    List<Map<String, dynamic>> records,
    List<String> removeFields,
  ) {
    return FieldUtils.simplifyRecords(records, removeFields: removeFields);
  }

  /// 构建摘要数据的辅助方法
  ///
  /// [summary] 摘要数据 Map
  ///
  /// 返回标准的摘要数据结构
  Map<String, dynamic> buildSummary(Map<String, dynamic> summary) {
    return FieldUtils.buildSummaryResponse(summary);
  }

  /// 构建紧凑数据的辅助方法
  ///
  /// [summary] 摘要数据 Map
  /// [records] 记录列表
  ///
  /// 返回标准的紧凑数据结构
  Map<String, dynamic> buildCompact(
    Map<String, dynamic> summary,
    List<Map<String, dynamic>> records,
  ) {
    return FieldUtils.buildCompactResponse(summary, records);
  }

  /// 构建完整数据的辅助方法
  ///
  /// [data] 数据（List 或 Map）
  ///
  /// 返回标准的完整数据结构
  Map<String, dynamic> buildFull(dynamic data) {
    return FieldUtils.buildFullResponse(data);
  }
}

/// 简化的字段过滤混入（仅提供核心功能）
///
/// 适用于简单场景，不需要完整的构建器模式。
///
/// 使用示例：
/// ```dart
/// class SimplePromptReplacements with SimpleFieldFilterMixin {
///   Future<String> getData(Map<String, dynamic> params) async {
///     final records = await _fetchRecords();
///     return filterAndSerialize(records, params);
///   }
/// }
/// ```
mixin SimpleFieldFilterMixin {
  /// 过滤并序列化数据
  ///
  /// [records] 原始记录列表
  /// [params] 参数（包含 mode 和 fields）
  /// [defaultMode] 默认模式（未指定时使用）
  ///
  /// 返回 JSON 字符串
  String filterAndSerialize(
    List<Map<String, dynamic>> records,
    Map<String, dynamic> params, {
    AnalysisMode defaultMode = AnalysisMode.summary,
  }) {
    final mode = AnalysisModeUtils.parseFromParams(params);
    final customFields = params['fields'] as List<dynamic>?;

    Map<String, dynamic> result;

    if (customFields != null && customFields.isNotEmpty) {
      // 使用 fields 参数
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
      switch (mode) {
        case AnalysisMode.summary:
          result = FieldUtils.buildSummaryResponse({'total': records.length});
          break;
        case AnalysisMode.compact:
        case AnalysisMode.full:
          result = FieldUtils.buildFullResponse(records);
          break;
      }
    }

    return FieldUtils.toJsonString(result);
  }
}
