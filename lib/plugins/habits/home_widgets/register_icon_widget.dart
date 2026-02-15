/// 习惯追踪插件 - 图标组件注册 (1x1)
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';

/// 注册习惯图标组件
void registerIconWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'habits_icon',
      pluginId: 'habits',
      name: 'habits_widgetName'.tr,
      description: 'habits_widgetDescription'.tr,
      icon: Icons.auto_awesome,
      color: Colors.amber,
      defaultSize: const SmallSize(),
      supportedSizes: [const SmallSize()],
      category: 'home_categoryRecord'.tr,
      builder: (context, config) => GenericIconWidget(
        icon: Icons.auto_awesome,
        color: Colors.amber,
        name: 'habits_widgetName'.tr,
      ),
    ),
  );
}
