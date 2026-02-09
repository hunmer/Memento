/// 物品管理插件 - 仓库选择器注册
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
import 'widgets/goods_warehouse_widget.dart';
import 'utils.dart';

const Color _goodsColor = Color.fromARGB(255, 207, 77, 116);

/// 注册仓库选择器小组件
void registerWarehouseSelectorWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'goods_warehouse_selector',
      pluginId: 'goods',
      name: 'goods_warehouseSelector'.tr,
      description: 'goods_warehouseSelectorDesc'.tr,
      icon: Icons.warehouse,
      color: _goodsColor,
      defaultSize: HomeWidgetSize.medium,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
      category: 'home_categoryRecord'.tr,
      selectorId: 'goods.warehouse',
      dataRenderer: _renderWarehouseData,
      navigationHandler: _navigateToWarehouse,
      dataSelector: extractWarehouseData,
      builder: (context, config) => GenericSelectorWidget(
        widgetDefinition: registry.getWidget('goods_warehouse_selector')!,
        config: config,
      ),
    ),
  );
}

/// 渲染选中的仓库数据
Widget _renderWarehouseData(
  BuildContext context,
  SelectorResult result,
  Map<String, dynamic> config,
) {
  // 从 result.data 获取仓库 ID
  final data = result.data as Map<String, dynamic>?;
  if (data == null) {
    return HomeWidget.buildErrorWidget(context, '请选择仓库');
  }

  final warehouseId = data['id'] as String?;

  if (warehouseId == null) {
    return HomeWidget.buildErrorWidget(context, '仓库ID为空');
  }

  // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
  return StatefulBuilder(
    builder: (context, setState) {
      return EventListenerContainer(
        events: const ['goods_item_added', 'goods_item_deleted'],
        onEvent: () => setState(() {}),
        child: GoodsWarehouseWidget(warehouseId: warehouseId),
      );
    },
  );
}

/// 导航到仓库详情页面
void _navigateToWarehouse(
  BuildContext context,
  SelectorResult result,
) {
  final warehouseId = getWarehouseIdFromResult(result);
  final warehouseName = getWarehouseNameFromResult(result);

  if (warehouseId == null || warehouseId.isEmpty) {
    debugPrint('仓库ID为空');
    return;
  }

  // 尝试获取最新数据
  final plugin = GoodsPlugin.instance;
  final warehouse = plugin.getWarehouse(warehouseId);
  final name = warehouse?.title ?? warehouseName ?? '未知仓库';

  NavigationHelper.pushNamed(
    context,
    '/goods/warehouse_detail',
    arguments: {'warehouseId': warehouseId, 'warehouseName': name},
  );
}
