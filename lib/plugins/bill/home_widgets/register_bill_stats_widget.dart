library;

/// 账单插件 - 支出统计组件注册

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'bill_colors.dart';
import 'providers.dart' show provideBillStatsWidgets;

/// 注册支出统计组件
void registerBillStatsWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'bill_stats_widget',
      pluginId: 'bill',
      name: 'bill_statsWidgetName'.tr,
      description: 'bill_statsWidgetDescription'.tr,
      icon: Icons.pie_chart,
      color: billColor,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [
        HomeWidgetSize.medium,
        HomeWidgetSize.large,
        HomeWidgetSize.custom,
      ],
      category: 'home_categoryRecord'.tr,

      // 选择器配置
      selectorId: 'bill.stats.config',

      // 公共组件提供者
      commonWidgetsProvider: provideBillStatsWidgets,

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
                widgetDefinition: registry.getWidget('bill_stats_widget')!,
                config: config,
              ),
            );
          },
        );
      },
    ),
  );
}
