/// 待办插件 - 概览组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'package:Memento/plugins/todo/home_widgets/providers.dart';

/// 注册 2x2 概览组件
void registerOverviewWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'todo_overview',
      pluginId: 'todo',
      name: 'todo_overviewName'.tr,
      description: 'todo_overviewDescription'.tr,
      icon: Icons.check_box_outlined,
      color: Colors.blue,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: 'home_categoryTools'.tr,
      builder:
          (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: getAvailableStats,
    ),
  );
}

/// 构建 2x2 概览组件
Widget _buildOverviewWidget(
  BuildContext context,
  Map<String, dynamic> config,
) {
  // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
  return StatefulBuilder(
    builder: (context, setState) {
      return EventListenerContainer(
        events: const ['task_added', 'task_deleted', 'task_completed'],
        onEvent: () => setState(() {}),
        child: _buildOverviewWidgetContent(context, config),
      );
    },
  );
}

/// 构建概览小组件内容（获取最新数据）
Widget _buildOverviewWidgetContent(
  BuildContext context,
  Map<String, dynamic> config,
) {
  try {
    // 解析插件配置
    PluginWidgetConfig widgetConfig;
    try {
      if (config.containsKey('pluginWidgetConfig')) {
        widgetConfig = PluginWidgetConfig.fromJson(
          config['pluginWidgetConfig'] as Map<String, dynamic>,
        );
      } else {
        widgetConfig = PluginWidgetConfig();
      }
    } catch (e) {
      widgetConfig = PluginWidgetConfig();
    }

    // 获取可用的统计项数据（从 PluginManager 获取最新数据）
    final availableItems = getAvailableStats(context);

    // 使用通用小组件
    return GenericPluginWidget(
      pluginId: 'todo',
      pluginName: 'todo_name'.tr,
      pluginIcon: Icons.check_box,
      pluginDefaultColor: Colors.blue,
      availableItems: availableItems,
      config: widgetConfig,
    );
  } catch (e) {
    return HomeWidget.buildErrorWidget(context, e.toString());
  }
}
