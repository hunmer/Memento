/// 待办插件 - 待办列表小组件注册（公共小组件）
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/base/live_selector_widget.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';

// 导入 CommandWidgetsProvider
import 'package:Memento/plugins/todo/home_widgets/providers/command_widgets_provider.dart'
    as cmd;

/// 默认显示的公共小组件类型
const CommonWidgetId defaultWidgetType = CommonWidgetId.taskListCard;

/// 待办列表小组件（基于 LiveSelectorWidget）
///
/// 默认显示 taskListCard 公共小组件，支持实时更新
class _TodoListLiveWidget extends LiveSelectorWidget {
  const _TodoListLiveWidget({
    super.key,
    required super.config,
    required super.widgetDefinition,
  });

  @override
  List<String> get eventListeners => const [
    'task_added',
    'task_deleted',
    'task_completed',
  ];

  @override
  Future<Map<String, dynamic>> getLiveData(Map<String, dynamic> config) async {
    return cmd.TodoCommandWidgetsProvider.provideCommonWidgets({});
  }

  @override
  String get widgetTag => 'TodoListWidget';

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

/// 注册 2x2 待办列表小组件（公共小组件，无配置）
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
      supportedSizes: const [LargeSize()],
      category: 'home_categoryTools'.tr,
      commonWidgetsProvider: (data) async {
        return cmd.TodoCommandWidgetsProvider.provideCommonWidgets(data);
      },
      builder: (context, config) {
        return _TodoListLiveWidget(
          config: _ensureConfigHasCommonWidget(config),
          widgetDefinition: registry.getWidget('todo_list')!,
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
