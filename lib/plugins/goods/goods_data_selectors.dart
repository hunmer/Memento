part of 'goods_plugin.dart';

// 注册数据选择器
void _registerDataSelectors() {
  final pluginDataSelectorService = PluginDataSelectorService.instance;

  // 注册仓库选择器（单级）
  pluginDataSelectorService.registerSelector(SelectorDefinition(
    id: 'goods.warehouse',
    pluginId: GoodsPlugin.instance.id,
    name: '选择仓库',
    icon: GoodsPlugin.instance.icon,
    color: GoodsPlugin.instance.color,
    steps: [
      SelectorStep(
        id: 'warehouse',
        title: '选择仓库',
        viewType: SelectorViewType.list,
        isFinalStep: true,
        dataLoader: (_) async {
          return GoodsPlugin.instance.warehouses.map((warehouse) => SelectableItem(
            id: warehouse.id,
            title: warehouse.title,
            subtitle: '${warehouse.items.length} 件物品',
            icon: warehouse.icon,
            color: warehouse.iconColor,
            rawData: warehouse.toJson(),
          )).toList();
        },
      ),
    ],
  ));

  // 注册物品选择器（两级：仓库 → 物品）
  pluginDataSelectorService.registerSelector(SelectorDefinition(
    id: 'goods.item',
    pluginId: GoodsPlugin.instance.id,
    name: '选择物品',
    icon: GoodsPlugin.instance.icon,
    color: GoodsPlugin.instance.color,
    steps: [
      // 第一级：选择仓库
      SelectorStep(
        id: 'warehouse',
        title: '选择仓库',
        viewType: SelectorViewType.list,
        isFinalStep: false,
        dataLoader: (_) async {
          return GoodsPlugin.instance.warehouses.map((warehouse) => SelectableItem(
            id: warehouse.id,
            title: warehouse.title,
            subtitle: '${warehouse.items.length} 件物品',
            icon: warehouse.icon,
            color: warehouse.iconColor,
            rawData: warehouse.toJson(),
          )).toList();
        },
      ),
      // 第二级：选择物品
      SelectorStep(
        id: 'item',
        title: '选择物品',
        viewType: SelectorViewType.list,
        isFinalStep: true,
        dataLoader: (previousSelections) async {
          final warehouse = Warehouse.fromJson(previousSelections['warehouse'] as Map<String, dynamic>);
          return _getAllItemsRecursively(warehouse.items);
        },
      ),
    ],
  ));
}

// 递归获取所有物品（包含子物品），转换为 SelectableItem 列表
List<SelectableItem> _getAllItemsRecursively(List<GoodsItem> items, {String prefix = ''}) {
  List<SelectableItem> result = [];
  for (var item in items) {
    result.add(SelectableItem(
      id: item.id,
      title: prefix.isNotEmpty ? '$prefix${item.title}' : item.title,
      subtitle: item.purchasePrice != null ? '¥${item.purchasePrice!.toStringAsFixed(2)}' : null,
      icon: item.icon,
      color: item.iconColor,
      rawData: item.toJson(),
    ));
    // 递归处理子物品
    if (item.subItems.isNotEmpty) {
      result.addAll(_getAllItemsRecursively(
        item.subItems,
        prefix: '$prefix${item.title} > ',
      ));
    }
  }
  return result;
}
