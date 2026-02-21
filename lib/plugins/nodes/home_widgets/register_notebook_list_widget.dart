/// 节点笔记本插件 - 笔记本列表小组件注册（公共小组件）
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/base/live_selector_widget.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';

// 导入 CommandWidgetsProvider
import 'package:Memento/plugins/nodes/home_widgets/providers/command_widgets_provider.dart'
    as cmd;

/// 默认显示的公共小组件类型
const CommonWidgetId defaultWidgetType = CommonWidgetId.taskListCard;

/// 笔记本列表小组件（基于 LiveSelectorWidget）
///
/// 默认显示 taskListCard 公共小组件，支持实时更新
class _NodesListLiveWidget extends LiveSelectorWidget {
  const _NodesListLiveWidget({
    required super.config,
    required super.widgetDefinition,
  });

  @override
  List<String> get eventListeners => const [
    'nodes_notebook_added',
    'nodes_notebook_updated',
    'nodes_notebook_deleted',
    'nodes_node_added',
    'nodes_node_updated',
    'nodes_node_deleted',
  ];

  @override
  Future<Map<String, dynamic>> getLiveData(
    Map<String, dynamic> config,
  ) async {
    return cmd.NodesCommandWidgetsProvider.provideCommonWidgets({});
  }

  @override
  String get widgetTag => 'NodesListWidget';

  @override
  Widget buildCommonWidget(
    BuildContext context,
    CommonWidgetId widgetId,
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return CommonWidgetBuilder.build(
      context,
      widgetId,
      props,
      size,
      inline: true,
    );
  }
}

/// 注册笔记本列表小组件（公共小组件，无配置）
void registerNotebookListWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'nodes_notebook_list',
      pluginId: 'nodes',
      name: 'nodes_notebookListWidgetName'.tr,
      description: 'nodes_notebookListWidgetDesc'.tr,
      icon: Icons.view_list,
      color: Colors.amber,
      defaultSize: const LargeSize(),
      supportedSizes: const [LargeSize()],
      category: 'home_categoryTools'.tr,
      commonWidgetsProvider: (data) async {
        return cmd.NodesCommandWidgetsProvider.provideCommonWidgets(data);
      },
      builder: (context, config) {
        return _NodesListLiveWidget(
          config: _ensureConfigHasCommonWidget(config),
          widgetDefinition: registry.getWidget('nodes_notebook_list')!,
        );
      },
    ),
  );
}

/// 确保 config 包含默认的公共小组件配置
Map<String, dynamic> _ensureConfigHasCommonWidget(
  Map<String, dynamic> config,
) {
  final newConfig = Map<String, dynamic>.from(config);
  if (!newConfig.containsKey('selectorWidgetConfig')) {
    newConfig['selectorWidgetConfig'] = {
      'commonWidgetId': defaultWidgetType.name,
      'usesCommonWidget': true,
      'commonWidgetProps': {},
    };
  }
  return newConfig;
}
