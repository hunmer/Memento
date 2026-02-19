/// 聊天插件 - 图标组件注册
///
/// 注册 1x1 简单图标组件
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';

/// 注册聊天图标组件
///
/// 这是一个 1x1 的简单图标组件，提供快速访问功能
void registerIconWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'chat_icon',
      pluginId: 'chat',
      name: 'chat_widgetName'.tr,
      description: 'chat_widgetDescription'.tr,
      icon: Icons.chat_bubble,
      color: Colors.indigoAccent,
      defaultSize: const SmallSize(),
      supportedSizes: [const SmallSize()],
      category: 'home_categoryCommunication'.tr,
      builder:
          (context, config) => GenericIconWidget(
            icon: Icons.chat_bubble,
            color: Colors.indigoAccent,
            name: 'chat_widgetName'.tr,
          ),
    ),
  );
}
