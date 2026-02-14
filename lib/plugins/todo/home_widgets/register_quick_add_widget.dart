/// 待办插件 - 快速添加小组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'widgets/quick_add_widget.dart';

/// 注册 1x1 快速添加小组件
void registerQuickAddWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'todo_quick_add',
      pluginId: 'todo',
      name: 'todo_quickAdd'.tr,
      description: 'todo_quickAddDesc'.tr,
      icon: Icons.add_task,
      color: Colors.blue,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => const QuickAddWidget(),
    ),
  );
}
