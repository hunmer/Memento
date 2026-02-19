/// 纪念日插件 - 图标组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';

/// 注册 1x1 图标组件 - 快速访问
void registerIconWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'day_icon',
      pluginId: 'day',
      name: 'day_widgetName'.tr,
      description: 'day_widgetDescription'.tr,
      icon: Icons.event_outlined,
      color: Colors.black87,
      defaultSize: const SmallSize(),
      supportedSizes: [const SmallSize()],
      category: 'home_categoryRecord'.tr,
      builder: (context, config) => GenericIconWidget(
        icon: Icons.event_outlined,
        color: Colors.black87,
        name: 'day_widgetName'.tr,
      ),
    ),
  );
}
