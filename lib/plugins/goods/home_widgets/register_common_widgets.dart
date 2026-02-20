/// 物品插件 - 公共组件注册
///
/// 支持通过 dataSelector 选择物品后，使用公共小组件渲染
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';
import 'provide_common_widgets.dart';
import 'utils.dart';

const Color _goodsColor = Color.fromARGB(255, 207, 77, 116);

/// 注册公共小组件（物品小组件 - 支持公共小组件样式）
void registerCommonWidgets(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'goods_common_widgets',
      pluginId: 'goods',
      name: 'goods_commonWidgetsName'.tr,
      description: 'goods_commonWidgetsDesc'.tr,
      icon: Icons.dashboard,
      color: _goodsColor,
      defaultSize: const MediumSize(),
      supportedSizes: [const MediumSize(), const LargeSize()],
      category: 'home_categoryRecord'.tr,
      selectorId: 'goods.item',
      dataSelector: extractItemData,
      commonWidgetsProvider: provideCommonWidgets,
      navigationHandler: _navigateToItem,
      builder: (context, config) {
        return GenericSelectorWidget(
          widgetDefinition: registry.getWidget('goods_common_widgets')!,
          config: config,
        );
      },
    ),
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
