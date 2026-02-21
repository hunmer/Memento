// NFC 插件 - 图标组件注册

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';

/// 注册 1x1 简单图标组件 - 快速访问
void registerIconWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'nfc_icon',
      pluginId: 'nfc',
      name: 'nfc_widgetName'.tr,
      description: 'nfc_widgetDescription'.tr,
      icon: Icons.nfc,
      color: Colors.orange,
      defaultSize: const SmallSize(),
      supportedSizes: [const SmallSize()],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => GenericIconWidget(
        icon: Icons.nfc,
        color: Colors.orange,
        name: 'nfc_pluginName'.tr,
      ),
    ),
  );
}
