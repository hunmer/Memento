/// Nodes 插件 - UseCase 业务逻辑层

import 'package:uuid/uuid.dart';
import 'package:shared_models/repositories/nodes/nodes_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:shared_models/utils/validation.dart';

/// Nodes 插件 UseCase - 封装所有业务逻辑
class NodesUseCase {
  final INodesRepository repository;
  final Uuid _uuid = const Uuid();

  NodesUseCase(this.repository);

  // ============ 笔记本 CRUD 操作 ============

  /// 获取笔记本列表
  Future<Result<dynamic>> getNotebooks(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getNotebooks(pagination: pagination);

      return result.map((notebooks) {
        final jsonList = notebooks.map((n) => n.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: pagination.offset,
            count: pagination.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取笔记本列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取笔记本
  Future<Result<Map<String, dynamic>?>> getNotebookById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getNotebookById(id);
      return result.map((notebook) => notebook?.toJson());
    } catch (e) {
      return Result.failure('获取笔记本失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建笔记本
  Future<Result<Map<String, dynamic>>> createNotebook(
    Map<String, dynamic> params,
  ) async {
    // 参数验证
    final titleValidation = ParamValidator.requireString(params, 'title');
    if (!titleValidation.isValid) {
      return Result.failure(
        titleValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final notebook = NotebookDto(
        id: params['id'] as String? ?? _uuid.v4(),
        title: params['title'] as String,
        icon: params['icon'] as int? ?? 57415,
        color: params['color'] as int? ?? 4280391411,
        nodes: (params['nodes'] as List<dynamic>?)
                ?.map((e) => NodeDto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

      final result = await repository.createNotebook(notebook);
      return result.map((n) => n.toJson());
    } catch (e) {
      return Result.failure('创建笔记本失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新笔记本
  Future<Result<Map<String, dynamic>>> updateNotebook(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有数据
      final existingResult = await repository.getNotebookById(id);
      if (existingResult.isFailure) {
        return Result.failure('笔记本不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('笔记本不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        title: params['title'] as String? ?? existing.title,
        icon: params['icon'] as int? ?? existing.icon,
        color: params['color'] as int? ?? existing.color,
        nodes: params.containsKey('nodes')
            ? (params['nodes'] as List<dynamic>?)
                    ?.map((e) => NodeDto.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                existing.nodes
            : existing.nodes,
      );

      final result = await repository.updateNotebook(id, updated);
      return result.map((n) => n.toJson());
    } catch (e) {
      return Result.failure('更新笔记本失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除笔记本
  Future<Result<bool>> deleteNotebook(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteNotebook(id);
    } catch (e) {
      return Result.failure('删除笔记本失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索笔记本
  Future<Result<dynamic>> searchNotebooks(Map<String, dynamic> params) async {
    try {
      final query = NotebookQuery(
        titleKeyword: params['titleKeyword'] as String?,
        pagination: _extractPagination(params),
      );

      final result = await repository.searchNotebooks(query);
      return result.map((notebooks) {
        final jsonList = notebooks.map((n) => n.toJson()).toList();

        if (query.pagination != null && query.pagination!.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: query.pagination!.offset,
            count: query.pagination!.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('搜索笔记本失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 节点 CRUD 操作 ============

  /// 获取指定笔记本的节点列表
  Future<Result<dynamic>> getNodes(Map<String, dynamic> params) async {
    final notebookId = params['notebookId'] as String?;
    if (notebookId == null || notebookId.isEmpty) {
      return Result.failure(
        '缺少必需参数: notebookId',
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final pagination = _extractPagination(params);
      final result = await repository.getNodes(notebookId, pagination: pagination);

      return result.map((nodes) {
        final jsonList = nodes.map((n) => n.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: pagination.offset,
            count: pagination.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取节点列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取节点
  Future<Result<Map<String, dynamic>?>> getNodeById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getNodeById(id);
      return result.map((node) => node?.toJson());
    } catch (e) {
      return Result.failure('获取节点失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建节点
  Future<Result<Map<String, dynamic>>> createNode(
    Map<String, dynamic> params,
  ) async {
    // 参数验证
    final titleValidation = ParamValidator.requireString(params, 'title');
    if (!titleValidation.isValid) {
      return Result.failure(
        titleValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final now = DateTime.now();
      final node = NodeDto(
        id: params['id'] as String? ?? _uuid.v4(),
        title: params['title'] as String,
        createdAt: now,
        tags: (params['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        status: params['status'] != null
            ? NodeStatus.values[params['status'] as int]
            : NodeStatus.todo,
        startDate: params['startDate'] != null
            ? DateTime.parse(params['startDate'] as String)
            : null,
        endDate: params['endDate'] != null
            ? DateTime.parse(params['endDate'] as String)
            : null,
        customFields: (params['customFields'] as List<dynamic>?)
                ?.map((e) => CustomFieldDto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        notes: params['notes'] as String? ?? '',
        parentId: params['parentId'] as String? ?? '',
        children: (params['children'] as List<dynamic>?)
                ?.map((e) => NodeDto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        isExpanded: params['isExpanded'] as bool? ?? true,
        pathValue: params['pathValue'] as String? ?? '',
        color: params['color'] as int? ?? 4280391411,
      );

      final result = await repository.createNode(node);
      return result.map((n) => n.toJson());
    } catch (e) {
      return Result.failure('创建节点失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新节点
  Future<Result<Map<String, dynamic>>> updateNode(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有数据
      final existingResult = await repository.getNodeById(id);
      if (existingResult.isFailure) {
        return Result.failure('节点不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('节点不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        title: params['title'] as String? ?? existing.title,
        tags: params.containsKey('tags')
            ? (params['tags'] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList() ??
                existing.tags
            : existing.tags,
        status: params['status'] != null
            ? NodeStatus.values[params['status'] as int]
            : existing.status,
        startDate: params['startDate'] != null
            ? DateTime.parse(params['startDate'] as String)
            : existing.startDate,
        endDate: params['endDate'] != null
            ? DateTime.parse(params['endDate'] as String)
            : existing.endDate,
        customFields: params.containsKey('customFields')
            ? (params['customFields'] as List<dynamic>?)
                    ?.map((e) => CustomFieldDto.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                existing.customFields
            : existing.customFields,
        notes: params['notes'] as String? ?? existing.notes,
        children: params.containsKey('children')
            ? (params['children'] as List<dynamic>?)
                    ?.map((e) => NodeDto.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                existing.children
            : existing.children,
        isExpanded: params['isExpanded'] as bool? ?? existing.isExpanded,
        pathValue: params['pathValue'] as String? ?? existing.pathValue,
        color: params['color'] as int? ?? existing.color,
      );

      final result = await repository.updateNode(id, updated);
      return result.map((n) => n.toJson());
    } catch (e) {
      return Result.failure('更新节点失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除节点
  Future<Result<bool>> deleteNode(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteNode(id);
    } catch (e) {
      return Result.failure('删除节点失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索节点
  Future<Result<dynamic>> searchNodes(Map<String, dynamic> params) async {
    final notebookId = params['notebookId'] as String?;
    if (notebookId == null || notebookId.isEmpty) {
      return Result.failure(
        '缺少必需参数: notebookId',
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final query = NodeQuery(
        notebookId: notebookId,
        titleKeyword: params['titleKeyword'] as String?,
        status: params['status'] != null
            ? NodeStatus.values[params['status'] as int]
            : null,
        tag: params['tag'] as String?,
        pagination: _extractPagination(params),
      );

      final result = await repository.searchNodes(query);
      return result.map((nodes) {
        final jsonList = nodes.map((n) => n.toJson()).toList();

        if (query.pagination != null && query.pagination!.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: query.pagination!.offset,
            count: query.pagination!.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('搜索节点失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 树形结构操作 ============

  /// 切换节点展开/折叠状态
  Future<Result<Map<String, dynamic>>> toggleNodeExpansion(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    final isExpanded = params['isExpanded'] as bool?;
    if (isExpanded == null) {
      return Result.failure('缺少必需参数: isExpanded', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.toggleNodeExpansion(id, isExpanded);
      return result.map((n) => n.toJson());
    } catch (e) {
      return Result.failure('切换节点展开状态失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取节点路径
  Future<Result<List<String>>> getNodePath(
    Map<String, dynamic> params,
  ) async {
    final notebookId = params['notebookId'] as String?;
    if (notebookId == null || notebookId.isEmpty) {
      return Result.failure(
        '缺少必需参数: notebookId',
        code: ErrorCodes.invalidParams,
      );
    }

    final nodeId = params['nodeId'] as String?;
    if (nodeId == null || nodeId.isEmpty) {
      return Result.failure('缺少必需参数: nodeId', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.getNodePath(notebookId, nodeId);
    } catch (e) {
      return Result.failure('获取节点路径失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取同级节点
  Future<Result<dynamic>> getSiblingNodes(
    Map<String, dynamic> params,
  ) async {
    final notebookId = params['notebookId'] as String?;
    if (notebookId == null || notebookId.isEmpty) {
      return Result.failure(
        '缺少必需参数: notebookId',
        code: ErrorCodes.invalidParams,
      );
    }

    final nodeId = params['nodeId'] as String?;
    if (nodeId == null || nodeId.isEmpty) {
      return Result.failure('缺少必需参数: nodeId', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getSiblingNodes(notebookId, nodeId);
      return result.map((nodes) => nodes.map((n) => n.toJson()).toList());
    } catch (e) {
      return Result.failure('获取同级节点失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 辅助方法 ============

  PaginationParams? _extractPagination(Map<String, dynamic> params) {
    final offset = params['offset'] as int?;
    final count = params['count'] as int?;

    if (offset == null && count == null) return null;

    return PaginationParams(
      offset: offset ?? 0,
      count: count ?? 100,
    );
  }
}
