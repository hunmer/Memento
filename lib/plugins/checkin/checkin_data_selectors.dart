part of 'checkin_plugin.dart';

// ==================== 数据选择器注册 ====================

// 注册数据选择器
void _registerDataSelectors() {
  // 单选数据选择器
  pluginDataSelectorService.registerSelector(SelectorDefinition(
    id: 'checkin.item',
    pluginId: CheckinPlugin.instance.id,
    name: '选择签到项',
    icon: CheckinPlugin.instance.icon,
    color: CheckinPlugin.instance.color,
    searchable: true,
    selectionMode: SelectionMode.single,
    steps: [
      SelectorStep(
        id: 'item',
        title: '选择签到项',
        viewType: SelectorViewType.grid,
        isFinalStep: true,
        dataLoader: (_) async {
          return CheckinPlugin.instance._checkinItems.map((item) => SelectableItem(
            id: item.id,
            title: item.name,
            subtitle: item.group,
            icon: item.icon,
            color: item.color,
            rawData: item,
          )).toList();
        },
        searchFilter: (items, query) {
          if (query.isEmpty) return items;
          final lowerQuery = query.toLowerCase();
          return items.where((item) =>
            item.title.toLowerCase().contains(lowerQuery) ||
            (item.subtitle?.toLowerCase().contains(lowerQuery) ?? false)
          ).toList();
        },
      ),
    ],
  ));

  // 多选数据选择器 - 选择多个签到项目
  pluginDataSelectorService.registerSelector(SelectorDefinition(
    id: 'checkin.items',
    pluginId: CheckinPlugin.instance.id,
    name: '选择签到项目（多个）',
    icon: CheckinPlugin.instance.icon,
    color: CheckinPlugin.instance.color,
    searchable: true,
    selectionMode: SelectionMode.multiple,
    steps: [
      SelectorStep(
        id: 'items',
        title: '选择签到项目',
        viewType: SelectorViewType.grid,
        isFinalStep: true,
        dataLoader: (_) async {
          return CheckinPlugin.instance._checkinItems.map((item) => SelectableItem(
            id: item.id,
            title: item.name,
            subtitle: item.group,
            icon: item.icon,
            color: item.color,
            rawData: item,
          )).toList();
        },
        searchFilter: (items, query) {
          if (query.isEmpty) return items;
          final lowerQuery = query.toLowerCase();
          return items.where((item) =>
            item.title.toLowerCase().contains(lowerQuery) ||
            (item.subtitle?.toLowerCase().contains(lowerQuery) ?? false)
          ).toList();
        },
      ),
    ],
  ));
}
