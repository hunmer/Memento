/// Memento Prompt 字段工具类
///
/// 提供统一的字段命名规范、数据简化和格式转换工具。
/// 用于确保不同插件返回的 Prompt 数据格式一致，减少 token 消耗。
library;

import 'dart:convert';

/// 字段工具类
class FieldUtils {
  FieldUtils._(); // 私有构造函数，禁止实例化

  // ==================== 统一字段命名规范 ====================

  /// 统计数据字段前缀
  static const String summaryPrefix = 'sum';

  /// 记录列表字段名
  static const String recordsField = 'recs';

  /// 常用字段缩写映射
  static const Map<String, String> fieldAbbreviations = {
    // 统计类
    'total': 'total', // 总数（不缩写，常用）
    'count': 'cnt',
    'duration': 'dur',
    'average': 'avg',
    'income': 'inc',
    'expense': 'exp',
    'balance': 'bal',
    'minimum': 'min',
    'maximum': 'max',

    // 记录类
    'records': 'recs',
    'description': 'desc',
    'timestamp': 'ts',
    'status': 'status', // 不缩写
    'priority': 'priority', // 不缩写
    'category': 'cat',
    'quantity': 'qty',

    // 时间类
    'startTime': 'start',
    'endTime': 'end',
    'createdAt': 'created',
    'updatedAt': 'updated',
    'dueDate': 'due',

    // 其他
    'title': 'title', // 不缩写
    'tags': 'tags', // 不缩写
    'notes': 'notes', // 不缩写（作为字段名时）
  };

  // ==================== 数据简化工具 ====================

  /// 截断文本内容
  ///
  /// [text] 原始文本
  /// [maxLength] 最大长度
  /// [suffix] 截断后的后缀（默认"..."）
  static String truncateText(String? text, int maxLength, {String suffix = '...'}) {
    if (text == null || text.isEmpty) {
      return '';
    }

    if (text.length <= maxLength) {
      return text;
    }

    return '${text.substring(0, maxLength)}$suffix';
  }

  /// 简化记录列表 - 移除冗长字段
  ///
  /// [records] 原始记录列表
  /// [removeFields] 要移除的字段列表
  /// [keepFields] 要保留的字段列表（如果指定，则只保留这些字段）
  static List<Map<String, dynamic>> simplifyRecords(
    List<dynamic> records, {
    List<String>? removeFields,
    List<String>? keepFields,
  }) {
    if (records.isEmpty) {
      return [];
    }

    return records.map((record) {
      if (record is! Map) {
        return <String, dynamic>{};
      }

      final recordMap = Map<String, dynamic>.from(record);

      if (keepFields != null && keepFields.isNotEmpty) {
        // 白名单模式：只保留指定字段
        final simplified = <String, dynamic>{};
        for (final field in keepFields) {
          if (recordMap.containsKey(field)) {
            simplified[field] = recordMap[field];
          }
        }
        return simplified;
      } else if (removeFields != null && removeFields.isNotEmpty) {
        // 黑名单模式：移除指定字段
        for (final field in removeFields) {
          recordMap.remove(field);
        }
        return recordMap;
      }

      return recordMap;
    }).toList();
  }

  /// 截断记录列表中的文本字段
  ///
  /// [records] 原始记录列表
  /// [textFields] 需要截断的文本字段列表（如 ['content', 'description']）
  /// [maxLength] 最大长度
  static List<Map<String, dynamic>> truncateRecordFields(
    List<dynamic> records,
    List<String> textFields,
    int maxLength,
  ) {
    if (records.isEmpty || textFields.isEmpty) {
      return records.cast<Map<String, dynamic>>();
    }

    return records.map((record) {
      if (record is! Map) {
        return <String, dynamic>{};
      }

      final recordMap = Map<String, dynamic>.from(record);

      for (final field in textFields) {
        if (recordMap.containsKey(field) && recordMap[field] is String) {
          recordMap[field] = truncateText(
            recordMap[field] as String,
            maxLength,
          );
        }
      }

      return recordMap;
    }).toList();
  }

  // ==================== 格式转换工具 ====================

  /// 构建标准的摘要数据结构
  ///
  /// 返回格式：
  /// ```json
  /// {
  ///   "sum": {
  ///     "total": 100,
  ///     "cnt": 50,
  ///     "dur": 3600
  ///   }
  /// }
  /// ```
  static Map<String, dynamic> buildSummaryResponse(Map<String, dynamic> summary) {
    return {
      summaryPrefix: summary,
    };
  }

  /// 构建标准的紧凑数据结构
  ///
  /// 返回格式：
  /// ```json
  /// {
  ///   "sum": { "total": 10 },
  ///   "recs": [...]
  /// }
  /// ```
  static Map<String, dynamic> buildCompactResponse(
    Map<String, dynamic> summary,
    List<Map<String, dynamic>> records,
  ) {
    return {
      summaryPrefix: summary,
      recordsField: records,
    };
  }

