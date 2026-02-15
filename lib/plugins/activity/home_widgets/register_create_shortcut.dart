/// 活动插件 - 创建快捷入口注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'widgets/activity_create_shortcut.dart';

/// 注册创建快捷入口小组件（1x1）
void registerCreateShortcutWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'activity_create_shortcut',
      pluginId: 'activity',
      name: 'activity_createActivityShortcut'.tr,
      description: 'activity_createActivityShortcutDesc'.tr,
      icon: Icons.add_circle,
      color: Colors.pink,
      defaultSize: const SmallSize(),
      supportedSizes: [const SmallSize()],
      category: 'home_categoryRecord'.tr,
      builder: (context, config) => const ActivityCreateShortcutWidget(),
    ),
  );
}
