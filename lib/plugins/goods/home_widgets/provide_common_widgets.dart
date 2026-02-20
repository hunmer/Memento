/// 物品管理插件公共小组件提供者
///
/// 支持通过 dataSelector 选择物品后，使用公共小组件渲染
library;

import 'package:Memento/plugins/goods/goods_plugin.dart';
import 'package:flutter/foundation.dart';

/// 公共小组件提供者函数
///
/// 根据 data 参数（包含选择的物品数据）返回对应的 props
/// 数据格式：{'id': 物品ID, 'title': xxx, 'warehouseId': 仓库ID}
Future<Map<String, Map<String, dynamic>>> provideCommonWidgets(
  Map<String, dynamic> data,
) async {
  // 从 data 中获取选择的数据（dataSelector 提取后的 Map）
  final id = data['id'] as String?;
  final warehouseId = data['warehouseId'] as String?;
  final title = data['title'] as String?;

  debugPrint('[provideCommonWidgets] data: $data');
  debugPrint(
    '[provideCommonWidgets] id: $id, warehouseId: $warehouseId',
  );

  if (id == null) {
    return {};
  }

  // 物品数据：确保有 warehouseId
  String? effectiveWarehouseId = warehouseId;
  if (effectiveWarehouseId == null || effectiveWarehouseId.isEmpty) {
    final plugin = GoodsPlugin.instance;
    final findResult = plugin.findGoodsItemById(id);
    effectiveWarehouseId = findResult?.warehouseId;
    debugPrint(
      '[provideCommonWidgets] findResult: $findResult, effectiveWarehouseId: $effectiveWarehouseId',
    );
  }

  if (effectiveWarehouseId == null || effectiveWarehouseId.isEmpty) {
    debugPrint('[provideCommonWidgets] warehouseId is null, returning empty');
    return {};
  }

  // 构建 goodsItemSelector 数据（显示特定物品）
  return {
    'goodsItemSelector': {
      'itemIds': [id],
      'warehouseIds': [effectiveWarehouseId],
      'title': title ?? '物品',
      'showListMode': false,
    },
  };
}
