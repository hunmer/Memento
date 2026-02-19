/// 目标追踪插件 - 图标组件注册（1x1 简单图标组件）
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';

/// 注册目标追踪插件图标组件
void registerIconWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'tracker_icon',
      pluginId: 'tracker',
      name: 'tracker_widgetName'.tr,
      description: 'tracker_widgetDescription'.tr,
      icon: Icons.track_changes,
      color: Colors.red,
      defaultSize: const SmallSize(),
      supportedSizes: [const SmallSize()],
      category: 'home_categoryRecord'.tr,
      builder: (context, config) => GenericIconWidget(
        icon: Icons.track_changes,
        color: Colors.red,
        name: 'tracker_name'.tr,
      ),
    ),
  );
}
