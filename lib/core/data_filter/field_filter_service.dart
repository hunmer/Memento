/// 通用字段过滤服务
///
/// 为 jsAPI 提供统一的数据过滤能力，支持：
/// - 字段白名单/黑名单过滤
/// - 数据模式切换（summary/compact/full）
/// - 文本截断
/// - 统计摘要生成
library;

import 'dart:convert';

import '../analysis/field_utils.dart';
import 'filter_options.dart';

/// 字段过滤服务
class FieldFilterService {
  FieldFilterService._(); // 私有构造函数，禁止实例化

  /// 紧凑模式默认移除的字段
  static const List<String> _defaultExcludeFieldsInCompact = [
    'description',
    'content',
    'notes',
    'metadata',
    'detail',
    'remark',
  ];

  /// 过滤数据（统一入口）
  ///
  /// [data] 原始数据（支持 List、Map、基本类型、JSON字符串）
  /// [options] 过滤选项
  ///
  /// 返回过滤后的数据
  static dynamic filterData(
    dynamic data,
    FilterOptions options,
  ) {
    // 如果不需要过滤，直接返回
    if (!options.needsFiltering) {
      return data;
    }

    // 如果是 JSON 字符串，先尝试解析
    dynamic parsedData = data;
    if (data is String) {
      try {
        // 使用 dart:convert 解析 JSON
        parsedData = _parseJson(data);
      } catch (e) {
        // 如果解析失败，可能是普通字符串，直接返回
        return data;
      }
    }

    // 根据数据类型分发处理
    if (parsedData is List) {
      return _filterList(parsedData, options);
    } else if (parsedData is Map<String, dynamic>) {
      return _filterMap(parsedData, options);
    } else if (parsedData is Map) {
      return _filterMap(Map<String, dynamic>.from(parsedData), options);
    } else {
      // 基本类型直接返回
      return parsedData;
    }
  }

  /// 解析 JSON 字符串
  ///
  /// 尝试将字符串解析为 List 或 Map
  static dynamic _parseJson(String jsonStr) {
    return jsonDecode(jsonStr);
  }

  /// 过滤列表数据
  static dynamic _filterList(List<dynamic> list, FilterOptions options) {
    if (list.isEmpty) {
      return _buildEmptyResponse(options);
    }

    // Summary 模式：只返回统计摘要
    if (options.isSummaryOnly) {
      return _generateSummary(list, options);
    }

    // 过滤每个记录
    final filteredList = list.map((item) {
      if (item is Map<String, dynamic>) {
        return _filterRecord(item, options);
      } else if (item is Map) {
        return _filterRecord(Map<String, dynamic>.from(item), options);
      } else {
        return item;
      }
    }).toList();

    // Compact/Full 模式：返回摘要 + 记录
    if (options.generateSummary) {
      return {
        'sum': _calculateSummary(filteredList),
        'recs': filteredList,
      };
    } else {
      return filteredList;
    }
  }

  /// 过滤 Map 数据
  static Map<String, dynamic> _filterMap(
    Map<String, dynamic> map,
    FilterOptions options,
  ) {
    // 检查是否已经是响应格式 {sum: {...}, recs: [...]}
    if (map.containsKey('sum') && map.containsKey('recs')) {
      // 递归过滤 recs
      final recs = map['recs'];
      if (recs is List) {
        return {
          'sum': map['sum'],
          'recs': _filterList(recs, options.copyWith(generateSummary: false)),
        };
      }
    }

    // 单个记录，直接过滤
    return _filterRecord(map, options);
  }

  /// 过滤单条记录
  static Map<String, dynamic> _filterRecord(
    Map<String, dynamic> record,
    FilterOptions options,
  ) {
    Map<String, dynamic> filtered = {};

    // 白名单模式（优先级最高）
    if (options.fields != null && options.fields!.isNotEmpty) {
      for (final field in options.fields!) {
        if (record.containsKey(field)) {
          filtered[field] = record[field];
        }
      }
      return _processTextFields(filtered, options);
    }

    // 复制所有字段
    filtered = Map<String, dynamic>.from(record);

    // 黑名单模式
    final excludeFields = _getExcludeFields(options);
    for (final field in excludeFields) {
      filtered.remove(field);
    }

    // 处理文本字段
    filtered = _processTextFields(filtered, options);

    // 缩短字段名（可选）
    if (options.abbreviateFieldNames) {
      filtered = _abbreviateFieldNames(filtered);
    }

    return filtered;
  }

