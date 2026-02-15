/// Agent Chat - 图标组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';

/// 注册 1x1 简单图标组件 - 快速访问
void registerIconWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'agent_chat_icon',
      pluginId: 'agent_chat',
      name: 'agent_chat_name'.tr,
      description: 'agent_chat_description'.tr,
      icon: Icons.chat_bubble_outline,
      color: const Color(0xFF2196F3),
      defaultSize: const SmallSize(),
      supportedSizes: [const SmallSize()],
      category: 'home_categoryTools'.tr,
      builder:
          (context, config) => GenericIconWidget(
            icon: Icons.chat_bubble_outline,
            color: const Color(0xFF2196F3),
            name: 'agent_chat_name'.tr,
          ),
    ),
  );
}
