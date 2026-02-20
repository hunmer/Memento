/// 物品管理插件公共小组件提供者
///
/// 支持通过 dataSelector 选择物品后，使用公共小组件渲染
library;

import 'package:Memento/plugins/goods/goods_plugin.dart';
import 'package:flutter/foundation.dart';

/// 公共小组件提供者函数
///
/// 根据 data 参数（包含选择的数据）返回对应的 props
/// 支持两种数据类型：
/// - 仓库数据：{'id': 仓库ID, 'title': xxx, 'warehouseId': 仓库ID, 'isWarehouse': true}
/// - 物品数据：{'id': 物品ID, 'title': xxx, 'warehouseId': 仓库ID}
Future<Map<String, Map<String, dynamic>>> provideCommonWidgets(
  Map<String, dynamic> data,
) async {
  // 从 data 中获取选择的数据（dataSelector 提取后的 Map）
  final id = data['id'] as String?;
  final warehouseId = data['warehouseId'] as String?;
  final title = data['title'] as String?;
  final isWarehouse = data['isWarehouse'] as bool? ?? false;

  debugPrint('[provideCommonWidgets] data: $data');
  debugPrint(
    '[provideCommonWidgets] id: $id, warehouseId: $warehouseId, isWarehouse: $isWarehouse',
  );

  if (id == null) {
    return {};
  }

  if (isWarehouse) {
    // 仓库数据：id 就是 warehouseId，显示仓库中所有物品
    debugPrint('[provideCommonWidgets] 仓库模式，显示仓库所有物品');
    return {
      'goodsItemSelector': {
        'itemIds': [], // 空数组表示显示仓库中所有物品
        'warehouseIds': [id],
        'title': title ?? '仓库',
        'showListMode': false,
      },
    };
  }

  // 物品数据：需要查找物品所属的仓库
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