  /// 获取要排除的字段列表
  static List<String> _getExcludeFields(FilterOptions options) {
    final excludeFields = <String>[];

    // Compact 模式的默认排除字段
    if (options.mode == FilterMode.compact) {
      excludeFields.addAll(_defaultExcludeFieldsInCompact);
    }

    // 用户指定的排除字段
    if (options.excludeFields != null) {
      excludeFields.addAll(options.excludeFields!);
    }

    return excludeFields;
  }

  /// 处理文本字段（截断）
  static Map<String, dynamic> _processTextFields(
    Map<String, dynamic> record,
    FilterOptions options,
  ) {
    if (options.textLengthLimits == null ||
        options.textLengthLimits!.isEmpty) {
      return record;
    }

    final processed = Map<String, dynamic>.from(record);

    options.textLengthLimits!.forEach((field, maxLength) {
      if (processed.containsKey(field) && processed[field] is String) {
        final text = processed[field] as String;
        if (text.length > maxLength) {
          processed[field] = FieldUtils.truncateText(text, maxLength);
        }
      }
    });

    return processed;
  }

  /// 缩短字段名
  static Map<String, dynamic> _abbreviateFieldNames(
    Map<String, dynamic> record,
  ) {
    final abbreviated = <String, dynamic>{};

    record.forEach((key, value) {
      final abbrevKey = FieldUtils.fieldAbbreviations[key] ?? key;
      abbreviated[abbrevKey] = value;
    });

    return abbreviated;
  }

  /// 生成统计摘要
  static Map<String, dynamic> _generateSummary(
    List<dynamic> list,
    FilterOptions options,
  ) {
    final summary = _calculateSummary(list);
    return FieldUtils.buildSummaryResponse(summary);
  }

  /// 计算统计数据
  static Map<String, dynamic> _calculateSummary(List<dynamic> list) {
    final summary = <String, dynamic>{
      'total': list.length,
    };

    // 尝试计算常见统计字段
    if (list.isNotEmpty && list.first is Map) {
      // 统计数值字段的总和
      final numericFields = <String, num>{};
      for (final item in list) {
        if (item is! Map) continue;

        item.forEach((key, value) {
          if (value is num) {
            numericFields[key] = (numericFields[key] ?? 0) + value;
          }
        });
      }

      // 添加常见的统计字段
      if (numericFields.containsKey('amount')) {
        summary['totalAmount'] = numericFields['amount'];
      }
      if (numericFields.containsKey('duration')) {
        summary['totalDuration'] = numericFields['duration'];
      }
      if (numericFields.containsKey('dur')) {
        summary['dur'] = numericFields['dur'];
      }
    }

    return summary;
  }

  /// 构建空响应
  static Map<String, dynamic> _buildEmptyResponse(FilterOptions options) {
    if (options.isSummaryOnly) {
      return FieldUtils.buildSummaryResponse({'total': 0});
    } else if (options.generateSummary) {
      return FieldUtils.buildCompactResponse({'total': 0}, []);
    } else {
      return {};
    }
  }

  /// 从参数中提取过滤选项并应用过滤
  ///
  /// 便捷方法，用于直接从 jsAPI 参数中提取过滤选项
  ///
  /// [data] 原始数据
  /// [params] 参数 Map（包含 mode、fields 等）
  ///
  /// 返回过滤后的数据
  static dynamic filterFromParams(
    dynamic data,
    Map<String, dynamic>? params,
  ) {
    final options = FilterOptions.fromParams(params);
    return filterData(data, options);
  }

  /// 清理参数（移除过滤相关的参数）
  ///
  /// 用于从参数中移除过滤选项，避免传递给底层方法
  ///
  /// [params] 原始参数
  ///
  /// 返回清理后的参数
  static Map<String, dynamic> cleanParams(Map<String, dynamic>? params) {
    if (params == null) {
      return {};
    }

    final cleaned = Map<String, dynamic>.from(params);
    cleaned.remove('mode');
    cleaned.remove('fields');
    cleaned.remove('excludeFields');
    cleaned.remove('textLengthLimits');
    cleaned.remove('generateSummary');
    cleaned.remove('abbreviateFieldNames');

    return cleaned;
  }
}
