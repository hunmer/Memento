/// 脚本中心插件 - 图标组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';

/// 注册脚本中心图标组件（1x1 简单图标组件 - 快速访问）
void registerIconWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'scripts_center_icon',
      pluginId: 'scripts_center',
      name: 'scripts_center_widgetName'.tr,
      description: 'scripts_center_widgetDescription'.tr,
      icon: Icons.code,
      color: Colors.deepPurple,
      defaultSize: const SmallSize(),
      supportedSizes: [const SmallSize()],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => GenericIconWidget(
        icon: Icons.code,
        color: Colors.deepPurple,
        name: 'scripts_center_name'.tr,
      ),
    ),
  );
}
