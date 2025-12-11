/// Nodes 插件 - 服务端 Repository 实现
library;

import 'package:shared_models/shared_models.dart';
import '../services/plugin_data_service.dart';

class ServerNodesRepository implements INodesRepository {
  final PluginDataService dataService;
  final String userId;

  static const String _pluginId = 'nodes';

  ServerNodesRepository({
    required this.dataService,
    required this.userId,
  });

  // ============ 内部方法 ============

  Future<List<NotebookDto>> _readAllNotebooks() async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      'nodes_notebooks.json',
    );
    if (data == null) return [];

    final notebooks = data['notebooks'] as List<dynamic>? ?? [];
    return notebooks
        .map((e) => NotebookDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAllNotebooks(List<NotebookDto> notebooks) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'nodes_notebooks.json',
      {'notebooks': notebooks.map((n) => n.toJson()).toList()},
    );
  }

  // ============ 笔记本操作实现 ============

  @override
  Future<Result<List<NotebookDto>>> getNotebooks(
      {PaginationParams? pagination}) async {
    try {
      var notebooks = await _readAllNotebooks();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          notebooks,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(notebooks);
    } catch (e) {
      return Result.failure('获取笔记本列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<NotebookDto?>> getNotebookById(String id) async {
    try {
      final notebooks = await _readAllNotebooks();
      final notebook = notebooks.where((n) => n.id == id).firstOrNull;
      return Result.success(notebook);
    } catch (e) {
      return Result.failure('获取笔记本失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<NotebookDto>> createNotebook(NotebookDto notebook) async {
    try {
      final notebooks = await _readAllNotebooks();
      notebooks.add(notebook);
      await _saveAllNotebooks(notebooks);
      return Result.success(notebook);
    } catch (e) {
      return Result.failure('创建笔记本失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<NotebookDto>> updateNotebook(
      String id, NotebookDto notebook) async {
    try {
      final notebooks = await _readAllNotebooks();
      final index = notebooks.indexWhere((n) => n.id == id);

      if (index == -1) {
        return Result.failure('笔记本不存在', code: ErrorCodes.notFound);
      }

      notebooks[index] = notebook;
      await _saveAllNotebooks(notebooks);
      return Result.success(notebook);
    } catch (e) {
      return Result.failure('更新笔记本失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteNotebook(String id) async {
    try {
      final notebooks = await _readAllNotebooks();
      final initialLength = notebooks.length;
      notebooks.removeWhere((n) => n.id == id);

      if (notebooks.length == initialLength) {
        return Result.failure('笔记本不存在', code: ErrorCodes.notFound);
      }

      await _saveAllNotebooks(notebooks);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除笔记本失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<NotebookDto>>> searchNotebooks(NotebookQuery query) async {
    try {
      var notebooks = await _readAllNotebooks();

      if (query.titleKeyword != null) {
        notebooks = notebooks.where((notebook) {
          return notebook.title.toLowerCase().contains(
                query.titleKeyword!.toLowerCase(),
              );
        }).toList();
      }

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          notebooks,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(notebooks);
    } catch (e) {
      return Result.failure('搜索笔记本失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 节点操作实现 ============

  @override
  Future<Result<List<NodeDto>>> getNodes(String notebookId,
      {PaginationParams? pagination}) async {
    try {
      final notebooks = await _readAllNotebooks();
      final notebook = notebooks.where((n) => n.id == notebookId).firstOrNull;

      if (notebook == null) {
        return Result.success([]);
      }

      var nodes = notebook.nodes;

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          nodes,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(nodes);
    } catch (e) {
      return Result.failure('获取节点列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<NodeDto?>> getNodeById(String id) async {
    try {
      // 需要遍历所有笔记本的节点树
      final notebooks = await _readAllNotebooks();
      for (final notebook in notebooks) {
        final node = _findNodeById(notebook.nodes, id);
        if (node != null) {
          return Result.success(node);
        }
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure('获取节点失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<NodeDto>> createNode(NodeDto node) async {
    try {
      final notebooks = await _readAllNotebooks();

      // 找到父节点所在的笔记本
      NotebookDto? targetNotebook;
      NodeDto? parentNode;

      // 查找笔记本和父节点
      for (final notebook in notebooks) {
        if (node.parentId.isEmpty) {
          // 根节点，直接添加到笔记本
          targetNotebook = notebook;
          break;
        } else {
          // 查找父节点
          parentNode = _findNodeById(notebook.nodes, node.parentId);
          if (parentNode != null) {
            targetNotebook = notebook;
            break;
          }
        }
      }

      if (targetNotebook == null) {
        return Result.failure('找不到目标笔记本', code: ErrorCodes.notFound);
      }

      // 如果有父节点，添加到父节点的 children 中
      if (parentNode != null) {
        final updatedParent = parentNode.copyWith(
          children: [...parentNode.children, node],
        );
        _updateNodeInNotebook(targetNotebook, updatedParent);
      } else {
        // 添加为根节点
        final updatedNotebook = targetNotebook.copyWith(
          nodes: [...targetNotebook.nodes, node],
        );
        final index = notebooks.indexWhere((n) => n.id == targetNotebook!.id);
        notebooks[index] = updatedNotebook;
      }

      await _saveAllNotebooks(notebooks);
      return Result.success(node);
    } catch (e) {
      return Result.failure('创建节点失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<NodeDto>> updateNode(String id, NodeDto node) async {
    try {
      final notebooks = await _readAllNotebooks();

      // 查找包含该节点的笔记本
      for (final notebook in notebooks) {
        final existingNode = _findNodeById(notebook.nodes, id);
        if (existingNode != null) {
          _updateNodeInNotebook(notebook, node);
          await _saveAllNotebooks(notebooks);
          return Result.success(node);
        }
      }

      return Result.failure('节点不存在', code: ErrorCodes.notFound);
    } catch (e) {
      return Result.failure('更新节点失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteNode(String id) async {
    try {
      final notebooks = await _readAllNotebooks();

      // 查找并删除节点
      for (final notebook in notebooks) {
        if (_deleteNodeFromNotebook(notebook, id)) {
          await _saveAllNotebooks(notebooks);
          return Result.success(true);
        }
      }

      return Result.failure('节点不存在', code: ErrorCodes.notFound);
    } catch (e) {
      return Result.failure('删除节点失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<NodeDto>>> searchNodes(NodeQuery query) async {
    try {
      final notebooks = await _readAllNotebooks();
      final notebook =
          notebooks.where((n) => n.id == query.notebookId).firstOrNull;

      if (notebook == null) {
        return Result.success([]);
      }

      var allNodes = _getAllNodes(notebook.nodes);

      if (query.titleKeyword != null) {
        allNodes = allNodes.where((node) {
          return node.title.toLowerCase().contains(
                query.titleKeyword!.toLowerCase(),
              );
        }).toList();
      }

      if (query.status != null) {
        allNodes =
            allNodes.where((node) => node.status == query.status).toList();
      }

      if (query.tag != null) {
        allNodes =
            allNodes.where((node) => node.tags.contains(query.tag)).toList();
      }

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          allNodes,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(allNodes);
    } catch (e) {
      return Result.failure('搜索节点失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 树形结构操作实现 ============

  @override
  Future<Result<NodeDto>> toggleNodeExpansion(
      String id, bool isExpanded) async {
    try {
      final notebooks = await _readAllNotebooks();

      for (final notebook in notebooks) {
        final node = _findNodeById(notebook.nodes, id);
        if (node != null) {
          final updatedNode = node.copyWith(isExpanded: isExpanded);
          _updateNodeInNotebook(notebook, updatedNode);
          await _saveAllNotebooks(notebooks);
          return Result.success(updatedNode);
        }
      }

      return Result.failure('节点不存在', code: ErrorCodes.notFound);
    } catch (e) {
      return Result.failure('切换节点展开状态失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<String>>> getNodePath(
      String notebookId, String nodeId) async {
    try {
      final notebooks = await _readAllNotebooks();
      final notebook = notebooks.where((n) => n.id == notebookId).firstOrNull;

      if (notebook == null) {
        return Result.failure('笔记本不存在', code: ErrorCodes.notFound);
      }

      final path = _findNodePath(notebook.nodes, nodeId, []);
      return Result.success(path.reversed.toList());
    } catch (e) {
      return Result.failure('获取节点路径失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<NodeDto>>> getSiblingNodes(
      String notebookId, String nodeId) async {
    try {
      final notebooks = await _readAllNotebooks();
      final notebook = notebooks.where((n) => n.id == notebookId).firstOrNull;

      if (notebook == null) {
        return Result.success([]);
      }

      final siblings = _findSiblingNodes(notebook.nodes, nodeId, []);
      return Result.success(siblings);
    } catch (e) {
      return Result.failure('获取同级节点失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 辅助方法 ============

  NodeDto? _findNodeById(List<NodeDto> nodes, String id) {
    for (final node in nodes) {
      if (node.id == id) {
        return node;
      }
      final found = _findNodeById(node.children, id);
      if (found != null) return found;
    }
    return null;
  }

  bool _updateNodeInNotebook(NotebookDto notebook, NodeDto updatedNode) {
    return _updateNodeInList(notebook.nodes, updatedNode);
  }

  bool _updateNodeInList(List<NodeDto> nodes, NodeDto updatedNode) {
    for (int i = 0; i < nodes.length; i++) {
      if (nodes[i].id == updatedNode.id) {
        nodes[i] = updatedNode;
        return true;
      }
      if (_updateNodeInList(nodes[i].children, updatedNode)) {
        return true;
      }
    }
    return false;
  }

  bool _deleteNodeFromNotebook(NotebookDto notebook, String nodeId) {
    return _deleteNodeFromList(notebook.nodes, nodeId);
  }

  bool _deleteNodeFromList(List<NodeDto> nodes, String nodeId) {
    for (int i = 0; i < nodes.length; i++) {
      if (nodes[i].id == nodeId) {
        nodes.removeAt(i);
        return true;
      }
      if (_deleteNodeFromList(nodes[i].children, nodeId)) {
        return true;
      }
    }
    return false;
  }

  List<String> _findNodePath(
      List<NodeDto> nodes, String nodeId, List<String> path) {
    for (final node in nodes) {
      if (node.id == nodeId) {
        path.add(node.title);
        return path;
      }
      final found = _findNodePath(node.children, nodeId, path);
      if (found.isNotEmpty) {
        path.add(node.title);
        return path;
      }
    }
    return [];
  }

  List<NodeDto> _findSiblingNodes(
      List<NodeDto> nodes, String nodeId, List<NodeDto> siblings) {
    for (final node in nodes) {
      if (node.id == nodeId) {
        return siblings;
      }
      final found = _findSiblingNodes(node.children, nodeId, node.children);
      if (found.isNotEmpty) {
        return found;
      }
    }
    return siblings;
  }

  List<NodeDto> _getAllNodes(List<NodeDto> nodes) {
    final List<NodeDto> allNodes = [];
    for (final node in nodes) {
      allNodes.add(node);
      allNodes.addAll(_getAllNodes(node.children));
    }
    return allNodes;
  }
}
