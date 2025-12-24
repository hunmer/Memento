import 'package:get/get.dart' hide Node;
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/widgets/quill_viewer/quill_viewer.dart';
import 'package:Memento/plugins/nodes/controllers/nodes_controller.dart';
import 'package:Memento/plugins/nodes/models/notebook.dart';
import 'package:Memento/plugins/nodes/models/node.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/plugins/nodes/widgets/node_item.dart';
import 'node_edit_screen.dart';
import 'package:uuid/uuid.dart';

class NodesScreen extends StatefulWidget {
  final Notebook notebook;

  const NodesScreen({super.key, required this.notebook});

  @override
  State<NodesScreen> createState() => _NodesScreenState();
}

class _NodesScreenState extends State<NodesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<NodesController>(context, listen: true);

    final currentNotebook = controller.getNotebook(widget.notebook.id);
    final theme = Theme.of(context);

    return SuperCupertinoNavigationWrapper(
      title: Text(
        widget.notebook.title,
        style: TextStyle(color: theme.textTheme.titleLarge?.color),
      ),
      largeTitle: '节点',

      enableSearchBar: true,
      searchPlaceholder: '搜索节点标题或笔记',
      onSearchChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: theme.iconTheme.color),
          tooltip: '搜索节点',
          onPressed: () {
            // 点击搜索图标会触发搜索框聚焦，实际搜索逻辑由 onSearchChanged 处理
          },
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
          onSelected:
              (value) => _handleMenuAction(
                value,
                context,
                controller,
                currentNotebook,
              ),
          itemBuilder:
              (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'copy',
                  child: ListTile(
                    leading: const Icon(Icons.copy),
                    title: Text('nodes_copyToText'.tr),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'clear',
                  child: ListTile(
                    leading: const Icon(Icons.clear_all),
                    title: Text('nodes_clearNodes'.tr),
                  ),
                ),
              ],
        ),
      ],
      body: Stack(
        children: [
          currentNotebook?.nodes.isEmpty ?? true
              ? Center(child: Text('nodes_noNodesYet'.tr))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: currentNotebook?.nodes.length ?? 0,
                itemBuilder: (context, index) {
                  return NodeItem(
                    node: currentNotebook!.nodes[index],
                    notebookId: widget.notebook.id,
                    depth: 0,
                  );
                },
              ),
          // FAB 覆盖层
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () => _addRootNode(context),
            ),
          ),
        ],
      ),
      searchBody: _buildSearchBody(controller, currentNotebook, _searchQuery),
    );
  }

  void _handleMenuAction(
    String value,
    BuildContext context,
    NodesController controller,
    Notebook? currentNotebook,
  ) {
    if (currentNotebook == null) return;

    switch (value) {
      case 'copy':
        _copyToText(context, currentNotebook);
        break;
      case 'clear':
        _showClearConfirmDialog(context, controller, currentNotebook);
        break;
    }
  }

  void _copyToText(BuildContext context, Notebook notebook) {
    final buffer = StringBuffer();

    void processNode(Node node, int depth) {
      buffer.writeln('${'  ' * depth}${node.title}');
      if (node.notes.isNotEmpty) {
        buffer.writeln('${'  ' * (depth + 1)}${node.notes}');
      }
      for (var child in node.children) {
        processNode(child, depth + 1);
      }
    }

    for (var node in notebook.nodes) {
      processNode(node, 0);
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    Toast.success('nodes_copiedToClipboard'.tr);
  }

  void _showClearConfirmDialog(
    BuildContext context,
    NodesController controller,
    Notebook notebook,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('nodes_clearNodesTitle'.tr),
            content: Text('nodes_clearNodesConfirm'.tr),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('nodes_cancel'.tr),
              ),
              TextButton(
                onPressed: () {
                  controller.clearNodes(notebook.id);
                  Navigator.pop(context);
                  Toast.success('nodes_nodesCleared'.tr);
                },
                child: Text('nodes_clear'.tr),
              ),
            ],
          ),
    );
  }

  void _addRootNode(BuildContext context) {
    final controller = Provider.of<NodesController>(context, listen: false);
    final newNode = Node(
      id: const Uuid().v4(),
      title: '',
      status: NodeStatus.todo,
      createdAt: DateTime.now(),
    );

    NavigationHelper.push(
      context,
      ChangeNotifierProvider<NodesController>.value(
        value: controller,
        child: NodeEditScreen(
          notebookId: widget.notebook.id,
          node: newNode,
          isNew: true,
        ),
      ),
    );
  }

  /// 构建搜索结果页面
  Widget _buildSearchBody(
    NodesController controller,
    Notebook? currentNotebook,
    String query,
  ) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '输入关键词搜索节点',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    // 执行搜索：匹配节点标题或笔记内容
    final allNodes = _getAllNodes(currentNotebook?.nodes ?? []);
    final matchedNodes =
        allNodes.where((node) {
          return node.title.toLowerCase().contains(query.toLowerCase()) ||
              node.notes.toLowerCase().contains(query.toLowerCase());
        }).toList();

    if (matchedNodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.find_replace, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '未找到匹配的节点',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '试试其他关键词',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    // 显示搜索结果
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matchedNodes.length,
      itemBuilder: (context, index) {
        final node = matchedNodes[index];
        // 获取节点路径显示
        final path = controller.getNodePath(widget.notebook.id, node.id);
        final pathText = path.join(' / ');

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: node.color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(node.status),
                color: _getStatusColor(node.status),
                size: 20,
              ),
            ),
            title: Text(
              node.title.isEmpty ? '(无标题)' : node.title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pathText.isNotEmpty) ...[
                  Text(
                    pathText,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                ],
                if (node.notes.isNotEmpty) ...[
                  Container(
                    height: 60,
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: ClipRect(
                      child: SingleChildScrollView(
                        child: QuillViewer(data: node.notes, selectable: false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Wrap(
                  spacing: 8,
                  children: [
                    if (node.tags.isNotEmpty)
                      ...node.tags.map(
                        (tag) => Chip(
                          label: Text(
                            tag,
                            style: const TextStyle(fontSize: 11),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            onTap: () {
              // 点击搜索结果进入编辑界面
              NavigationHelper.push(
                context,
                ChangeNotifierProvider<NodesController>.value(
                  value: controller,
                  child: NodeEditScreen(
                    notebookId: widget.notebook.id,
                    node: node,
                    isNew: false,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// 递归获取所有节点（包括子节点）
  List<Node> _getAllNodes(List<Node> nodes) {
    final result = <Node>[];
    for (final node in nodes) {
      result.add(node);
      if (node.children.isNotEmpty) {
        result.addAll(_getAllNodes(node.children));
      }
    }
    return result;
  }

  /// 根据节点状态获取图标
  IconData _getStatusIcon(NodeStatus status) {
    switch (status) {
      case NodeStatus.todo:
        return Icons.radio_button_unchecked;
      case NodeStatus.doing:
        return Icons.access_time;
      case NodeStatus.done:
        return Icons.check_circle;
      case NodeStatus.none:
        return Icons.circle_outlined;
    }
  }

  /// 根据节点状态获取颜色
  Color _getStatusColor(NodeStatus status) {
    switch (status) {
      case NodeStatus.todo:
        return Colors.grey;
      case NodeStatus.doing:
        return Colors.blue;
      case NodeStatus.done:
        return Colors.green;
      case NodeStatus.none:
        return Colors.grey.shade400;
    }
  }
}
