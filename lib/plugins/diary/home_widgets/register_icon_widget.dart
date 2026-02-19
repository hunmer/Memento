/// 日记插件 - 图标组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';

/// 注册日记图标小组件（1x1 简单图标组件）
void registerIconWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'diary_icon',
      pluginId: 'diary',
      name: 'diary_widgetName'.tr,
      description: 'diary_widgetDescription'.tr,
      icon: Icons.book,
      color: Colors.indigo,
      defaultSize: const SmallSize(),
      supportedSizes: [const SmallSize()],
      category: 'home_categoryRecord'.tr,
      builder:
          (context, config) => GenericIconWidget(
            icon: Icons.book,
            color: Colors.indigo,
            name: 'diary_widgetName'.tr,
          ),
    ),
  );
}
