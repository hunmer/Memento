/// 计时器插件 - 图标组件注册
library;

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';

/// 注册 1x1 简单图标组件 - 快速访问
void registerIconWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'timer_icon',
      pluginId: 'timer',
      name: 'timer_widgetName'.tr,
      description: 'timer_widgetDescription'.tr,
      icon: Icons.timer,
      color: Colors.blueGrey,
      defaultSize: const SmallSize(),
      supportedSizes: [const SmallSize()],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => GenericIconWidget(
        icon: Icons.timer,
        color: Colors.blueGrey,
        name: 'timer_name'.tr,
      ),
    ),
  );
}
