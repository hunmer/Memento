import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'nodes_plugin.dart';
import 'l10n/nodes_localizations.dart';

/// 节点笔记本插件的主页小组件注册
class NodesHomeWidgets {
  /// 注册所有节点插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'nodes_icon',
      pluginId: 'nodes',
      name: '节点',
      description: '快速打开节点笔记本',
      icon: Icons.account_tree,
      color: Colors.amber,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: '工具',
      builder: (context, config) => const GenericIconWidget(
        icon: Icons.account_tree,
        color: Colors.amber,
        name: '节点',
      ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'nodes_overview',
      pluginId: 'nodes',
      name: '节点概览',
      description: '显示笔记本、节点和待办统计',
      icon: Icons.dashboard,
      color: Colors.amber,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: '工具',
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ));
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats() {
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
          label: '笔记本数',
          value: '$notebookCount',
          highlight: notebookCount > 0,
          color: Colors.amber,
        ),
        StatItemData(
          id: 'nodes_count',
          label: '节点数',
          value: '$totalNodes',
          highlight: false,
        ),
        StatItemData(
          id: 'todo_nodes_count',
          label: '待办节点',
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
      final l10n = NodesLocalizations.of(context);

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
      final availableItems = _getAvailableStats();

      // 使用通用小组件
      return GenericPluginWidget(
        pluginName: l10n.name,
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
            '加载失败',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
