/// 纪念日插件 - 日期范围列表组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'providers.dart';

/// 注册纪念日列表小组件 - 显示指定日期范围内的纪念日
void registerDateRangeListWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'day_date_range_list',
      pluginId: 'day',
      name: 'day_listWidgetName'.tr,
      description: 'day_listWidgetDescription'.tr,
      icon: Icons.calendar_month,
      color: Colors.black87,
      defaultSize: const LargeSize(),
      supportedSizes: [const MediumSize(), const LargeSize()],
      category: 'home_categoryRecord'.tr,
      // 使用日期范围选择器
      selectorId: 'day.dateRange',
      dataSelector: extractDateRangeData,
      navigationHandler: navigateToDayPage,
      // 使用公共小组件提供者
      commonWidgetsProvider: provideDateRangeCommonWidgets,
      builder: (context, config) {
        return GenericSelectorWidget(
          widgetDefinition: registry.getWidget('day_date_range_list')!,
          config: config,
        );
      },
    ),
  );
}
