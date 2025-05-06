import 'goods_item.dart';

/// 物品查找结果
class FindItemResult {
  /// 找到的物品
  final GoodsItem item;
  
  /// 物品所在仓库的ID
  final String warehouseId;

  FindItemResult({
    required this.item,
    required this.warehouseId,
  });
}