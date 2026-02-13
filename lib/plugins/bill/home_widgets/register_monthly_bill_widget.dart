library;

/// 账单插件 - 月份账单组件注册

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'bill_colors.dart';
import 'providers.dart';

/// 注册月份账单组件
void registerMonthlyBillWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'monthly_bill_widget',
      pluginId: 'bill',
      name: 'bill_monthlyBillsWidgetName'.tr,
      description: 'bill_monthlyWidgetDescription'.tr,
      icon: Icons.calendar_month,
      color: billColor,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
      category: 'home_categoryRecord'.tr,

      // 选择器配置
      selectorId: 'bill.monthly.config',

      // 公共组件提供者
      commonWidgetsProvider: provideBillCommonWidgets,

      builder: (context, config) {
        return StatefulBuilder(
          builder: (context, setState) {
            return EventListenerContainer(
              events: const [
                'bill_added',
                'bill_deleted',
                'account_added',
                'account_deleted',
              ],
              onEvent: () => setState(() {}),
              child: GenericSelectorWidget(
                widgetDefinition: registry.getWidget('monthly_bill_widget')!,
                config: config,
              ),
            );
          },
        );
      },
    ),
  );
}
