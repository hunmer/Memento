/// 日历相册插件 - 图标小组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'utils.dart';

/// 注册 1x1 简单图标组件 - 快速访问
void registerIconWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'calendar_album_icon',
      pluginId: 'calendar_album',
      name: 'calendar_album_widget_name'.tr,
      description: 'calendar_album_widget_description'.tr,
      icon: Icons.notes_rounded,
      color: pluginColor,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: 'home_categoryRecord'.tr,
      builder:
          (context, config) => GenericIconWidget(
            icon: Icons.notes_rounded,
            color: pluginColor,
            name: 'calendar_album_widget_name'.tr,
          ),
    ),
  );
}
