import 'package:flutter/material.dart';
import '../../screens/home_screen/models/home_widget_size.dart';
import '../../screens/home_screen/widgets/home_widget.dart';
import '../../screens/home_screen/managers/home_widget_registry.dart';
import '../../core/plugin_manager.dart';
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
      builder: (context, config) => _buildIconWidget(context),
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
      builder: (context, config) => _buildOverviewWidget(context),
    ));
  }

  /// 构建 1x1 图标组件
  static Widget _buildIconWidget(BuildContext context) {
    return Center(
      child: Icon(
        Icons.account_tree,
        size: 48,
        color: Colors.amber,
      ),
    );
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(BuildContext context) {
    try {
      final plugin = PluginManager.instance.getPlugin('nodes') as NodesPlugin?;
      if (plugin == null) {
        return _buildErrorWidget(context, '插件未加载');
      }

      final theme = Theme.of(context);
      final l10n = NodesLocalizations.of(context);
      final controller = plugin.controller;

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部图标和标题
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_tree,
                    size: 24,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 统计信息
            Expanded(
              child: FutureBuilder<Map<String, int>>(
                future: _getStatistics(controller),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final stats = snapshot.data ?? {
                    'notebooks': 0,
                    'nodes': 0,
                    'todo': 0,
                  };

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 第一行：笔记本数和节点数
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            label: l10n.notebooksCount,
                            value: '${stats['notebooks']}',
                            theme: theme,
                            highlight: stats['notebooks']! > 0,
                            color: Colors.amber,
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: theme.dividerColor,
                          ),
                          _StatItem(
                            label: l10n.nodesCount,
                            value: '${stats['nodes']}',
                            theme: theme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 第二行：待办节点数
                      _StatItem(
                        label: l10n.pendingNodesCount,
                        value: '${stats['todo']}',
                        theme: theme,
                        highlight: stats['todo']! > 0,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return _buildErrorWidget(context, e.toString());
    }
  }

  /// 获取统计数据
  static Future<Map<String, int>> _getStatistics(controller) async {
    final notebookCount = controller.notebooks.length;

    int totalNodes = 0;
    int todoNodes = 0;

    for (var notebook in controller.notebooks) {
      totalNodes += _countAllNodes(notebook.nodes);
      todoNodes += _countTodoNodes(notebook.nodes);
    }

    return {
      'notebooks': notebookCount,
      'nodes': totalNodes,
      'todo': todoNodes,
    };
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

/// 统计项组件
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final bool highlight;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.theme,
    this.highlight = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: highlight && color != null ? color : null,
          ),
        ),
      ],
    );
  }
}