  /// 构建标准的完整数据结构
  ///
  /// 对于完整模式，通常直接返回原始数据，但也可以使用此方法规范化格式
  static Map<String, dynamic> buildFullResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is List) {
      return {
        recordsField: data,
      };
    } else {
      return {
        'data': data,
      };
    }
  }

  // ==================== JSON 序列化工具 ====================

  /// 将数据转换为 JSON 字符串
  ///
  /// [data] 要序列化的数据
  /// [pretty] 是否格式化输出（默认 false，节省 token）
  static String toJsonString(dynamic data, {bool pretty = false}) {
    if (pretty) {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    } else {
      return jsonEncode(data);
    }
  }

  /// 从 JSON 字符串解析数据
  static dynamic fromJsonString(String jsonStr) {
    try {
      return jsonDecode(jsonStr);
    } catch (e) {
      return null;
    }
  }

  // ==================== 数据验证工具 ====================

  /// 验证记录是否包含必需字段
  ///
  /// [record] 要验证的记录
  /// [requiredFields] 必需字段列表
  ///
  /// 返回缺失的字段列表（空列表表示验证通过）
  static List<String> validateRecord(
    Map<String, dynamic> record,
    List<String> requiredFields,
  ) {
    final missingFields = <String>[];

    for (final field in requiredFields) {
      if (!record.containsKey(field) || record[field] == null) {
        missingFields.add(field);
      }
    }

    return missingFields;
  }

  /// 验证日期范围参数
  ///
  /// [params] 参数 Map
  ///
  /// 返回：{startDate: DateTime, endDate: DateTime} 或 null
  static Map<String, DateTime>? parseDateRange(Map<String, dynamic>? params) {
    if (params == null) {
      return null;
    }

    DateTime? startDate;
    DateTime? endDate;

    // 解析 startDate
    if (params.containsKey('startDate')) {
      final startDateStr = params['startDate']?.toString();
      if (startDateStr != null) {
        startDate = DateTime.tryParse(startDateStr);
      }
    }

    // 解析 endDate
    if (params.containsKey('endDate')) {
      final endDateStr = params['endDate']?.toString();
      if (endDateStr != null) {
        endDate = DateTime.tryParse(endDateStr);
      }
    }

    if (startDate == null && endDate == null) {
      return null;
    }

    return {
      'startDate': startDate ?? DateTime.now().subtract(const Duration(days: 7)),
      'endDate': endDate ?? DateTime.now(),
    };
  }

  // ==================== 常用数据转换 ====================

  /// 转换日期时间为 ISO 8601 字符串
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }
    return dateTime.toIso8601String();
  }

  /// 转换时长为可读格式
  ///
  /// [minutes] 分钟数
  ///
  /// 返回格式：
  /// - 小于60分钟："30m"
  /// - 小于24小时："2h 30m"
  /// - 大于24小时："2d 5h"
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else if (minutes < 1440) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    } else {
      final days = minutes ~/ 1440;
      final hours = (minutes % 1440) ~/ 60;
      return hours > 0 ? '${days}d ${hours}h' : '${days}d';
    }
  }

  /// 四舍五入到指定小数位
  static double roundToDecimal(double value, int decimals) {
    final mod = pow10(decimals);
    return (value * mod).round() / mod;
  }

  /// 计算 10 的 n 次方（用于四舍五入）
  static double pow10(int n) {
    double result = 1.0;
    for (int i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }
}

/// 紧凑记录构建器
///
/// 用于构建符合规范的紧凑模式记录对象。
///
/// 使用示例：
/// ```dart
/// final record = CompactRecordBuilder()
///   ..id = 'uuid'
///   ..title = '标题'
///   ..timestamp = DateTime.now()
///   ..tags = ['标签1', '标签2'];
/// ```
class CompactRecordBuilder {
  final Map<String, dynamic> _data = {};

  // 核心字段
  set id(String value) => _data['id'] = value;
  set title(String value) => _data['title'] = value;
  set timestamp(DateTime value) => _data['ts'] = FieldUtils.formatDateTime(value);
  set tags(List<String> value) => _data['tags'] = value;
  set status(String value) => _data['status'] = value;
  set category(String value) => _data['cat'] = value;

  // 时间字段
  set startTime(DateTime value) => _data['start'] = FieldUtils.formatDateTime(value);
  set endTime(DateTime value) => _data['end'] = FieldUtils.formatDateTime(value);
  set dueDate(DateTime value) => _data['due'] = FieldUtils.formatDateTime(value);

  // 自定义字段
  void setCustomField(String key, dynamic value) {
    _data[key] = value;
  }

  /// 构建记录
  Map<String, dynamic> build() {
    return Map<String, dynamic>.from(_data);
  }
}
