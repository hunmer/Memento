import 'package:get/get.dart' hide Node;
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'nodes_plugin.dart';

/// 节点笔记本插件的主页小组件注册
class NodesHomeWidgets {
  /// 注册所有节点插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'nodes_icon',
      pluginId: 'nodes',
      name: 'nodes_widgetName'.tr,
      description: 'nodes_widgetDescription'.tr,
      icon: Icons.account_tree,
      color: Colors.amber,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => GenericIconWidget(
        icon: Icons.account_tree,
        color: Colors.amber,
        name: 'nodes_name'.tr,
      ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'nodes_overview',
      pluginId: 'nodes',
      name: 'nodes_overviewName'.tr,
      description: 'nodes_overviewDescription'.tr,
      icon: Icons.dashboard,
      color: Colors.amber,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ));
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    try {
      final plugin = PluginManager.instance.getPlugin('nodes') as NodesPlugin?;
      if (plugin == null) return [];

      final controller = plugin.controller;
      final notebookCount = controller.notebooks.length;

      int totalNodes = 0;
      int todoNodes = 0;

      for (var notebook in controller.notebooks) {
        totalNodes += _countAllNodes(notebook.nodes);
        todoNodes += _countTodoNodes(notebook.nodes);
      }

      return [
        StatItemData(
          id: 'notebooks_count',
          label: 'nodes_notebooksCount'.tr,
          value: '$notebookCount',
          highlight: notebookCount > 0,
          color: Colors.amber,
        ),
        StatItemData(
          id: 'nodes_count',
          label: 'nodes_nodesCount'.tr,
          value: '$totalNodes',
          highlight: false,
        ),
        StatItemData(
          id: 'todo_nodes_count',
          label: 'nodes_todoNodes'.tr,
          value: '$todoNodes',
          highlight: todoNodes > 0,
          color: Colors.orange,
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  /// 递归计算所有节点总数
  static int _countAllNodes(List nodes) {
    int count = nodes.length;
    for (var node in nodes) {
      count += _countAllNodes(node.children);
    }
    return count;
  }

  /// 递归计算待办节点数量
  static int _countTodoNodes(List nodes) {
    int count = 0;
    for (var node in nodes) {
      // NodeStatus.todo 的值是 0
      if (node.status.index == 0) {
        count++;
      }
      count += _countTodoNodes(node.children);
    }
    return count;
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(BuildContext context, Map<String, dynamic> config) {
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

      // 获取可用的统计项数据
      final availableItems = _getAvailableStats(context);

      // 使用通用小组件
      return GenericPluginWidget(
        pluginName: 'nodes_name'.tr,
        pluginIcon: Icons.account_tree,
        pluginDefaultColor: Colors.amber,
        availableItems: availableItems,
        config: widgetConfig,
      );
    } catch (e) {
      return _buildErrorWidget(context, e.toString());
    }
  }

  /// 构建错误提示组件
  static Widget _buildErrorWidget(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 32, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            'home_loadFailed'.tr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
