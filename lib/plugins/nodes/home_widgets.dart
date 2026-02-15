import 'package:get/get.dart' hide Node;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'nodes_plugin.dart';
import 'models/node.dart';
import 'screens/node_edit_screen/node_edit_screen.dart';
import 'screens/nodes_screen.dart';
import 'controllers/nodes_controller.dart';

/// 节点笔记本插件的主页小组件注册
class NodesHomeWidgets {
  /// 注册所有节点插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(
      HomeWidget(
        id: 'nodes_icon',
        pluginId: 'nodes',
        name: 'nodes_widgetName'.tr,
        description: 'nodes_widgetDescription'.tr,
        icon: Icons.account_tree,
        color: Colors.amber,
        defaultSize: const SmallSize(),
        supportedSizes: [const SmallSize()],
        category: 'home_categoryTools'.tr,
        builder:
            (context, config) => GenericIconWidget(
              icon: Icons.account_tree,
              color: Colors.amber,
              name: 'nodes_name'.tr,
            ),
      ),
    );

    // 2x2 详细卡片 - 显示统计信息
    registry.register(
      HomeWidget(
        id: 'nodes_overview',
        pluginId: 'nodes',
        name: 'nodes_overviewName'.tr,
        description: 'nodes_overviewDescription'.tr,
        icon: Icons.dashboard,
        color: Colors.amber,
        defaultSize: const LargeSize(),
        supportedSizes: [const LargeSize()],
        category: 'home_categoryTools'.tr,
        builder: (context, config) => _buildOverviewWidget(context, config),
        availableStatsProvider: _getAvailableStats,
      ),
    );

    // 节点列表小组件 - 选择笔记本展示节点（支持多种尺寸）
    registry.register(
      HomeWidget(
        id: 'nodes_notebook_list',
        pluginId: 'nodes',
        name: 'nodes_notebookListName'.tr,
        description: 'nodes_notebookListDescription'.tr,
        icon: Icons.view_list,
        color: Colors.amber,
        defaultSize: const WideSize()2,
        supportedSizes: [
          const LargeSize(), // 2x2
          const LargeSize()3, // 2x3
          const WideSize()2, // 4x2
          const WideSize()3, // 4x3
        ],
        category: 'home_categoryTools'.tr,
        selectorId: 'nodes.notebook',
        dataRenderer: _renderNotebookNodes,
        navigationHandler: _navigateToNotebook,
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
  static Widget _buildOverviewWidget(
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

      // 获取可用的统计项数据
      final availableItems = _getAvailableStats(context);

      // 使用通用小组件
      return GenericPluginWidget(
        pluginId: 'nodes',
        pluginName: 'nodes_name'.tr,
        pluginIcon: Icons.account_tree,
        pluginDefaultColor: Colors.amber,
        availableItems: availableItems,
        config: widgetConfig,
      );
    } catch (e) {
      return HomeWidget.buildErrorWidget(context, e.toString());
    }
  }


  /// 渲染笔记本节点列表
  static Widget _renderNotebookNodes(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    final savedData = result.data is Map<String, dynamic>
        ? result.data as Map<String, dynamic>
        : <String, dynamic>{};
    final notebookId = savedData['id'] as String? ?? '';

    // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
    return StatefulBuilder(
      builder: (context, setState) {
        return EventListenerContainer(
          events: const [
            'nodes_notebook_added',
            'nodes_notebook_updated',
            'nodes_notebook_deleted',
            'nodes_node_added',
            'nodes_node_updated',
            'nodes_node_deleted',
          ],
          onEvent: () => setState(() {}),
          child: _buildNotebookWidget(context, notebookId, savedData, result),
        );
      },
    );
  }

  /// 构建笔记本小组件内容（获取最新数据）
  static Widget _buildNotebookWidget(
    BuildContext context,
    String notebookId,
    Map<String, dynamic> savedData,
    SelectorResult result,
  ) {
    // 从 PluginManager 获取最新的节点数据
    final nodes = _loadNotebookNodesSync(notebookId);

    if (nodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_outlined, size: 32, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'nodes_noNodes'.tr,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    // 扁平化节点树（显示所有节点包括子节点，带深度信息）
    final flatNodes = <Map<String, dynamic>>[];
    void flattenNodes(List<Node> nodeList, int depth) {
      for (var node in nodeList) {
        flatNodes.add({'node': node, 'depth': depth});
        if (node.children.isNotEmpty) {
          flattenNodes(node.children, depth + 1);
        }
      }
    }

    flattenNodes(nodes, 0);

    final notebookTitle =
        savedData['title'] as String? ?? 'nodes_notebook'.tr;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToNotebook(context, result),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: 显示笔记本标题
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        notebookTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${flatNodes.length} ${'nodes_nodes'.tr}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 节点列表
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: flatNodes.length,
                  separatorBuilder:
                      (context, index) => Divider(
                        height: 1,
                        color: Theme.of(context).dividerColor.withOpacity(0.3),
                      ),
                  itemBuilder: (context, index) {
                    final item = flatNodes[index];
                    final node = item['node'] as Node;
                    final depth = item['depth'] as int;
                    return _buildNodeListItem(context, notebookId, node, depth);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建单个节点列表项（左侧颜色条 + 缩进 + 标题）
  static Widget _buildNodeListItem(BuildContext context, String notebookId, Node node, int depth) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () async {
        final plugin = PluginManager.instance.getPlugin('nodes') as NodesPlugin?;
        if (plugin == null) return;

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider<NodesController>.value(
              value: plugin.controller,
              child: NodeEditScreen(
                notebookId: notebookId,
                node: node,
                isNew: false,
              ),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // 层级缩进（颜色竖条也跟着缩进）
            SizedBox(width: depth * 16.0),
            // 左侧颜色竖条
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: node.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // 节点标题
            Expanded(
              child: Text(
                node.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: (14 - depth * 0.5).clamp(11, 14), // 深层字体略小
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 从 controller 加载笔记本的节点（同步版本，用于事件监听器）
  static List<Node> _loadNotebookNodesSync(String notebookId) {
    try {
      final plugin = PluginManager.instance.getPlugin('nodes') as NodesPlugin?;
      if (plugin == null || notebookId.isEmpty) return [];

      final notebook = plugin.controller.getNotebook(notebookId);
      if (notebook == null) return [];

      return notebook.nodes;
    } catch (e) {
      debugPrint('加载笔记本节点失败: $e');
      return [];
    }
  }

  /// 导航到笔记本详情页
  static Future<void> _navigateToNotebook(
    BuildContext context,
    SelectorResult result,
  ) async {
    final data =
        result.data is Map<String, dynamic>
            ? result.data as Map<String, dynamic>
            : {};
    final notebookId = data['id'] as String?;

    if (notebookId == null || notebookId.isEmpty) return;

    final plugin = PluginManager.instance.getPlugin('nodes') as NodesPlugin?;
    if (plugin == null) return;

    final notebook = plugin.controller.getNotebook(notebookId);
    if (notebook == null) return;

    await NavigationHelper.push(
      context,
      ChangeNotifierProvider<NodesController>.value(
        value: plugin.controller,
        child: NodesScreen(notebook: notebook),
      ),
    );
  }
}
