/// 笔记插件 - 图标组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'utils.dart' show notesColor;

/// 注册图标小组件（1x1 简单图标组件 - 快速访问）
void registerIconWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'notes_icon',
      pluginId: 'notes',
      name: 'notes_widgetName'.tr,
      description: 'notes_widgetDescription'.tr,
      icon: Icons.note_alt_outlined,
      color: notesColor,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: 'home_categoryRecord'.tr,
      builder:
          (context, config) => GenericIconWidget(
            icon: Icons.note_alt_outlined,
            color: notesColor,
            name: 'notes_widgetName'.tr,
          ),
    ),
  );
}
