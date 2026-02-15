/// 活动插件 - 图标组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';

/// 注册图标小组件（1x1）
void registerIconWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'activity_icon',
      pluginId: 'activity',
      name: 'activity_widgetName'.tr,
      description: 'activity_widgetDescription'.tr,
      icon: Icons.timeline,
      color: Colors.pink,
      defaultSize: const SmallSize(),
      supportedSizes: [const SmallSize()],
      category: 'home_categoryRecord'.tr,
      builder:
          (context, config) => GenericIconWidget(
            icon: Icons.timeline,
            color: Colors.pink,
            name: 'activity_widgetName'.tr,
          ),
    ),
  );
}
