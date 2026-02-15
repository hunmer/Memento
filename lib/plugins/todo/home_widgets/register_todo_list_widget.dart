/// 待办插件 - 待办列表小组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'widgets/todo_list_widget.dart';

/// 注册 2x2 待办列表小组件
void registerTodoListWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'todo_list',
      pluginId: 'todo',
      name: 'todo_listWidgetName'.tr,
      description: 'todo_listWidgetDesc'.tr,
      icon: Icons.checklist,
      color: Colors.blue,
      defaultSize: const LargeSize(),
      supportedSizes: [const LargeSize()],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => const TodoListWidget(),
    ),
  );
}
