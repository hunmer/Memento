/// 待办插件 - 图标组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';

/// 注册 1x1 图标组件
void registerIconWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'todo_icon',
      pluginId: 'todo',
      name: 'todo_widgetName'.tr,
      description: 'todo_widgetDescription'.tr,
      icon: Icons.check_box,
      color: Colors.blue,
      defaultSize: const SmallSize(),
      supportedSizes: [const SmallSize()],
      category: 'home_categoryTools'.tr,
      builder:
          (context, config) => GenericIconWidget(
            icon: Icons.check_box,
            color: Colors.blue,
            name: 'todo_name'.tr,
          ),
    ),
  );
}
