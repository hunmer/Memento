/// 物品管理插件主页小组件工具函数
library;

import 'package:flutter/material.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';

/// 物品管理插件主题色
const Color goodsColor = Color.fromARGB(255, 207, 77, 116);

/// 从选择器数据数组中提取仓库数据
Map<String, dynamic> extractWarehouseData(List<dynamic> dataArray) {
  Map<String, dynamic> itemData = {};
  final rawData = dataArray[0];

  if (rawData is Map<String, dynamic>) {
    itemData = rawData;
  } else if (rawData is dynamic && rawData.toJson != null) {
    final jsonResult = rawData.toJson();
    if (jsonResult is Map<String, dynamic>) {
      itemData = jsonResult;
    }
  }

  final result = <String, dynamic>{};
  result['id'] = itemData['id'] as String?;
  result['title'] = itemData['title'] as String?;
  result['icon'] = itemData['icon'] as int?;
  result['iconColor'] = itemData['iconColor'] as int?;
  return result;
}

/// 从选择器数据数组中提取物品数据
///
/// 支持两种数据类型：
/// - 物品数据：包含 warehouseId 字段
/// - 仓库数据：包含 items 字段，仓库的 id 就是 warehouseId
Map<String, dynamic> extractItemData(List<dynamic> dataArray) {
  Map<String, dynamic> itemData = {};
  final rawData = dataArray[0];

  debugPrint('[extractItemData] rawData 类型: ${rawData.runtimeType}');
  debugPrint('[extractItemData] rawData 内容: $rawData');

  if (rawData is Map<String, dynamic>) {
    itemData = rawData;
  } else if (rawData is dynamic && rawData.toJson != null) {
    final jsonResult = rawData.toJson();
    if (jsonResult is Map<String, dynamic>) {
      itemData = jsonResult;
    }
  }

  debugPrint('[extractItemData] itemData 类型: ${itemData.runtimeType}');
  debugPrint('[extractItemData] itemData 内容: $itemData');

  final result = <String, dynamic>{};
  result['id'] = itemData['id'] as String?;
  result['title'] = itemData['title'] as String?;
  result['icon'] = itemData['icon'] as int?;
  result['iconColor'] = itemData['iconColor'] as int?;
  result['purchasePrice'] = itemData['purchasePrice'] as double?;

  // 检测是否为仓库数据（仓库有 items 字段）
  final hasItemsField = itemData.containsKey('items') && itemData['items'] is List;
  if (hasItemsField) {
    // 仓库数据：仓库的 id 就是 warehouseId，标记为仓库类型
    result['warehouseId'] = itemData['id'] as String?;
    result['isWarehouse'] = true;
    debugPrint('[extractItemData] 检测到仓库数据，使用 id 作为 warehouseId');
  } else {
    // 物品数据：使用 warehouseId 字段
    result['warehouseId'] = itemData['warehouseId'] as String?;
    result['isWarehouse'] = false;
  }

  debugPrint('[extractItemData] 提取结果: $result');

  return result;
}

/// 从选择器结果中获取仓库ID
String? getWarehouseIdFromResult(SelectorResult result) {
  final data = result.data as Map<String, dynamic>?;
  return data?['id'] as String?;
}

/// 从选择器结果中获取仓库名称
String? getWarehouseNameFromResult(SelectorResult result) {
  final data = result.data as Map<String, dynamic>?;
  return data?['title'] as String?;
}

/// 从选择器结果中获取物品ID
String? getItemIdFromResult(SelectorResult result) {
  final data = result.data as Map<String, dynamic>?;
  return data?['id'] as String?;
}
