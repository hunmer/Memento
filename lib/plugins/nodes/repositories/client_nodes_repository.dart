/// Nodes 插件 - 客户端 Repository 实现
///
/// 通过适配现有的 NodesController 来实现 INodesRepository 接口

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_models/repositories/nodes/nodes_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import '../controllers/nodes_controller.dart';
import '../models/node.dart' as local;
import '../models/notebook.dart';

/// 客户端 Nodes Repository 实现
class ClientNodesRepository extends INodesRepository {
  final NodesController controller;

  ClientNodesRepository({required this.controller});

  // ============ 笔记本 CRUD 操作 ============

  @override
  Future<Result<List<NotebookDto>>> getNotebooks({
    PaginationParams? pagination,
  }) async {
    try {
      final notebooks = controller.notebooks;
      final dtos = notebooks.map(_notebookToDto).toList();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('获取笔记本列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<NotebookDto?>> getNotebookById(String id) async {
    try {
      final notebook = controller.getNotebook(id);
      if (notebook == null || notebook.id.isEmpty) {
        return Result.success(null);
      }
      return Result.success(_notebookToDto(notebook));
    } catch (e) {
      return Result.failure('获取笔记本失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<NotebookDto>> createNotebook(NotebookDto dto) async {
    try {
      // 将 DTO 转换为 Notebook
      final icon = dto.icon != null
          ? IconData(dto.icon!, fontFamily: 'MaterialIcons')
          : Icons.book;
      final color = dto.color != null ? Color(dto.color!) : Colors.blue;

      await controller.addNotebook(
        dto.title,
        icon,
        id: dto.id,
        color: color,
      );

      // 返回创建后的 DTO
      final createdNotebook = controller.getNotebook(dto.id);
      if (createdNotebook == null) {
        return Result.failure('创建笔记本失败', code: ErrorCodes.serverError);
      }

      return Result.success(_notebookToDto(createdNotebook));
    } catch (e) {
      return Result.failure('创建笔记本失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<NotebookDto>> updateNotebook(String id, NotebookDto dto) async {
    try {
      // 获取现有笔记本
      final existingNotebook = controller.getNotebook(id);
      if (existingNotebook == null || existingNotebook.id.isEmpty) {
        return Result.failure('笔记本不存在', code: ErrorCodes.notFound);
      }

      // 将 DTO 转换为 Notebook
      final icon = dto.icon != null
          ? IconData(dto.icon!, fontFamily: 'MaterialIcons')
          : existingNotebook.icon;
      final color = dto.color != null ? Color(dto.color!) : existingNotebook.color;

      final updatedNotebook = Notebook(
        id: existingNotebook.id,
        title: dto.title,
        icon: icon,
        color: color,
        nodes: (dto.nodes.isNotEmpty)
            ? dto.nodes.map((nodeDto) => _dtoToNode(nodeDto)).toList()
            : existingNotebook.nodes,
      );

      await controller.updateNotebook(updatedNotebook);

      // 返回更新后的 DTO
      final resultNotebook = controller.getNotebook(id);
      if (resultNotebook == null) {
        return Result.failure('更新笔记本失败', code: ErrorCodes.serverError);
      }

      return Result.success(_notebookToDto(resultNotebook));
    } catch (e) {
      return Result.failure('更新笔记本失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteNotebook(String id) async {
    try {
      await controller.deleteNotebook(id);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除笔记本失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<NotebookDto>>> searchNotebooks(NotebookQuery query) async {
    try {
      final notebooks = controller.notebooks;
      final matches = <Notebook>[];

      for (final notebook in notebooks) {
        bool isMatch = true;

        if (query.titleKeyword != null && query.titleKeyword!.isNotEmpty) {
          final keyword = query.titleKeyword!.toLowerCase();
          isMatch = notebook.title.toLowerCase().contains(keyword);
        }

        if (isMatch) {
          matches.add(notebook);
        }
      }

      final dtos = matches.map(_notebookToDto).toList();

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('搜索笔记本失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 节点 CRUD 操作 ============

  @override
  Future<Result<List<NodeDto>>> getNodes(
    String notebookId, {
    PaginationParams? pagination,
  }) async {
    try {
      final notebook = controller.getNotebook(notebookId);
      if (notebook == null || notebook.id.isEmpty) {
        return Result.failure('笔记本不存在', code: ErrorCodes.notFound);
      }

      // 获取所有根节点（扁平列表）
      final allNodes = _getAllNodes(notebook.nodes);
      final dtos = allNodes.map(_nodeToDto).toList();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('获取节点列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<NodeDto?>> getNodeById(String id) async {
    try {
      // 在所有笔记本中查找节点
      for (final notebook in controller.notebooks) {
        final node = _findNodeById(notebook.nodes, id);
        if (node != null) {
          return Result.success(_nodeToDto(node));
        }
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure('获取节点失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<NodeDto>> createNode(NodeDto dto) async {
    try {
      // 找到所属笔记本
      var notebookId = _findNotebookIdByNodeDto(dto);

      if (notebookId.isEmpty && controller.notebooks.isNotEmpty) {
        // 如果没有找到所属笔记本，使用第一个笔记本
        notebookId = controller.notebooks.first.id;
      }

      if (notebookId.isEmpty) {
        return Result.failure('没有可用的笔记本', code: ErrorCodes.notFound);
      }

      // 将 DTO 转换为 Node
      final node = _dtoToNode(dto);
      final parentId = dto.parentId.isNotEmpty ? dto.parentId : null;

      await controller.addNode(notebookId, node, parentId: parentId);

      return Result.success(_nodeToDto(node));
    } catch (e) {
      return Result.failure('创建节点失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<NodeDto>> updateNode(String id, NodeDto dto) async {
    try {
      // 找到节点所在的笔记本
      String? notebookId;
      local.Node? existingNode;

      for (final notebook in controller.notebooks) {
        existingNode = _findNodeById(notebook.nodes, id);
        if (existingNode != null) {
          notebookId = notebook.id;
          break;
        }
      }

      if (existingNode == null || notebookId == null) {
        return Result.failure('节点不存在', code: ErrorCodes.notFound);
      }

      // 将 DTO 转换为 Node（保留现有属性）
      final updatedNode = _dtoToNode(dto);

      // 保留原节点的子节点和展开状态
      updatedNode.children = existingNode.children;
      updatedNode.isExpanded = existingNode.isExpanded;

      await controller.updateNode(notebookId, updatedNode);

      return Result.success(_nodeToDto(updatedNode));
    } catch (e) {
      return Result.failure('更新节点失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteNode(String id) async {
    try {
      // 找到节点所在的笔记本
      String? notebookId;

      for (final notebook in controller.notebooks) {
        final node = _findNodeById(notebook.nodes, id);
        if (node != null) {
          notebookId = notebook.id;
          break;
        }
      }

      if (notebookId == null) {
        return Result.failure('节点不存在', code: ErrorCodes.notFound);
      }

      await controller.deleteNode(notebookId, id);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除节点失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<NodeDto>>> searchNodes(NodeQuery query) async {
    try {
      final notebook = controller.getNotebook(query.notebookId);
      if (notebook == null || notebook.id.isEmpty) {
        return Result.failure('笔记本不存在', code: ErrorCodes.notFound);
      }

      final allNodes = _getAllNodes(notebook.nodes);
      final matches = <local.Node>[];

      for (final node in allNodes) {
        bool isMatch = true;

        // 标题关键词匹配
        if (query.titleKeyword != null && query.titleKeyword!.isNotEmpty) {
          final keyword = query.titleKeyword!.toLowerCase();
          isMatch = node.title.toLowerCase().contains(keyword);
        }

        // 状态匹配
        if (isMatch && query.status != null) {
          isMatch = _convertNodeStatus(node.status) == query.status;
        }

        // 标签匹配
        if (isMatch && query.tag != null && query.tag!.isNotEmpty) {
          isMatch = node.tags.contains(query.tag);
        }

        if (isMatch) {
          matches.add(node);
        }
      }

      final dtos = matches.map(_nodeToDto).toList();

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('搜索节点失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 树形结构操作 ============

  @override
  Future<Result<NodeDto>> toggleNodeExpansion(String id, bool isExpanded) async {
    try {
      // 找到节点所在的笔记本
      String? notebookId;
      local.Node? node;

      for (final notebook in controller.notebooks) {
        node = _findNodeById(notebook.nodes, id);
        if (node != null) {
          notebookId = notebook.id;
          break;
        }
      }

      if (node == null || notebookId == null) {
        return Result.failure('节点不存在', code: ErrorCodes.notFound);
      }

      await controller.toggleNodeExpansion(notebookId, id);

      // 返回更新后的节点
      final updatedNode = _findNodeById(
        controller.getNotebook(notebookId)!.nodes,
        id,
      )!;

      return Result.success(_nodeToDto(updatedNode));
    } catch (e) {
      return Result.failure('切换节点展开状态失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<String>>> getNodePath(String notebookId, String nodeId) async {
    try {
      final pathTitles = controller.getNodePath(notebookId, nodeId);
      return Result.success(pathTitles);
    } catch (e) {
      return Result.failure('获取节点路径失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<NodeDto>>> getSiblingNodes(String notebookId, String nodeId) async {
    try {
      final siblings = controller.getSiblingNodes(notebookId, nodeId);
      return Result.success(siblings.map(_nodeToDto).toList());
    } catch (e) {
      return Result.failure('获取同级节点失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 转换方法 ============

  NotebookDto _notebookToDto(Notebook notebook) {
    return NotebookDto(
      id: notebook.id,
      title: notebook.title,
      icon: notebook.icon.codePoint,
      color: notebook.color.value,
      nodes: notebook.nodes.map(_nodeToDto).toList(),
    );
  }

  NodeDto _nodeToDto(local.Node node) {
    return NodeDto(
      id: node.id,
      title: node.title,
      createdAt: node.createdAt,
      tags: node.tags,
      status: _convertNodeStatus(node.status),
      startDate: node.startDate,
      endDate: node.endDate,
      customFields: node.customFields
          .map((field) => CustomFieldDto(key: field.key, value: field.value))
          .toList(),
      notes: node.notes,
      parentId: node.parentId,
      children: node.children.map(_nodeToDto).toList(),
      isExpanded: node.isExpanded,
      pathValue: node.pathValue,
      color: node.color.value,
    );
  }

  local.Node _dtoToNode(NodeDto dto) {
    return local.Node(
      id: dto.id,
      title: dto.title,
      createdAt: dto.createdAt,
      tags: dto.tags,
      status: _convertNodeStatusFromDto(dto.status),
      startDate: dto.startDate,
      endDate: dto.endDate,
      customFields: dto.customFields
          .map((field) => local.CustomField(key: field.key, value: field.value))
          .toList(),
      notes: dto.notes,
      parentId: dto.parentId,
      color: Color(dto.color),
      pathValue: dto.pathValue,
    );
  }

  // ============ 类型转换辅助方法 ============

  /// 将本地 NodeStatus 转换为 DTO NodeStatus
  NodeStatus _convertNodeStatus(local.NodeStatus localStatus) {
    return NodeStatus.values[localStatus.index];
  }

  /// 将 DTO NodeStatus 转换为本地 NodeStatus
  local.NodeStatus _convertNodeStatusFromDto(NodeStatus dtoStatus) {
    return local.NodeStatus.values[dtoStatus.index];
  }

  // ============ 辅助方法 ============

  /// 递归获取所有节点（扁平列表）
  List<local.Node> _getAllNodes(List<local.Node> nodes) {
    final result = <local.Node>[];
    for (final node in nodes) {
      result.add(node);
      result.addAll(_getAllNodes(node.children));
    }
    return result;
  }

  /// 根据 ID 递归查找节点
  local.Node? _findNodeById(List<local.Node> nodes, String id) {
    for (final node in nodes) {
      if (node.id == id) {
        return node;
      }
      final found = _findNodeById(node.children, id);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  /// 根据节点找到所属笔记本 ID
  String _findNotebookIdByNodeDto(NodeDto node) {
    for (final notebook in controller.notebooks) {
      if (_containsNode(notebook.nodes, node.id)) {
        return notebook.id;
      }
    }
    return '';
  }

  /// 检查节点列表中是否包含指定 ID 的节点
  bool _containsNode(List<local.Node> nodes, String nodeId) {
    for (final node in nodes) {
      if (node.id == nodeId) {
        return true;
      }
      if (_containsNode(node.children, nodeId)) {
        return true;
      }
    }
    return false;
  }
}
