/// Nodes 插件 - Repository 接口定义
library;

import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';

// ============ DTOs ============

/// 自定义字段 DTO
class CustomFieldDto {
  final String key;
  final String value;

  const CustomFieldDto({
    required this.key,
    required this.value,
  });

  /// 从 JSON 构造
  factory CustomFieldDto.fromJson(Map<String, dynamic> json) {
    return CustomFieldDto(
      key: json['key'] as String,
      value: json['value'] as String,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
    };
  }

  /// 复制并修改
  CustomFieldDto copyWith({
    String? key,
    String? value,
  }) {
    return CustomFieldDto(
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }
}

/// 节点状态枚举
enum NodeStatus { todo, doing, done, none }

/// 节点 DTO
class NodeDto {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<String> tags;
  final NodeStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<CustomFieldDto> customFields;
  final String notes;
  final String parentId;
  final List<NodeDto> children;
  final bool isExpanded;
  final String pathValue;
  final int color;

  const NodeDto({
    required this.id,
    required this.title,
    required this.createdAt,
    this.tags = const [],
    this.status = NodeStatus.todo,
    this.startDate,
    this.endDate,
    this.customFields = const [],
    this.notes = '',
    this.parentId = '',
    this.children = const [],
    this.isExpanded = true,
    this.pathValue = '',
    this.color = 4280391411, // Colors.grey.value
  });

  /// 从 JSON 构造
  factory NodeDto.fromJson(Map<String, dynamic> json) {
    final tagsList =
        (json['tags'] as List<dynamic>).map((e) => e as String).toList();
    final customFieldsList = (json['customFields'] as List<dynamic>?)
            ?.map((e) => CustomFieldDto.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    final childrenList = (json['children'] as List<dynamic>?)
            ?.map((e) => NodeDto.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return NodeDto(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      tags: tagsList,
      status: NodeStatus.values[json['status'] as int],
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      customFields: customFieldsList,
      notes: json['notes'] as String,
      parentId: json['parentId'] as String? ?? '',
      children: childrenList,
      isExpanded: json['isExpanded'] as bool? ?? true,
      pathValue: json['pathValue'] as String? ?? '',
      color: json['color'] as int? ?? 4280391411,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
      'status': status.index,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'customFields': customFields.map((e) => e.toJson()).toList(),
      'notes': notes,
      'parentId': parentId,
      'children': children.map((e) => e.toJson()).toList(),
      'isExpanded': isExpanded,
      'pathValue': pathValue,
      'color': color,
    };
  }

  /// 复制并修改
  NodeDto copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    List<String>? tags,
    NodeStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    List<CustomFieldDto>? customFields,
    String? notes,
    String? parentId,
    List<NodeDto>? children,
    bool? isExpanded,
    String? pathValue,
    int? color,
  }) {
    return NodeDto(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      customFields: customFields ?? this.customFields,
      notes: notes ?? this.notes,
      parentId: parentId ?? this.parentId,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
      pathValue: pathValue ?? this.pathValue,
      color: color ?? this.color,
    );
  }
}

/// 笔记本 DTO
class NotebookDto {
  final String id;
  final String title;
  final int icon;
  final int color;
  final List<NodeDto> nodes;

  const NotebookDto({
    required this.id,
    required this.title,
    this.icon = 57415, // Icons.book.codePoint
    this.color = 4280391411, // Colors.blue.value
    this.nodes = const [],
  });

  /// 从 JSON 构造
  factory NotebookDto.fromJson(Map<String, dynamic> json) {
    final nodesList = (json['nodes'] as List<dynamic>?)
            ?.map((e) => NodeDto.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return NotebookDto(
      id: json['id'] as String,
      title: json['title'] as String,
      icon: json['icon'] as int? ?? 57415,
      color: json['color'] as int? ?? 4280391411,
      nodes: nodesList,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'icon': icon,
      'color': color,
      'nodes': nodes.map((e) => e.toJson()).toList(),
    };
  }

  /// 复制并修改
  NotebookDto copyWith({
    String? id,
    String? title,
    int? icon,
    int? color,
    List<NodeDto>? nodes,
  }) {
    return NotebookDto(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      nodes: nodes ?? this.nodes,
    );
  }
}

// ============ Query Objects ============

/// 笔记本查询参数对象
class NotebookQuery {
  final String? titleKeyword;
  final PaginationParams? pagination;

  const NotebookQuery({
    this.titleKeyword,
    this.pagination,
  });
}

/// 节点查询参数对象
class NodeQuery {
  final String notebookId;
  final String? titleKeyword;
  final NodeStatus? status;
  final String? tag;
  final PaginationParams? pagination;

  const NodeQuery({
    required this.notebookId,
    this.titleKeyword,
    this.status,
    this.tag,
    this.pagination,
  });
}

// ============ Repository Interface ============

/// Nodes 插件 Repository 接口
abstract class INodesRepository {
  // ============ 笔记本 CRUD 操作 ============

  /// 获取所有笔记本
  Future<Result<List<NotebookDto>>> getNotebooks(
      {PaginationParams? pagination});

  /// 根据 ID 获取笔记本
  Future<Result<NotebookDto?>> getNotebookById(String id);

  /// 创建笔记本
  Future<Result<NotebookDto>> createNotebook(NotebookDto notebook);

  /// 更新笔记本
  Future<Result<NotebookDto>> updateNotebook(String id, NotebookDto notebook);

  /// 删除笔记本
  Future<Result<bool>> deleteNotebook(String id);

  /// 搜索笔记本
  Future<Result<List<NotebookDto>>> searchNotebooks(NotebookQuery query);

  // ============ 节点 CRUD 操作 ============

  /// 获取指定笔记本的所有节点
  Future<Result<List<NodeDto>>> getNodes(String notebookId,
      {PaginationParams? pagination});

  /// 根据 ID 获取节点
  Future<Result<NodeDto?>> getNodeById(String id);

  /// 创建节点
  Future<Result<NodeDto>> createNode(NodeDto node);

  /// 更新节点
  Future<Result<NodeDto>> updateNode(String id, NodeDto node);

  /// 删除节点
  Future<Result<bool>> deleteNode(String id);

  /// 搜索节点
  Future<Result<List<NodeDto>>> searchNodes(NodeQuery query);

  // ============ 树形结构操作 ============

  /// 切换节点展开/折叠状态
  Future<Result<NodeDto>> toggleNodeExpansion(String id, bool isExpanded);

  /// 获取节点的路径
  Future<Result<List<String>>> getNodePath(String notebookId, String nodeId);

  /// 获取节点的所有同级节点
  Future<Result<List<NodeDto>>> getSiblingNodes(
      String notebookId, String nodeId);
}
