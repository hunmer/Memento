/// 节点笔记本插件 - 笔记本列表组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'providers.dart';

/// 注册笔记本列表小组件（选择笔记本展示节点，支持多种尺寸）
void registerNotebookListWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'nodes_notebook_list',
      pluginId: 'nodes',
      name: 'nodes_notebookListName'.tr,
      description: 'nodes_notebookListDescription'.tr,
      icon: Icons.view_list,
      color: Colors.amber,
      defaultSize: const Wide2Size(),
      supportedSizes: [
        const LargeSize(), // 2x2
        const Large3Size(), // 2x3
        const Wide2Size(), // 4x2
        const Wide3Size(), // 4x3
      ],
      category: 'home_categoryTools'.tr,
      selectorId: 'nodes.notebook',
      dataRenderer: renderNotebookNodes,
      navigationHandler: navigateToNotebook,
      dataSelector: (dataArray) {
        final notebookData = dataArray[0] as Map<String, dynamic>;
        return {
          'id': notebookData['id'] as String,
          'title': notebookData['title'] as String?,
        };
      },
      builder: (context, config) {
        return GenericSelectorWidget(
          widgetDefinition: registry.getWidget('nodes_notebook_list')!,
          config: config,
        );
      },
    ),
  );
}
