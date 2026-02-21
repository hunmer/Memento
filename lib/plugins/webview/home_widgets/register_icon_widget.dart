/// WebView插件 - 图标组件注册
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
      id: 'webview_icon',
      pluginId: 'webview',
      name: 'webview_widgetName'.tr,
      description: 'webview_widgetDescription'.tr,
      icon: Icons.language,
      color: const Color(0xFF4285F4),
      defaultSize: const SmallSize(),
      supportedSizes: [const SmallSize()],
      category: 'home_categoryTools'.tr,
      builder:
          (context, config) => GenericIconWidget(
            icon: Icons.language,
            color: const Color(0xFF4285F4),
            name: 'webview_name'.tr,
          ),
    ),
  );
}
