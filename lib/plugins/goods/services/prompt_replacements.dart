import 'package:flutter/material.dart';
import '../goods_plugin.dart';
import '../models/goods_item.dart';
import '../../../core/analysis/analysis_mode.dart';
import '../../../core/analysis/field_utils.dart';

/// Goods插件的Prompt替换服务
///
/// 遵循 Memento Prompt 数据格式规范 v2.0
/// 详见: docs/PROMPT_DATA_SPEC.md
class GoodsPromptReplacements {
  final GoodsPlugin _plugin;

  GoodsPromptReplacements(this._plugin);

  /// 获取物品数据并格式化为文本
  ///
  /// 参数:
  /// - warehouseId: 仓库ID过滤 (可选)
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  /// - fields: 自定义返回字段列表 (可选, 优先级高于 mode)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total, warehouses, cats }, topCats: [...] }
  /// - compact: 简化记录 { sum: {...}, recs: [...] } (无description, subItems等)
  /// - full: 完整数据 (包含所有字段)
  /// - fields: 自定义字段 { recs: [...] } (仅包含指定字段)
  Future<String> getItems(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final customFields = params['fields'] as List<dynamic>?;
      final warehouseId = params['warehouseId'] as String?;

      // 2. 获取物品列表
      List<GoodsItem> items = [];
      if (warehouseId != null && warehouseId.isNotEmpty) {
        // 获取指定仓库的物品
        final warehouse = _plugin.getWarehouse(warehouseId);
        if (warehouse != null) {
          items = warehouse.items;
        }
      } else {
        // 获取所有仓库的所有物品
        for (var warehouse in _plugin.warehouses) {
          items.addAll(warehouse.items);
        }
      }

      // 3. 根据 customFields 或 mode 转换数据
      Map<String, dynamic> result;

      if (customFields != null && customFields.isNotEmpty) {
        // 优先使用 fields 参数（白名单模式）
        final fieldList = customFields.map((e) => e.toString()).toList();
        final itemJsonList = items.map((i) => i.toJson()).toList();
        final filteredRecords = FieldUtils.simplifyRecords(
          itemJsonList,
          keepFields: fieldList,
        );
        result = FieldUtils.buildCompactResponse(
          {'total': filteredRecords.length},
          filteredRecords,
        );
      } else {
        // 使用 mode 参数
        result = _convertByMode(items, mode);
      }

      // 4. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取物品数据失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取物品数据时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取分类统计数据
  ///
  /// 返回格式: { total, warehouses, categories: [{name, count, value}] }
  Future<String> getCategories(Map<String, dynamic> params) async {
    try {
      // 统计所有物品
      int totalItems = 0;
      final categoryCounts = <String, int>{};
      final categoryValues = <String, double>{};

      for (var warehouse in _plugin.warehouses) {
        for (var item in warehouse.items) {
          totalItems++;

          // 使用仓库名称作为分类
          final category = warehouse.title;
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;

          if (item.purchasePrice != null) {
            categoryValues[category] =
                (categoryValues[category] ?? 0) + item.purchasePrice!;
          }
        }
      }

      // 按物品数量排序
      final categories = categoryCounts.entries.map((e) {
        return {
          'name': e.key,
          'cnt': e.value,
          'value': categoryValues[e.key] ?? 0,
        };
      }).toList()
        ..sort((a, b) => (b['cnt'] as int).compareTo(a['cnt'] as int));

      return FieldUtils.toJsonString({
        'total': totalItems,
        'warehouses': _plugin.warehouses.length,
        'cats': categories,
      });
    } catch (e) {
      debugPrint('获取分类数据失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取分类数据时出错',
        'details': e.toString(),
      });
    }
  }

  /// 根据模式转换数据
  Map<String, dynamic> _convertByMode(
    List<GoodsItem> items,
    AnalysisMode mode,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildSummary(items);
      case AnalysisMode.compact:
        return _buildCompact(items);
      case AnalysisMode.full:
        return _buildFull(items);
    }
  }

  /// 构建摘要数据 (summary模式)
  ///
  /// 返回格式:
  /// {
  ///   "sum": {
  ///     "total": 120,
  ///     "warehouses": 5,
  ///     "totalValue": 58888.50,
  ///     "topCats": [{"cat": "客厅", "cnt": 30}]
  ///   }
  /// }
  Map<String, dynamic> _buildSummary(List<GoodsItem> items) {
    if (items.isEmpty) {
      return FieldUtils.buildSummaryResponse({
        'total': 0,
        'warehouses': _plugin.warehouses.length,
        'totalValue': 0,
      });
    }

    // 计算总价值
    double totalValue = 0;
    for (var item in items) {
      if (item.purchasePrice != null) {
        totalValue += item.purchasePrice!;
      }
    }

    // 统计各仓库的物品数量
    final warehouseCounts = <String, int>{};
    for (var warehouse in _plugin.warehouses) {
      if (warehouse.items.isNotEmpty) {
        warehouseCounts[warehouse.title] = warehouse.items.length;
      }
    }

    // 按数量排序，取前5个仓库
    final topCats = warehouseCounts.entries
        .map((e) => {
              'cat': e.key,
              'cnt': e.value,
            })
        .toList()
      ..sort((a, b) => (b['cnt'] as int).compareTo(a['cnt'] as int));

    return FieldUtils.buildSummaryResponse({
      'total': items.length,
      'warehouses': _plugin.warehouses.length,
      'totalValue': double.parse(totalValue.toStringAsFixed(2)),
      if (topCats.isNotEmpty) 'topCats': topCats.take(5).toList(),
    });
  }

  /// 构建紧凑数据 (compact模式)
  ///
  /// 返回格式:
  /// {
  ///   "sum": { "total": 120, "warehouses": 5 },
  ///   "recs": [
  ///     {
  ///       "id": "uuid",
  ///       "name": "笔记本电脑",
  ///       "cat": "客厅",
  ///       "location": "书桌",
  ///       "qty": 1,
  ///       "price": 8999.0
  ///     }
  ///   ]
  /// }
  Map<String, dynamic> _buildCompact(List<GoodsItem> items) {
    if (items.isEmpty) {
      return FieldUtils.buildCompactResponse(
        {'total': 0, 'warehouses': _plugin.warehouses.length},
        [],
      );
    }

    // 简化记录（移除 notes, subItems, customFields, usageRecords 等字段）
    final compactRecords = items.map((item) {
      // 找到物品所在的仓库
      String? warehouseName;
      for (var warehouse in _plugin.warehouses) {
        if (warehouse.items.any((i) => i.id == item.id)) {
          warehouseName = warehouse.title;
          break;
        }
      }

      final record = <String, dynamic>{
        'id': item.id,
        'name': item.title,
      };

      // 只添加非空字段
      if (warehouseName != null) {
        record['cat'] = warehouseName; // 使用仓库名称作为分类
      }
      if (item.purchasePrice != null) {
        record['price'] = item.purchasePrice;
      }
      if (item.tags.isNotEmpty) {
        record['tags'] = item.tags;
      }

      return record;
    }).toList();

    return FieldUtils.buildCompactResponse(
      {
        'total': items.length,
        'warehouses': _plugin.warehouses.length,
      },
      compactRecords,
    );
  }

  /// 构建完整数据 (full模式)
  ///
  /// 返回格式: jsAPI 的原始数据
  Map<String, dynamic> _buildFull(List<GoodsItem> items) {
    final itemJsonList = items.map((i) => i.toJson()).toList();
    return FieldUtils.buildFullResponse(itemJsonList);
  }

  /// 释放资源
  void dispose() {}
}
