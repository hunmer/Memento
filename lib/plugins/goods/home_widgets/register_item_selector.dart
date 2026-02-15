/// 物品管理插件 - 物品选择器注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';
import 'widgets/goods_item_widget.dart';
import 'utils.dart';

const Color _goodsColor = Color.fromARGB(255, 207, 77, 116);

/// 注册物品选择器小组件
void registerItemSelectorWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'goods_item_selector',
      pluginId: 'goods',
      name: 'goods_itemSelector'.tr,
      description: 'goods_itemSelectorDesc'.tr,
      icon: Icons.inventory_2,
      color: _goodsColor,
      defaultSize: const MediumSize(),
      supportedSizes: [const MediumSize(), const LargeSize()],
      category: 'home_categoryRecord'.tr,
      selectorId: 'goods.item',
      dataRenderer: _renderItemData,
      navigationHandler: _navigateToItem,
      dataSelector: extractItemData,
      builder: (context, config) => GenericSelectorWidget(
        widgetDefinition: registry.getWidget('goods_item_selector')!,
        config: config,
      ),
    ),
  );
}

/// 渲染选中的物品数据
Widget _renderItemData(
  BuildContext context,
  SelectorResult result,
  Map<String, dynamic> config,
) {
  // 从 result.data 获取物品 ID
  final data = result.data as Map<String, dynamic>?;
  if (data == null) {
    return HomeWidget.buildErrorWidget(context, '请选择物品');
  }

  final itemId = data['id'] as String?;

  if (itemId == null) {
    return HomeWidget.buildErrorWidget(context, '物品ID为空');
  }

  // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
  return StatefulBuilder(
    builder: (context, setState) {
      return EventListenerContainer(
        events: const ['goods_item_added', 'goods_item_deleted'],
        onEvent: () => setState(() {}),
        child: GoodsItemWidget(itemId: itemId, config: config),
      );
    },
  );
}

/// 导航到物品详情页面
void _navigateToItem(
  BuildContext context,
  SelectorResult result,
) {
  final itemId = getItemIdFromResult(result);

  if (itemId == null || itemId.isEmpty) {
    debugPrint('物品ID为空');
    return;
  }

  // 尝试从 GoodsPlugin 获取最新数据以获取仓库ID
  final plugin = GoodsPlugin.instance;
  final findResult = plugin.findGoodsItemById(itemId);

  if (findResult == null) {
    debugPrint('未找到物品: $itemId');
    return;
  }

  NavigationHelper.pushNamed(
    context,
    '/goods/item_detail',
    arguments: {
      'itemId': itemId,
      'warehouseId': findResult.warehouseId,
      'itemTitle': findResult.item.title,
    },
  );
}
