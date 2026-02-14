import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';

/// 注册 1x1 简单图标组件
void registerIconWidget(HomeWidgetRegistry registry) {
  registry.register(HomeWidget(
    id: 'openai_icon',
    pluginId: 'openai',
    name: 'openai_widgetName'.tr,
    description: 'openai_widgetDescription'.tr,
    icon: Icons.smart_toy,
    color: Colors.deepOrange,
    defaultSize: HomeWidgetSize.small,
    supportedSizes: [HomeWidgetSize.small],
    category: 'home_categoryTools'.tr,
    builder: (context, config) => GenericIconWidget(
      icon: Icons.smart_toy,
      color: Colors.deepOrange,
      name: 'openai_widgetName'.tr,
    ),
  ));
}
