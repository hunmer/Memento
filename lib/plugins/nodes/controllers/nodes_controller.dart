import 'package:flutter/material.dart';
import 'dart:convert';
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
    final index = _notebooks.indexWhere((notebook) => notebook.id == notebookId);
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
      final notebooksData = await _storageManager.read('nodes_notebooks');
      if (notebooksData.isNotEmpty) {
        final List<dynamic> notebooks = notebooksData['notebooks'] as List<dynamic>;
        _notebooks = notebooks.map((data) => Notebook.fromJson(data as Map<String, dynamic>)).toList();
        
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
        'notebooks': _notebooks.map((notebook) => notebook.toJson()).toList()
      };
      await _storageManager.write('nodes_notebooks', data);
    } catch (e) {
      debugPrint('Error saving notebooks: $e');
    }
  }

  Future<void> addNotebook(String title, IconData icon, {Color color = Colors.blue}) async {
    final newNotebook = Notebook(
      id: const Uuid().v4(),
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
    if (oldIndex < 0 || newIndex < 0 || oldIndex >= _notebooks.length || newIndex >= _notebooks.length) {
      return;
    }
    
    final Notebook item = _notebooks.removeAt(oldIndex);
    _notebooks.insert(newIndex, item);
    
    notifyListeners();
    await _saveData();
  }

  // Node operations
  Future<void> addNode(String notebookId, Node node, {String? parentId}) async {
    final notebookIndex = _notebooks.indexWhere((notebook) => notebook.id == notebookId);
    if (notebookIndex == -1) return;

    if (parentId == null || parentId.isEmpty) {
      // Add as root node
      _notebooks[notebookIndex].nodes.add(node);
    } else {
      // Add as child node
      _addChildNode(_notebooks[notebookIndex].nodes, parentId, node);
    }

    notifyListeners();
    await _saveData();
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
    final notebookIndex = _notebooks.indexWhere((notebook) => notebook.id == notebookId);
    if (notebookIndex == -1) return;

    _updateNodeInList(_notebooks[notebookIndex].nodes, updatedNode);
    
    notifyListeners();
    await _saveData();
  }

  bool _updateNodeInList(List<Node> nodes, Node updatedNode) {
    for (int i = 0; i < nodes.length; i++) {
      if (nodes[i].id == updatedNode.id) {
        // Preserve children and expanded state
        updatedNode.children = nodes[i].children;
        updatedNode.isExpanded = nodes[i].isExpanded;
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
    final notebookIndex = _notebooks.indexWhere((notebook) => notebook.id == notebookId);
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
    final notebookIndex = _notebooks.indexWhere((notebook) => notebook.id == notebookId);
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
    final notebookIndex = _notebooks.indexWhere((notebook) => notebook.id == notebookId);
    if (notebookIndex == -1) return [];

    List<String> path = [];
    _findNodePath(_notebooks[notebookIndex].nodes, nodeId, path);
    return path.reversed.toList();
  }

  List<String> getNodePathIds(String notebookId, String nodeId) {
    final notebookIndex = _notebooks.indexWhere((notebook) => notebook.id == notebookId);
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
    final notebookIndex = _notebooks.indexWhere((notebook) => notebook.id == notebookId);
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
}