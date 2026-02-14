/// 日历插件 - 图标组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';

/// 日历插件颜色
const Color _calendarColor = Color.fromARGB(255, 211, 91, 91);

/// 注册图标组件
void registerIconWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'calendar_icon',
      pluginId: 'calendar',
      name: 'calendar_widgetName'.tr,
      description: 'calendar_widgetDescription'.tr,
      icon: Icons.calendar_month,
      color: _calendarColor,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => GenericIconWidget(
        icon: Icons.calendar_month,
        color: _calendarColor,
        name: 'calendar_widgetName'.tr,
      ),
    ),
  );
}
