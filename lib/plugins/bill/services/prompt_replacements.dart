import 'package:flutter/material.dart';
import '../bill_plugin.dart';
import '../../../core/analysis/analysis_mode.dart';
import '../../../core/analysis/field_utils.dart';

/// Bill插件的Prompt替换服务
///
/// 遵循 Memento Prompt 数据格式规范 v2.0
/// 详见: docs/PROMPT_DATA_SPEC.md
class BillPromptReplacements {
  final BillPlugin _plugin;

  BillPromptReplacements(this._plugin);

  /// 获取账单数据并格式化为文本
  ///
  /// 参数:
  /// - startDate: 开始日期 (可选, YYYY-MM-DD 格式)
  /// - endDate: 结束日期 (可选, YYYY-MM-DD 格式)
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  /// - fields: 自定义返回字段列表 (可选, 优先级高于 mode)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total, inc, exp, net }, topCat: [...] }
  /// - compact: 简化记录 { sum: {...}, recs: [...] }
  /// - full: 完整数据 (包含所有字段)
  /// - fields: 自定义字段 { recs: [...] } (仅包含指定字段)
  Future<String> getBills(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final customFields = params['fields'] as List<dynamic>?;
      final dateRange = _parseDateRange(params);

      // 2. 调用 jsAPI 获取账单数据
      final allBills = await _getBillsInRange(
        dateRange['startDate'],
        dateRange['endDate'],
      );

      // 3. 应用字段过滤
      Map<String, dynamic> result;

      if (customFields != null && customFields.isNotEmpty) {
        // 优先使用 fields 参数（白名单模式）
        final fieldList = customFields.map((e) => e.toString()).toList();
        final filteredRecords = FieldUtils.simplifyRecords(
          allBills,
          keepFields: fieldList,
        );
        result = FieldUtils.buildCompactResponse(
          {'total': filteredRecords.length},
          filteredRecords,
        );
      } else {
        // 使用 mode 参数
        result = _convertByMode(allBills, mode);
      }

      // 4. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取账单数据失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取账单数据时出错',
        'details': e.toString(),
      });
    }
  }

  /// 解析日期范围参数
  Map<String, DateTime?> _parseDateRange(Map<String, dynamic> params) {
    final String? startDateStr = params['startDate'] as String?;
    final String? endDateStr = params['endDate'] as String?;

    DateTime? startDate;
    DateTime? endDate;

    // 解析日期字符串
    if (startDateStr != null) {
      startDate = _parseDate(startDateStr);
    }

    if (endDateStr != null) {
      endDate = _parseDate(endDateStr);
    }

    return {
      'startDate': startDate,
      'endDate': endDate,
    };
  }

  /// 获取指定日期范围内的所有账单
  Future<List<Map<String, dynamic>>> _getBillsInRange(
    DateTime? start,
    DateTime? end,
  ) async {
    try {
      // 直接调用插件的 jsAPI 方法
      final jsAPI = _plugin.defineJSAPI();
      final getBillsFunc = jsAPI['getBills'];

      if (getBillsFunc == null) {
        debugPrint('getBills jsAPI 未定义');
        return [];
      }

      // 调用 jsAPI 获取账单列表
      final String jsonResult = await getBillsFunc(
        null, // accountId (不筛选账户)
        start?.toIso8601String().split('T')[0],
        end?.toIso8601String().split('T')[0],
      );

      // 解析 JSON 结果
      final List<dynamic> bills = FieldUtils.fromJsonString(jsonResult);
      return bills.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('调用 jsAPI 失败: $e');
      return [];
    }
  }

  /// 尝试多种格式解析日期字符串
  DateTime _parseDate(String dateStr) {
    // 尝试解析 yyyy/MM/dd 格式
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {}

    // 尝试解析 yyyy-MM-dd 格式
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {}

    // 尝试使用DateTime.parse
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}

    // 如果所有尝试都失败，抛出异常
    throw FormatException('无法解析日期: $dateStr');
  }

  /// 根据模式转换数据
  Map<String, dynamic> _convertByMode(
    List<Map<String, dynamic>> bills,
    AnalysisMode mode,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildSummary(bills);
      case AnalysisMode.compact:
        return _buildCompact(bills);
      case AnalysisMode.full:
        return _buildFull(bills);
    }
  }

  /// 构建摘要数据 (summary模式)
  ///
  /// 返回格式:
  /// {
  ///   "sum": {
  ///     "total": 100,
  ///     "inc": 5000.00,
  ///     "exp": 3000.00,
  ///     "net": 2000.00
  ///   },
  ///   "topCat": [
  ///     {"cat": "工资", "amt": 5000.00},
  ///     {"cat": "餐饮", "amt": -800.00}
  ///   ]
  /// }
  Map<String, dynamic> _buildSummary(List<Map<String, dynamic>> bills) {
    if (bills.isEmpty) {
      return FieldUtils.buildSummaryResponse({
        'total': 0,
        'inc': 0.0,
        'exp': 0.0,
        'net': 0.0,
      });
    }

    // 计算总收入和总支出
    double totalIncome = 0;
    double totalExpense = 0;
    final Map<String, double> categoryStats = {}; // 按类别统计

    for (final bill in bills) {
      final amount = (bill['amount'] as num?)?.toDouble() ?? 0.0;

      if (amount > 0) {
        totalIncome += amount;
      } else {
        totalExpense += amount.abs();
      }

      // 统计类别
      final category = bill['category'] as String? ?? '未分类';
      categoryStats[category] = (categoryStats[category] ?? 0.0) + amount;
    }

    // 生成类别排行（按金额绝对值降序）
    final topCategories = categoryStats.entries.map((entry) {
      return {
        'cat': entry.key,
        'amt': entry.value,
      };
    }).toList()
      ..sort((a, b) =>
          (b['amt'] as double).abs().compareTo((a['amt'] as double).abs()));

    // 只保留前10个类别
    final topCategoriesLimited = topCategories.take(10).toList();

    return FieldUtils.buildSummaryResponse({
      'total': bills.length,
      'inc': totalIncome,
      'exp': totalExpense,
      'net': totalIncome - totalExpense,
      if (topCategoriesLimited.isNotEmpty) 'topCat': topCategoriesLimited,
    });
  }

  /// 构建紧凑数据 (compact模式)
  ///
  /// 返回格式:
  /// {
  ///   "sum": { "total": 100, "net": 2000.00 },
  ///   "recs": [
  ///     {
  ///       "id": "uuid",
  ///       "title": "午餐",
  ///       "date": "2025-01-15",
  ///       "amount": -35.50,
  ///       "cat": "餐饮",
  ///       "account": "现金"
  ///     }
  ///   ]
  /// }
  Map<String, dynamic> _buildCompact(List<Map<String, dynamic>> bills) {
    if (bills.isEmpty) {
      return FieldUtils.buildCompactResponse(
        {'total': 0, 'net': 0.0},
        [],
      );
    }

    // 计算净余额
    double netBalance = 0;
    for (final bill in bills) {
      final amount = (bill['amount'] as num?)?.toDouble() ?? 0.0;
      netBalance += amount;
    }

    // 简化记录（移除 note, tag, icon 等字段）
    final compactRecords = bills.map((bill) {
      final record = <String, dynamic>{
        'id': bill['id'],
        'title': bill['title'],
        'date': _formatDate(bill['date']),
        'amount': bill['amount'],
        'cat': bill['category'],
      };

      // 只添加非空字段
      if (bill['accountId'] != null) {
        // 尝试获取账户名称
        final accountId = bill['accountId'] as String;
        final account = _plugin.accounts.firstWhere(
          (a) => a.id == accountId,
          orElse: () => null as dynamic,
        );
        if (account != null) {
          record['account'] = account.title;
        }
      }

      return record;
    }).toList();

    return FieldUtils.buildCompactResponse(
      {
        'total': bills.length,
        'net': netBalance,
      },
      compactRecords,
    );
  }

  /// 构建完整数据 (full模式)
  ///
  /// 返回格式: jsAPI 的原始数据
  Map<String, dynamic> _buildFull(List<Map<String, dynamic>> bills) {
    return FieldUtils.buildFullResponse(bills);
  }

  /// 格式化日期为 YYYY-MM-DD
  String _formatDate(dynamic date) {
    if (date is String) {
      // 如果已经是字符串，尝试提取日期部分
      if (date.contains('T')) {
        return date.split('T')[0];
      }
      return date;
    } else if (date is DateTime) {
      return date.toIso8601String().split('T')[0];
    }
    return '';
  }

  /// 释放资源
  void dispose() {}
}
