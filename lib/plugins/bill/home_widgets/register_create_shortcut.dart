/// 账单插件 - 创建账单快捷入口组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'widgets.dart' show renderBillStatsData, navigateToCreateBill;
import 'utils.dart' show extractBillWidgetData;

/// 注册创建账单快捷入口组件（选择账户和时间范围后显示收支统计）
void registerCreateShortcutWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'bill_create_shortcut',
      pluginId: 'bill',
      name: 'bill_createShortcutName'.tr,
      description: 'bill_createShortcutDescription'.tr,
      icon: Icons.add_card,
      color: Colors.green,
      defaultSize: const MediumSize(),
      supportedSizes: [const SmallSize(), const MediumSize()],
      category: 'home_categoryRecord'.tr,
      selectorId: 'bill.account_with_period',
      dataRenderer: renderBillStatsData,
      navigationHandler: navigateToCreateBill,
      dataSelector: extractBillWidgetData,
      builder:
          (context, config) => GenericSelectorWidget(
            widgetDefinition: registry.getWidget('bill_create_shortcut')!,
            config: config,
          ),
    ),
  );
}
