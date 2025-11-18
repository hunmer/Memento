import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/node.dart';
import '../models/notebook.dart';
import '../../../core/storage/storage_manager.dart';

class NodesController extends ChangeNotifier {
  final StorageManager _storageManager;
  List<Notebook> _notebooks = [];
  Notebook? _selectedNotebook;

  NodesController(this._storageManager) {
    _loadData();
  }

  List<Notebook> get notebooks => _notebooks;
  Notebook? get selectedNotebook => _selectedNotebook;

  Notebook? getNotebook(String notebookId) {
    return _notebooks.firstWhere(
      (notebook) => notebook.id == notebookId,
      orElse: () => Notebook(id: '', title: '', icon: Icons.book),
    );
  }

  Future<void> clearNodes(String notebookId) async {
    final index = _notebooks.indexWhere(
      (notebook) => notebook.id == notebookId,
    );
    if (index != -1) {
      _notebooks[index].nodes.clear();
      notifyListeners();
      await _saveData();
    }
  }

  void selectNotebook(Notebook notebook) {
    _selectedNotebook = notebook;
    notifyListeners();
  }

  Future<void> _loadData() async {
    try {
      final notebooksData = await _storageManager.read('nodes/nodes_notebooks');
      if (notebooksData.isNotEmpty) {
        final List<dynamic> notebooks =
            notebooksData['notebooks'] as List<dynamic>;
        _notebooks =
            notebooks
                .map((data) => Notebook.fromJson(data as Map<String, dynamic>))
                .toList();

        if (_notebooks.isNotEmpty && _selectedNotebook == null) {
          _selectedNotebook = _notebooks.first;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notebooks: $e');
      notifyListeners();
    }
  }

  Future<void> _saveData() async {
    try {
      final Map<String, dynamic> data = {
        'notebooks': _notebooks.map((notebook) => notebook.toJson()).toList(),
      };
      await _storageManager.write('nodes/nodes_notebooks', data);
    } catch (e) {
      debugPrint('Error saving notebooks: $e');
    }
  }

  Future<void> addNotebook(
    String title,
    IconData icon, {
    String? id,
    Color color = Colors.blue,
  }) async {
    final newNotebook = Notebook(
      id: id ?? const Uuid().v4(),
      title: title,
      icon: icon,
      color: color,
    );

    _notebooks.add(newNotebook);
    if (_notebooks.length == 1) {
      _selectedNotebook = newNotebook;
    }

    notifyListeners();
    await _saveData();
  }

  Future<void> updateNotebook(Notebook notebook) async {
    final index = _notebooks.indexWhere((n) => n.id == notebook.id);
    if (index != -1) {
      _notebooks[index] = notebook;
      if (_selectedNotebook?.id == notebook.id) {
        _selectedNotebook = notebook;
      }
      notifyListeners();
      await _saveData();
    }
  }

  Future<void> deleteNotebook(String notebookId) async {
    _notebooks.removeWhere((notebook) => notebook.id == notebookId);

    if (_selectedNotebook?.id == notebookId) {
      _selectedNotebook = _notebooks.isNotEmpty ? _notebooks.first : null;
    }

    notifyListeners();
    await _saveData();
  }

  Future<void> reorderNotebooks(int oldIndex, int newIndex) async {
    if (oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex >= _notebooks.length ||
        newIndex >= _notebooks.length) {
      return;
    }

    final Notebook item = _notebooks.removeAt(oldIndex);
    _notebooks.insert(newIndex, item);

    notifyListeners();
    await _saveData();
  }

  // Node operations
  Future<void> addNode(String notebookId, Node node, {String? parentId}) async {
    final notebookIndex = _notebooks.indexWhere(
      (notebook) => notebook.id == notebookId,
    );
    if (notebookIndex == -1) return;

    debugPrint('【NodesController】开始添加新节点: ${node.title}');
    debugPrint(
      '【NodesController】节点 parentId: ${node.parentId}, 传入的 parentId: $parentId',
    );

    // 使用节点自身的 parentId，如果没有则使用传入的 parentId
    final effectiveParentId =
        node.parentId.isNotEmpty ? node.parentId : (parentId ?? '');
    debugPrint('【NodesController】最终使用的 parentId: $effectiveParentId');

    if (effectiveParentId.isEmpty) {
      debugPrint('【NodesController】添加为根节点');
      // Add as root node
      _notebooks[notebookIndex].nodes.add(node);
    } else {
      debugPrint('【NodesController】尝试添加为子节点');
      // Add as child node
      final success = _addChildNode(
        _notebooks[notebookIndex].nodes,
        effectiveParentId,
        node,
      );
      if (!success) {
        // 如果找不到父节点，作为根节点添加
        debugPrint('【NodesController】未找到父节点: $effectiveParentId, 添加为根节点');
        _notebooks[notebookIndex].nodes.add(node);
      } else {
        debugPrint('【NodesController】成功添加为子节点');
      }
    }

    notifyListeners();
    await _saveData();
    debugPrint('【NodesController】节点添加完成，已通知UI更新');
  }

  bool _addChildNode(List<Node> nodes, String parentId, Node newNode) {
    for (int i = 0; i < nodes.length; i++) {
      if (nodes[i].id == parentId) {
        newNode.parentId = parentId;
        nodes[i].children.add(newNode);
        return true;
      }

      if (nodes[i].children.isNotEmpty) {
        if (_addChildNode(nodes[i].children, parentId, newNode)) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> updateNode(String notebookId, Node updatedNode) async {
    final notebookIndex = _notebooks.indexWhere(
      (notebook) => notebook.id == notebookId,
    );
    if (notebookIndex == -1) return;

    // 尝试在原位置更新节点
    final updated = _updateNodeInList(
      _notebooks[notebookIndex].nodes,
      updatedNode,
    );

    // 如果找不到节点（罕见情况），则删除旧节点并添加新节点
    if (!updated) {
      // 首先找到并删除原节点
      final oldNode = findNodeById(notebookId, updatedNode.id);
      if (oldNode != null) {
        _deleteNodeFromList(_notebooks[notebookIndex].nodes, updatedNode.id);
      }

      // 然后在新的位置添加更新后的节点
      if (updatedNode.parentId.isEmpty) {
        // 如果是根节点，直接添加到根节点列表
        _notebooks[notebookIndex].nodes.add(updatedNode);
      } else {
        // 否则添加为子节点
        final success = _addChildNode(
          _notebooks[notebookIndex].nodes,
          updatedNode.parentId,
          updatedNode,
        );
        if (!success) {
          // 如果找不到父节点，作为根节点添加
          debugPrint(
            'Parent node not found: ${updatedNode.parentId}, adding as root node',
          );
          _notebooks[notebookIndex].nodes.add(updatedNode);
        }
      }
    }

    notifyListeners();
    await _saveData();
  }

  bool _updateNodeInList(List<Node> nodes, Node updatedNode) {
    for (int i = 0; i < nodes.length; i++) {
      if (nodes[i].id == updatedNode.id) {
        // 保留原节点的子节点和展开状态
        final List<Node> originalChildren = nodes[i].children;
        final bool originalExpandedState = nodes[i].isExpanded;

        // 更新节点，但保留位置、子节点和展开状态
        updatedNode.children = originalChildren;
        updatedNode.isExpanded = originalExpandedState;
        nodes[i] = updatedNode;
        return true;
      }

      if (nodes[i].children.isNotEmpty) {
        if (_updateNodeInList(nodes[i].children, updatedNode)) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> deleteNode(String notebookId, String nodeId) async {
    final notebookIndex = _notebooks.indexWhere(
      (notebook) => notebook.id == notebookId,
    );
    if (notebookIndex == -1) return;

    _deleteNodeFromList(_notebooks[notebookIndex].nodes, nodeId);

    notifyListeners();
    await _saveData();
  }

  bool _deleteNodeFromList(List<Node> nodes, String nodeId) {
    for (int i = 0; i < nodes.length; i++) {
      if (nodes[i].id == nodeId) {
        nodes.removeAt(i);
        return true;
      }

      if (nodes[i].children.isNotEmpty) {
        if (_deleteNodeFromList(nodes[i].children, nodeId)) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> toggleNodeExpansion(String notebookId, String nodeId) async {
    final notebookIndex = _notebooks.indexWhere(
      (notebook) => notebook.id == notebookId,
    );
    if (notebookIndex == -1) return;

    _toggleNodeExpansionInList(_notebooks[notebookIndex].nodes, nodeId);

    notifyListeners();
  }

  bool _toggleNodeExpansionInList(List<Node> nodes, String nodeId) {
    for (int i = 0; i < nodes.length; i++) {
      if (nodes[i].id == nodeId) {
        nodes[i].isExpanded = !nodes[i].isExpanded;
        return true;
      }

      if (nodes[i].children.isNotEmpty) {
        if (_toggleNodeExpansionInList(nodes[i].children, nodeId)) {
          return true;
        }
      }
    }
    return false;
  }

  List<String> getNodePath(String notebookId, String nodeId) {
    final notebookIndex = _notebooks.indexWhere(
      (notebook) => notebook.id == notebookId,
    );
    if (notebookIndex == -1) return [];

    List<String> path = [];
    _findNodePath(_notebooks[notebookIndex].nodes, nodeId, path);
    return path.reversed.toList();
  }

  List<String> getNodePathIds(String notebookId, String nodeId) {
    final notebookIndex = _notebooks.indexWhere(
      (notebook) => notebook.id == notebookId,
    );
    if (notebookIndex == -1) return [];

    List<String> pathIds = [];
    _findNodePathIds(_notebooks[notebookIndex].nodes, nodeId, pathIds);
    return pathIds.reversed.toList();
  }

  bool _findNodePathIds(List<Node> nodes, String nodeId, List<String> pathIds) {
    for (final node in nodes) {
      if (node.id == nodeId) {
        pathIds.add(node.id);
        return true;
      }

      if (node.children.isNotEmpty) {
        if (_findNodePathIds(node.children, nodeId, pathIds)) {
          pathIds.add(node.id);
          return true;
        }
      }
    }
    return false;
  }

  bool _findNodePath(List<Node> nodes, String nodeId, List<String> path) {
    for (final node in nodes) {
      if (node.id == nodeId) {
        path.add(node.title);
        return true;
      }

      if (node.children.isNotEmpty) {
        if (_findNodePath(node.children, nodeId, path)) {
          path.add(node.title);
          return true;
        }
      }
    }
    return false;
  }

  // 通过ID查找节点
  Node? findNodeById(String notebookId, String nodeId) {
    final notebookIndex = _notebooks.indexWhere(
      (notebook) => notebook.id == notebookId,
    );
    if (notebookIndex == -1) return null;

    return _findNodeInList(_notebooks[notebookIndex].nodes, nodeId);
  }

  Node? _findNodeInList(List<Node> nodes, String nodeId) {
    for (final node in nodes) {
      if (node.id == nodeId) {
        return node;
      }

      if (node.children.isNotEmpty) {
        final foundNode = _findNodeInList(node.children, nodeId);
        if (foundNode != null) {
          return foundNode;
        }
      }
    }
    return null;
  }

  // 获取节点的所有同级节点（包括自身）
  List<Node> getSiblingNodes(String notebookId, String nodeId) {
    final notebookIndex = _notebooks.indexWhere(
      (notebook) => notebook.id == notebookId,
    );
    if (notebookIndex == -1) return [];

    // 如果是根节点，返回所有根节点
    final targetNode = findNodeById(notebookId, nodeId);
    if (targetNode == null) return [];

    if (targetNode.parentId.isEmpty) {
      return _notebooks[notebookIndex].nodes;
    }

    // 找到父节点
    final parentNode = findNodeById(notebookId, targetNode.parentId);
    if (parentNode == null) return [];

    // 返回父节点的所有子节点
    return parentNode.children;
  }
}
