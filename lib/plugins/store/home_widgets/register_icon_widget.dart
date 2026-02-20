/// 积分商店插件 - 图标组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';

/// 注册 1x1 简单图标组件
void registerIconWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'store_icon',
      pluginId: 'store',
      name: 'store_widgetName'.tr,
      description: 'store_widgetDescription'.tr,
      icon: Icons.store,
      color: Colors.pinkAccent,
      defaultSize: const SmallSize(),
      supportedSizes: [const SmallSize()],
      category: 'home_categoryTools'.tr,
      builder:
          (context, config) => GenericIconWidget(
            icon: Icons.store,
            color: Colors.pinkAccent,
            name: 'store_widgetName'.tr,
          ),
    ),
  );
}
