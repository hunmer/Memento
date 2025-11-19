import 'package:flutter/material.dart';
import '../store_plugin.dart';
import '../../../core/analysis/analysis_mode.dart';
import '../../../core/analysis/field_utils.dart';

/// Store插件的Prompt替换服务
///
/// 遵循 Memento Prompt 数据格式规范 v2.0
/// 详见: docs/PROMPT_DATA_SPEC.md
class StorePromptReplacements {
  final StorePlugin _plugin;

  StorePromptReplacements(this._plugin);

  /// 获取商品列表并格式化为文本
  ///
  /// 参数:
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  /// - fields: 自定义返回字段列表 (可选, 优先级高于 mode)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total, avgPrice, totalStock } }
  /// - compact: 简化记录 { sum: {...}, recs: [...] } (无description)
  /// - full: 完整数据 (包含所有字段)
  /// - fields: 自定义字段 { recs: [...] } (仅包含指定字段)
  Future<String> getProducts(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final customFields = params['fields'] as List<dynamic>?;

      // 2. 获取商品数据
      final products = _plugin.controller.products;

      // 3. 应用字段过滤
      Map<String, dynamic> result;

      if (customFields != null && customFields.isNotEmpty) {
        // 优先使用 fields 参数
        final fieldList = customFields.map((e) => e.toString()).toList();
        final filteredRecords = FieldUtils.simplifyRecords(
          products.map((p) => p.toJson()).toList(),
          keepFields: fieldList,
        );
        result = FieldUtils.buildCompactResponse(
          {'total': filteredRecords.length},
          filteredRecords,
        );
      } else {
        // 使用 mode 参数
        result = _convertProductsByMode(products, mode);
      }

      // 4. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取商品列表失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取商品列表时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取用户物品列表并格式化为文本
  ///
  /// 参数:
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total, expiring } }
  /// - compact: 简化记录 { sum: {...}, recs: [...] }
  /// - full: 完整数据 (包含所有字段)
  Future<String> getUserItems(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);

      // 2. 获取用户物品数据
      final userItems = _plugin.controller.userItems;

      // 3. 根据模式转换数据
      final result = _convertUserItemsByMode(userItems, mode);

      // 4. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取用户物品列表失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取用户物品列表时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取积分历史并格式化为文本
  ///
  /// 参数:
  /// - startDate: 开始日期 (可选, YYYY-MM-DD 格式)
  /// - endDate: 结束日期 (可选, YYYY-MM-DD 格式)
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total, gained, consumed } }
  /// - compact: 简化记录 { sum: {...}, recs: [...] }
  /// - full: 完整数据 (包含所有字段)
  Future<String> getPointsHistory(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final dateRange = _parseDateRange(params);

      // 2. 获取积分历史
      final allLogs = _plugin.controller.pointsLogs;

      // 3. 按日期范围过滤
      final filteredLogs = dateRange != null
          ? allLogs.where((log) {
              return !log.timestamp.isBefore(dateRange['startDate']!) &&
                  !log.timestamp.isAfter(dateRange['endDate']!);
            }).toList()
          : allLogs;

      // 4. 根据模式转换数据
      final result = _convertPointsLogsByMode(filteredLogs, mode);

      // 5. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取积分历史失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取积分历史时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取兑换历史并格式化为文本
  ///
  /// 参数:
  /// - startDate: 开始日期 (可选, YYYY-MM-DD 格式)
  /// - endDate: 结束日期 (可选, YYYY-MM-DD 格式)
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total, totalCost } }
  /// - compact: 简化记录 { sum: {...}, recs: [...] }
  /// - full: 完整数据 (包含所有字段)
  Future<String> getRedeemHistory(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final dateRange = _parseDateRange(params);

      // 2. 获取用户物品（代表兑换历史）
      final allItems = _plugin.controller.userItems;

      // 3. 按日期范围过滤
      final filteredItems = dateRange != null
          ? allItems.where((item) {
              return !item.purchaseDate.isBefore(dateRange['startDate']!) &&
                  !item.purchaseDate.isAfter(dateRange['endDate']!);
            }).toList()
          : allItems;

      // 4. 根据模式转换数据
      final result = _convertRedeemHistoryByMode(filteredItems, mode);

      // 5. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取兑换历史失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取兑换历史时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取积分统计并格式化为文本
  ///
  /// 参数:
  /// - startDate: 开始日期 (可选, YYYY-MM-DD 格式)
  /// - endDate: 结束日期 (可选, YYYY-MM-DD 格式)
  ///
  /// 返回格式: { sum: { current, gained, consumed, netChange } }
  Future<String> getPointsStats(Map<String, dynamic> params) async {
    try {
      // 1. 解析日期范围
      final dateRange = _parseDateRange(params);

      // 2. 获取积分历史
      final allLogs = _plugin.controller.pointsLogs;

      // 3. 按日期范围过滤
      final filteredLogs = dateRange != null
          ? allLogs.where((log) {
              return !log.timestamp.isBefore(dateRange['startDate']!) &&
                  !log.timestamp.isAfter(dateRange['endDate']!);
            }).toList()
          : allLogs;

      // 4. 计算统计数据
      int gained = 0;
      int consumed = 0;

      for (final log in filteredLogs) {
        if (log.type == '获得') {
          gained += log.value;
        } else if (log.type == '消耗' || log.type == '失去') {
          consumed += log.value.abs();
        }
      }

      final result = FieldUtils.buildSummaryResponse({
        'current': _plugin.controller.currentPoints,
        'gained': gained,
        'consumed': consumed,
        'netChange': gained - consumed,
      });

      // 5. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取积分统计失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取积分统计时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取归档商品列表并格式化为文本
  ///
  /// 参数:
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total } }
  /// - compact: 简化记录 { sum: {...}, recs: [...] }
  /// - full: 完整数据 (包含所有字段)
  Future<String> getArchivedProducts(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);

      // 2. 获取归档商品数据
      final archivedProducts = _plugin.controller.archivedProducts;

      // 3. 根据模式转换数据
      final result = _convertProductsByMode(archivedProducts, mode);

      // 4. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取归档商品列表失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取归档商品列表时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取即将过期的物品并格式化为文本
  ///
  /// 参数:
  /// - days: 天数 (默认7天)
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total, days } }
  /// - compact: 简化记录 { sum: {...}, recs: [...] }
  /// - full: 完整数据 (包含所有字段)
  Future<String> getExpiringItems(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final days = (params['days'] as num?)?.toInt() ?? 7;

      // 2. 计算过期时间范围
      final now = DateTime.now();
      final expiryThreshold = now.add(Duration(days: days));

      // 3. 获取即将过期的物品
      final expiringItems = _plugin.controller.userItems.where((item) {
        return item.expireDate.isAfter(now) &&
            item.expireDate.isBefore(expiryThreshold);
      }).toList();

      // 4. 根据模式转换数据
      final result = _convertExpiringItemsByMode(expiringItems, mode, days);

      // 5. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取即将过期物品失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取即将过期物品时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取使用历史并格式化为文本
  ///
  /// 参数:
  /// - startDate: 开始日期 (可选, YYYY-MM-DD 格式)
  /// - endDate: 结束日期 (可选, YYYY-MM-DD 格式)
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total } }
  /// - compact: 简化记录 { sum: {...}, recs: [...] }
  /// - full: 完整数据 (包含所有字段)
  Future<String> getUsageHistory(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final dateRange = _parseDateRange(params);

      // 2. 获取使用历史
      final allUsedItems = _plugin.controller.usedItems;

      // 3. 按日期范围过滤
      final filteredItems = dateRange != null
          ? allUsedItems.where((item) {
              return !item.useDate.isBefore(dateRange['startDate']!) &&
                  !item.useDate.isAfter(dateRange['endDate']!);
            }).toList()
          : allUsedItems;

      // 4. 根据模式转换数据
      final result = _convertUsageHistoryByMode(filteredItems, mode);

      // 5. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取使用历史失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取使用历史时出错',
        'details': e.toString(),
      });
    }
  }

  /// 解析日期范围参数
  Map<String, DateTime>? _parseDateRange(Map<String, dynamic> params) {
    final String? startDateStr = params['startDate'] as String?;
    final String? endDateStr = params['endDate'] as String?;

    DateTime? startDate;
    DateTime? endDate;

    // 解析日期字符串
    if (startDateStr != null && startDateStr.isNotEmpty) {
      startDate = _parseDate(startDateStr);
    }

    if (endDateStr != null && endDateStr.isNotEmpty) {
      endDate = _parseDate(endDateStr);
    }

    // 如果两个日期都没有提供，返回 null
    if (startDate == null && endDate == null) {
      return null;
    }

    // 如果只提供了一个日期，另一个设为极值
    startDate ??= DateTime(2000, 1, 1);
    endDate ??= DateTime.now().add(const Duration(days: 365));

    return {
      'startDate': startDate,
      'endDate': endDate,
    };
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

  /// 根据模式转换商品数据
  Map<String, dynamic> _convertProductsByMode(
    List<dynamic> products,
    AnalysisMode mode,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildProductsSummary(products);
      case AnalysisMode.compact:
        return _buildProductsCompact(products);
      case AnalysisMode.full:
        return _buildProductsFull(products);
    }
  }

  /// 构建商品摘要数据
  Map<String, dynamic> _buildProductsSummary(List<dynamic> products) {
    if (products.isEmpty) {
      return FieldUtils.buildSummaryResponse({
        'total': 0,
        'avgPrice': 0,
        'totalStock': 0,
      });
    }

    int totalPrice = 0;
    int totalStock = 0;

    for (final product in products) {
      totalPrice += product.price as int;
      totalStock += product.stock as int;
    }

    return FieldUtils.buildSummaryResponse({
      'total': products.length,
      'avgPrice': (totalPrice / products.length).round(),
      'totalStock': totalStock,
    });
  }

  /// 构建商品紧凑数据
  Map<String, dynamic> _buildProductsCompact(List<dynamic> products) {
    if (products.isEmpty) {
      return FieldUtils.buildCompactResponse(
        {'total': 0},
        [],
      );
    }

    final compactRecords = products.map((product) {
      return {
        'id': product.id,
        'name': product.name,
        'price': product.price,
        'stock': product.stock,
        'start': FieldUtils.formatDateTime(product.exchangeStart),
        'end': FieldUtils.formatDateTime(product.exchangeEnd),
        'dur': product.useDuration,
      };
    }).toList();

    return FieldUtils.buildCompactResponse(
      {'total': products.length},
      compactRecords,
    );
  }

  /// 构建商品完整数据
  Map<String, dynamic> _buildProductsFull(List<dynamic> products) {
    final fullRecords = products.map((product) => product.toJson()).toList();
    return FieldUtils.buildFullResponse(fullRecords);
  }

  /// 根据模式转换用户物品数据
  Map<String, dynamic> _convertUserItemsByMode(
    List<dynamic> userItems,
    AnalysisMode mode,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildUserItemsSummary(userItems);
      case AnalysisMode.compact:
        return _buildUserItemsCompact(userItems);
      case AnalysisMode.full:
        return _buildUserItemsFull(userItems);
    }
  }

  /// 构建用户物品摘要数据
  Map<String, dynamic> _buildUserItemsSummary(List<dynamic> userItems) {
    if (userItems.isEmpty) {
      return FieldUtils.buildSummaryResponse({
        'total': 0,
        'expiring': 0,
      });
    }

    final now = DateTime.now();
    final sevenDaysLater = now.add(const Duration(days: 7));
    final expiringCount = userItems.where((item) {
      return item.expireDate.isAfter(now) &&
          item.expireDate.isBefore(sevenDaysLater);
    }).length;

    return FieldUtils.buildSummaryResponse({
      'total': userItems.length,
      'expiring': expiringCount,
    });
  }

  /// 构建用户物品紧凑数据
  Map<String, dynamic> _buildUserItemsCompact(List<dynamic> userItems) {
    if (userItems.isEmpty) {
      return FieldUtils.buildCompactResponse(
        {'total': 0},
        [],
      );
    }

    final compactRecords = userItems.map((item) {
      return {
        'id': item.id,
        'name': item.productName,
        'remaining': item.remaining,
        'expire': FieldUtils.formatDateTime(item.expireDate),
        'purchased': FieldUtils.formatDateTime(item.purchaseDate),
        'price': item.purchasePrice,
      };
    }).toList();

    return FieldUtils.buildCompactResponse(
      {'total': userItems.length},
      compactRecords,
    );
  }

  /// 构建用户物品完整数据
  Map<String, dynamic> _buildUserItemsFull(List<dynamic> userItems) {
    final fullRecords = userItems.map((item) => item.toJson()).toList();
    return FieldUtils.buildFullResponse(fullRecords);
  }

  /// 根据模式转换积分历史数据
  Map<String, dynamic> _convertPointsLogsByMode(
    List<dynamic> logs,
    AnalysisMode mode,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildPointsLogsSummary(logs);
      case AnalysisMode.compact:
        return _buildPointsLogsCompact(logs);
      case AnalysisMode.full:
        return _buildPointsLogsFull(logs);
    }
  }

  /// 构建积分历史摘要数据
  Map<String, dynamic> _buildPointsLogsSummary(List<dynamic> logs) {
    if (logs.isEmpty) {
      return FieldUtils.buildSummaryResponse({
        'total': 0,
        'gained': 0,
        'consumed': 0,
      });
    }

    int gained = 0;
    int consumed = 0;

    for (final log in logs) {
      if (log.type == '获得') {
        gained += log.value as int;
      } else if (log.type == '消耗' || log.type == '失去') {
        consumed += (log.value as int).abs();
      }
    }

    return FieldUtils.buildSummaryResponse({
      'total': logs.length,
      'gained': gained,
      'consumed': consumed,
    });
  }

  /// 构建积分历史紧凑数据
  Map<String, dynamic> _buildPointsLogsCompact(List<dynamic> logs) {
    if (logs.isEmpty) {
      return FieldUtils.buildCompactResponse(
        {'total': 0},
        [],
      );
    }

    final compactRecords = logs.map((log) {
      return {
        'id': log.id,
        'type': log.type,
        'value': log.value,
        'reason': log.reason,
        'ts': FieldUtils.formatDateTime(log.timestamp),
      };
    }).toList();

    return FieldUtils.buildCompactResponse(
      {'total': logs.length},
      compactRecords,
    );
  }

  /// 构建积分历史完整数据
  Map<String, dynamic> _buildPointsLogsFull(List<dynamic> logs) {
    final fullRecords = logs.map((log) => log.toJson()).toList();
    return FieldUtils.buildFullResponse(fullRecords);
  }

  /// 根据模式转换兑换历史数据
  Map<String, dynamic> _convertRedeemHistoryByMode(
    List<dynamic> items,
    AnalysisMode mode,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildRedeemHistorySummary(items);
      case AnalysisMode.compact:
        return _buildRedeemHistoryCompact(items);
      case AnalysisMode.full:
        return _buildRedeemHistoryFull(items);
    }
  }

  /// 构建兑换历史摘要数据
  Map<String, dynamic> _buildRedeemHistorySummary(List<dynamic> items) {
    if (items.isEmpty) {
      return FieldUtils.buildSummaryResponse({
        'total': 0,
        'totalCost': 0,
      });
    }

    int totalCost = 0;
    for (final item in items) {
      totalCost += item.purchasePrice as int;
    }

    return FieldUtils.buildSummaryResponse({
      'total': items.length,
      'totalCost': totalCost,
    });
  }

  /// 构建兑换历史紧凑数据
  Map<String, dynamic> _buildRedeemHistoryCompact(List<dynamic> items) {
    if (items.isEmpty) {
      return FieldUtils.buildCompactResponse(
        {'total': 0},
        [],
      );
    }

    final compactRecords = items.map((item) {
      return {
        'id': item.id,
        'name': item.productName,
        'price': item.purchasePrice,
        'purchased': FieldUtils.formatDateTime(item.purchaseDate),
      };
    }).toList();

    return FieldUtils.buildCompactResponse(
      {'total': items.length},
      compactRecords,
    );
  }

  /// 构建兑换历史完整数据
  Map<String, dynamic> _buildRedeemHistoryFull(List<dynamic> items) {
    final fullRecords = items.map((item) => item.toJson()).toList();
    return FieldUtils.buildFullResponse(fullRecords);
  }

  /// 根据模式转换即将过期物品数据
  Map<String, dynamic> _convertExpiringItemsByMode(
    List<dynamic> items,
    AnalysisMode mode,
    int days,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildExpiringItemsSummary(items, days);
      case AnalysisMode.compact:
        return _buildExpiringItemsCompact(items, days);
      case AnalysisMode.full:
        return _buildExpiringItemsFull(items);
    }
  }

  /// 构建即将过期物品摘要数据
  Map<String, dynamic> _buildExpiringItemsSummary(
    List<dynamic> items,
    int days,
  ) {
    return FieldUtils.buildSummaryResponse({
      'total': items.length,
      'days': days,
    });
  }

  /// 构建即将过期物品紧凑数据
  Map<String, dynamic> _buildExpiringItemsCompact(
    List<dynamic> items,
    int days,
  ) {
    if (items.isEmpty) {
      return FieldUtils.buildCompactResponse(
        {'total': 0, 'days': days},
        [],
      );
    }

    final compactRecords = items.map((item) {
      final daysLeft =
          item.expireDate.difference(DateTime.now()).inDays;
      return {
        'id': item.id,
        'name': item.productName,
        'expire': FieldUtils.formatDateTime(item.expireDate),
        'daysLeft': daysLeft,
      };
    }).toList();

    return FieldUtils.buildCompactResponse(
      {'total': items.length, 'days': days},
      compactRecords,
    );
  }

  /// 构建即将过期物品完整数据
  Map<String, dynamic> _buildExpiringItemsFull(List<dynamic> items) {
    final fullRecords = items.map((item) => item.toJson()).toList();
    return FieldUtils.buildFullResponse(fullRecords);
  }

  /// 根据模式转换使用历史数据
  Map<String, dynamic> _convertUsageHistoryByMode(
    List<dynamic> items,
    AnalysisMode mode,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildUsageHistorySummary(items);
      case AnalysisMode.compact:
        return _buildUsageHistoryCompact(items);
      case AnalysisMode.full:
        return _buildUsageHistoryFull(items);
    }
  }

  /// 构建使用历史摘要数据
  Map<String, dynamic> _buildUsageHistorySummary(List<dynamic> items) {
    return FieldUtils.buildSummaryResponse({
      'total': items.length,
    });
  }

  /// 构建使用历史紧凑数据
  Map<String, dynamic> _buildUsageHistoryCompact(List<dynamic> items) {
    if (items.isEmpty) {
      return FieldUtils.buildCompactResponse(
        {'total': 0},
        [],
      );
    }

    final compactRecords = items.map((item) {
      return {
        'id': item.id,
        'name': item.productSnapshot['name'] ?? '',
        'useDate': FieldUtils.formatDateTime(item.useDate),
      };
    }).toList();

    return FieldUtils.buildCompactResponse(
      {'total': items.length},
      compactRecords,
    );
  }

  /// 构建使用历史完整数据
  Map<String, dynamic> _buildUsageHistoryFull(List<dynamic> items) {
    final fullRecords = items.map((item) => item.toJson()).toList();
    return FieldUtils.buildFullResponse(fullRecords);
  }

  /// 释放资源
  void dispose() {}
}
