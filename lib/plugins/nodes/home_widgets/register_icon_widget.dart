/// 节点笔记本插件 - 图标组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';

/// 注册图标组件（1x1 简单图标组件）
void registerIconWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'nodes_icon',
      pluginId: 'nodes',
      name: 'nodes_widgetName'.tr,
      description: 'nodes_widgetDescription'.tr,
      icon: Icons.account_tree,
      color: Colors.amber,
      defaultSize: const SmallSize(),
      supportedSizes: [const SmallSize()],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => GenericIconWidget(
        icon: Icons.account_tree,
        color: Colors.amber,
        name: 'nodes_name'.tr,
      ),
    ),
  );
}
