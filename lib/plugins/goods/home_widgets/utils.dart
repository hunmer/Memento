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
/// goods.item 选择器是两级选择（仓库 → 物品）， dataArray 包含：
/// - dataArray[0]: 仓库数据
/// - dataArray[1]: 物品数据（最终选择）
///
/// 只返回物品数据，必须包含 warehouseId 字段
Map<String, dynamic> extractItemData(List<dynamic> dataArray) {
  if (dataArray.isEmpty) {
    debugPrint('[extractItemData] 数据数组为空');
    return {};
  }

  // goods.item 是两级选择器，最终选择的数据在数组最后
  // dataArray[0] 是仓库数据，dataArray[1] 是物品数据
  final rawData = dataArray.last;

  debugPrint('[extractItemData] rawData 类型: ${rawData.runtimeType}');
  debugPrint('[extractItemData] rawData 内容: $rawData');

  Map<String, dynamic> itemData = {};
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

  // 从物品数据中获取 warehouseId
  // _getAllItemsRecursively 函数已经在物品数据中包含了 warehouseId
  result['warehouseId'] = itemData['warehouseId'] as String?;
  result['isWarehouse'] = false;

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
