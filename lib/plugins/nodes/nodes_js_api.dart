part of 'nodes_plugin.dart';

// ==================== JS API 定义 ====================

Map<String, Function> _defineJSAPIImpl() {
  return {
    // 笔记本相关
    'getNotebooks': _jsGetNotebooks,
    'getNotebook': _jsGetNotebook,
    'createNotebook': _jsCreateNotebook,
    'updateNotebook': _jsUpdateNotebook,
    'deleteNotebook': _jsDeleteNotebook,

    // 节点相关
    'getNodes': _jsGetNodes,
    'getNode': _jsGetNode,
    'createNode': _jsCreateNode,
    'updateNode': _jsUpdateNode,
    'deleteNode': _jsDeleteNode,
    'moveNode': _jsMoveNode,

    // 树结构相关
    'getNodeTree': _jsGetNodeTree,
    'getNodePath': _jsGetNodePath,

    // 查找方法
    'findNotebookBy': _jsFindNotebookBy,
    'findNotebookById': _jsFindNotebookById,
    'findNotebookByTitle': _jsFindNotebookByTitle,
    'findNodeBy': _jsFindNodeBy,
    'findNodeById': _jsFindNodeById,
    'findNodeByTitle': _jsFindNodeByTitle,
  };
}

// ==================== JS API 实现 ====================

/// 获取所有笔记本列表
Future<String> _jsGetNotebooks(Map<String, dynamic> params) async {
  final result = await NodesPlugin.instance.useCase.getNotebooks(params);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message ?? '未知错误'});
  }

  final data = result.dataOrNull ?? [];

  // 如果是分页结果,需要添加 nodeCount 字段
  if (data is Map && data.containsKey('items')) {
    final items = data['items'] as List;
    final enrichedItems =
        items.map((item) {
          final notebookJson = Map<String, dynamic>.from(item);
          notebookJson['nodeCount'] = _countAllNodesFromJson(
            notebookJson['nodes'] ?? [],
          );
          return notebookJson;
        }).toList();

    return jsonEncode({...data, 'items': enrichedItems});
  }

  // 如果是普通列表
  final enrichedList =
      (data as List).map((item) {
        final notebookJson = Map<String, dynamic>.from(item);
        notebookJson['nodeCount'] = _countAllNodesFromJson(
          notebookJson['nodes'] ?? [],
        );
        return notebookJson;
      }).toList();

  return jsonEncode(enrichedList);
}

/// 获取指定笔记本详情
Future<String> _jsGetNotebook(Map<String, dynamic> params) async {
  // 必需参数验证
  final String? notebookId = params['notebookId'];
  if (notebookId == null || notebookId.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: notebookId'});
  }

  final result = await NodesPlugin.instance.useCase.getNotebookById({'id': notebookId});

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message ?? '未知错误'});
  }

  final notebook = result.dataOrNull;
  if (notebook == null) {
    return jsonEncode({'error': '笔记本不存在'});
  }

  return jsonEncode({
    'id': notebook['id'],
    'title': notebook['title'],
    'icon': notebook['icon'],
    'color': notebook['color'],
    'nodeCount': _countAllNodesFromJson(notebook['nodes'] ?? []),
    'nodes': notebook['nodes'] ?? [],
  });
}

/// 创建笔记本
Future<String> _jsCreateNotebook(Map<String, dynamic> params) async {
  // 必需参数验证
  final String? title = params['title'];
  if (title == null || title.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: title'});
  }

  // 可选参数
  final String? id = params['id'];
  final int? iconCodePoint = params['iconCodePoint'];
  final int? colorValue = params['colorValue'];

  final result = await NodesPlugin.instance.useCase.createNotebook({
    'title': title,
    'id': id,
    'icon': iconCodePoint,
    'color': colorValue,
  });

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message ?? '未知错误'});
  }

  final notebook = result.dataOrNull ?? {};
  return jsonEncode({
    'id': notebook['id'],
    'title': notebook['title'],
    'icon': notebook['icon'],
    'color': notebook['color'],
  });
}

/// 更新笔记本
Future<String> _jsUpdateNotebook(Map<String, dynamic> params) async {
  // 必需参数验证
  final String? notebookId = params['notebookId'];
  if (notebookId == null || notebookId.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: notebookId'});
  }

  // 可选参数(从 updates 子对象获取)
  final Map<String, dynamic>? updates = params['updates'];
  if (updates == null) {
    return jsonEncode({'error': '缺少必需参数: updates'});
  }

  final result = await NodesPlugin.instance.useCase.updateNotebook({
    'id': notebookId,
    ...updates,
  });

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message ?? '未知错误'});
  }

  return jsonEncode({'success': true});
}

/// 删除笔记本
Future<String> _jsDeleteNotebook(Map<String, dynamic> params) async {
  // 必需参数验证
  final String? notebookId = params['notebookId'];
  if (notebookId == null || notebookId.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: notebookId'});
  }

  final result = await NodesPlugin.instance.useCase.deleteNotebook({'id': notebookId});

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message ?? '未知错误'});
  }

  return jsonEncode({'success': true});
}

/// 获取节点列表(可选父节点ID)
Future<String> _jsGetNodes(Map<String, dynamic> params) async {
  // 必需参数验证
  final String? notebookId = params['notebookId'];
  if (notebookId == null || notebookId.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: notebookId'});
  }

  // 可选参数
  final String? parentId = params['parentId'];

  final result = await NodesPlugin.instance.useCase.getNodes({'notebookId': notebookId});

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message ?? '未知错误'});
  }

  final data = result.dataOrNull ?? [];

  // 如果是分页结果
  if (data is Map && data.containsKey('items')) {
    var items = data['items'] as List;

    // 如果指定了 parentId,需要过滤子节点
    if (parentId != null && parentId.isNotEmpty) {
      items = items.where((node) => node['parentId'] == parentId).toList();
    }

    return jsonEncode({...data, 'items': items});
  }

  // 如果是普通列表
  var nodes = data as List;

  // 如果指定了 parentId,需要过滤子节点
  if (parentId != null && parentId.isNotEmpty) {
    nodes = nodes.where((node) => node['parentId'] == parentId).toList();
  }

  return jsonEncode({
    'success': true,
    'data': nodes,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });
}

/// 获取节点详情
Future<String> _jsGetNode(Map<String, dynamic> params) async {
  // 必需参数验证
  final String? nodeId = params['nodeId'];

  if (nodeId == null || nodeId.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: nodeId'});
  }

  final result = await NodesPlugin.instance.useCase.getNodeById({'id': nodeId});

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message ?? '未知错误'});
  }

  final node = result.dataOrNull;
  if (node == null) {
    return jsonEncode({'error': '节点不存在'});
  }

  return jsonEncode(node);
}

/// 创建节点
Future<String> _jsCreateNode(Map<String, dynamic> params) async {
  // 必需参数验证
  final String? notebookId = params['notebookId'];
  if (notebookId == null || notebookId.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: notebookId'});
  }

  // nodeData 是必需参数
  final Map<String, dynamic>? nodeData = params['nodeData'];
  if (nodeData == null) {
    return jsonEncode({'error': '缺少必需参数: nodeData'});
  }

  // 转换 nodeData 格式以适配 UseCase
  final useCaseParams = Map<String, dynamic>.from(nodeData);
  useCaseParams['notebookId'] = notebookId;

  final result = await NodesPlugin.instance.useCase.createNode(useCaseParams);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message ?? '未知错误'});
  }

  final node = result.dataOrNull ?? {};
  return jsonEncode({
    'id': node['id'],
    'title': node['title'],
    'status': node['status'],
  });
}

/// 更新节点
Future<String> _jsUpdateNode(Map<String, dynamic> params) async {
  // 必需参数验证
  final String? nodeId = params['nodeId'];

  if (nodeId == null || nodeId.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: nodeId'});
  }

  // 可选参数(从 updates 子对象获取)
  final Map<String, dynamic>? updates = params['updates'];
  if (updates == null) {
    return jsonEncode({'error': '缺少必需参数: updates'});
  }

  final result = await NodesPlugin.instance.useCase.updateNode({'id': nodeId, ...updates});

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message ?? '未知错误'});
  }

  return jsonEncode({'success': true});
}

/// 删除节点
Future<String> _jsDeleteNode(Map<String, dynamic> params) async {
  // 必需参数验证
  final String? nodeId = params['nodeId'];

  if (nodeId == null || nodeId.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: nodeId'});
  }

  final result = await NodesPlugin.instance.useCase.deleteNode({'id': nodeId});

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message ?? '未知错误'});
  }

  return jsonEncode({'success': true});
}

/// 移动节点到新的父节点下
Future<String> _jsMoveNode(Map<String, dynamic> params) async {
  // 必需参数验证
  final String? nodeId = params['nodeId'];
  final String? newParentId = params['newParentId'];

  if (nodeId == null || nodeId.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: nodeId'});
  }
  if (newParentId == null) {
    return jsonEncode({'error': '缺少必需参数: newParentId'});
  }

  // 获取节点详情
  final getResult = await NodesPlugin.instance.useCase.getNodeById({'id': nodeId});
  if (getResult.isFailure) {
    return jsonEncode({'error': getResult.errorOrNull?.message ?? '未知错误'});
  }

  final node = getResult.dataOrNull;
  if (node == null) {
    return jsonEncode({'error': '节点不存在'});
  }

  // 更新节点的 parentId
  final updateResult = await NodesPlugin.instance.useCase.updateNode({
    'id': nodeId,
    'parentId': newParentId,
  });

  if (updateResult.isFailure) {
    return jsonEncode({'error': updateResult.errorOrNull?.message ?? '未知错误'});
  }

  return jsonEncode({'success': true});
}

/// 获取完整节点树
Future<String> _jsGetNodeTree(Map<String, dynamic> params) async {
  // 必需参数验证
  final String? notebookId = params['notebookId'];
  if (notebookId == null || notebookId.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: notebookId'});
  }

  final notebookResult = await NodesPlugin.instance.useCase.getNotebookById({'id': notebookId});
  if (notebookResult.isFailure) {
    return jsonEncode({
      'error': notebookResult.errorOrNull?.message ?? '未知错误',
    });
  }

  final notebook = notebookResult.dataOrNull;
  if (notebook == null) {
    return jsonEncode({'error': '笔记本不存在'});
  }

  return jsonEncode({
    'notebookId': notebook['id'],
    'notebookTitle': notebook['title'],
    'tree': notebook['nodes'] ?? [],
  });
}

/// 获取节点路径
Future<String> _jsGetNodePath(Map<String, dynamic> params) async {
  // 必需参数验证
  final String? notebookId = params['notebookId'];
  final String? nodeId = params['nodeId'];

  if (notebookId == null || notebookId.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: notebookId'});
  }
  if (nodeId == null || nodeId.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: nodeId'});
  }

  final result = await NodesPlugin.instance.useCase.getNodePath({
    'notebookId': notebookId,
    'nodeId': nodeId,
  });

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message ?? '未知错误'});
  }

  final pathTitles = result.dataOrNull ?? [];
  final pathIds = <String>[]; // UseCase 中只返回标题,ID 需要额外获取

  return jsonEncode({
    'titles': pathTitles,
    'ids': pathIds,
    'fullPath': pathTitles.join(' / '),
  });
}

// ==================== 查找方法 ====================

/// 通用笔记本查找
Future<String> _jsFindNotebookBy(Map<String, dynamic> params) async {
  final String? field = params['field'];
  if (field == null || field.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: field'});
  }

  final dynamic value = params['value'];
  if (value == null) {
    return jsonEncode({'error': '缺少必需参数: value'});
  }

  final bool findAll = params['findAll'] ?? false;

  // 使用搜索功能
  if (field.toLowerCase() == 'title') {
    final result = await NodesPlugin.instance.useCase.searchNotebooks({
      'titleKeyword': value.toString(),
    });

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message ?? '未知错误'});
    }

    final notebooks = result.dataOrNull ?? [];

    // 如果不是查找所有,只返回第一个
    if (!findAll && notebooks is List && notebooks.isNotEmpty) {
      final notebook = notebooks.first;
      return jsonEncode({
        'id': notebook['id'],
        'title': notebook['title'],
        'icon': notebook['icon'],
        'color': notebook['color'],
        'nodeCount': _countAllNodesFromJson(notebook['nodes'] ?? []),
      });
    }

    // 返回所有匹配的笔记本
    if (notebooks is List) {
      final enrichedList =
          notebooks.map((nb) {
            final notebookJson = Map<String, dynamic>.from(nb);
            notebookJson['nodeCount'] = _countAllNodesFromJson(
              nb['nodes'] ?? [],
            );
            return notebookJson;
          }).toList();
      return jsonEncode(enrichedList);
    }
  }

  // 对于 ID 查找,直接获取笔记本
  if (field.toLowerCase() == 'id') {
    final result = await NodesPlugin.instance.useCase.getNotebookById({'id': value.toString()});

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message ?? '未知错误'});
    }

    final notebook = result.dataOrNull;
    if (notebook == null) {
      return jsonEncode(null);
    }

    return jsonEncode({
      'id': notebook['id'],
      'title': notebook['title'],
      'icon': notebook['icon'],
      'color': notebook['color'],
      'nodeCount': _countAllNodesFromJson(notebook['nodes'] ?? []),
    });
  }

  return jsonEncode(null);
}

/// 根据ID查找笔记本
Future<String> _jsFindNotebookById(Map<String, dynamic> params) async {
  final String? id = params['id'];
  if (id == null || id.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: id'});
  }

  final result = await NodesPlugin.instance.useCase.getNotebookById({'id': id});

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message ?? '未知错误'});
  }

  final notebook = result.dataOrNull;
  if (notebook == null) {
    return jsonEncode(null);
  }

  return jsonEncode({
    'id': notebook['id'],
    'title': notebook['title'],
    'icon': notebook['icon'],
    'color': notebook['color'],
    'nodeCount': _countAllNodesFromJson(notebook['nodes'] ?? []),
  });
}

/// 根据标题查找笔记本
Future<String> _jsFindNotebookByTitle(Map<String, dynamic> params) async {
  final String? title = params['title'];
  if (title == null || title.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: title'});
  }

  final bool findAll = params['findAll'] ?? false;

  final result = await NodesPlugin.instance.useCase.searchNotebooks({'titleKeyword': title});

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message ?? '未知错误'});
  }

  final notebooks = result.dataOrNull ?? [];

  if (!findAll && notebooks is List && notebooks.isNotEmpty) {
    final notebook = notebooks.first;
    return jsonEncode({
      'id': notebook['id'],
      'title': notebook['title'],
      'icon': notebook['icon'],
      'color': notebook['color'],
      'nodeCount': _countAllNodesFromJson(notebook['nodes'] ?? []),
    });
  }

  if (notebooks is List) {
    final enrichedList =
        notebooks.map((nb) {
          final notebookJson = Map<String, dynamic>.from(nb);
          notebookJson['nodeCount'] = _countAllNodesFromJson(
            nb['nodes'] ?? [],
          );
          return notebookJson;
        }).toList();
    return jsonEncode(enrichedList);
  }

  return jsonEncode(null);
}

/// 通用节点查找
Future<String> _jsFindNodeBy(Map<String, dynamic> params) async {
  final String? notebookId = params['notebookId'];
  if (notebookId == null || notebookId.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: notebookId'});
  }

  final String? field = params['field'];
  if (field == null || field.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: field'});
  }

  final dynamic value = params['value'];
  if (value == null) {
    return jsonEncode({'error': '缺少必需参数: value'});
  }

  final bool findAll = params['findAll'] ?? false;

  // 使用搜索功能
  if (field.toLowerCase() == 'title' || field.toLowerCase() == 'status') {
    final searchParams = <String, dynamic>{'notebookId': notebookId};

    if (field.toLowerCase() == 'title') {
      searchParams['titleKeyword'] = value.toString();
    } else if (field.toLowerCase() == 'status') {
      // 转换状态字符串为索引
      final statusMap = {'todo': 0, 'doing': 1, 'done': 2, 'none': 3};
      searchParams['status'] = statusMap[value.toString().toLowerCase()] ?? 0;
    }

    final result = await NodesPlugin.instance.useCase.searchNodes(searchParams);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message ?? '未知错误'});
    }

    final nodes = result.dataOrNull ?? [];

    if (!findAll && nodes is List && nodes.isNotEmpty) {
      return jsonEncode(nodes.first);
    }

    return jsonEncode(nodes);
  }

  // 对于 ID 查找,直接获取节点
  if (field.toLowerCase() == 'id') {
    final result = await NodesPlugin.instance.useCase.getNodeById({'id': value.toString()});

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message ?? '未知错误'});
    }

    final node = result.dataOrNull;
    if (node == null) {
      return jsonEncode(null);
    }

    return jsonEncode(node);
  }

  return jsonEncode(null);
}

/// 根据ID查找节点
Future<String> _jsFindNodeById(Map<String, dynamic> params) async {
  final String? nodeId = params['nodeId'];
  if (nodeId == null || nodeId.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: nodeId'});
  }

  final result = await NodesPlugin.instance.useCase.getNodeById({'id': nodeId});

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message ?? '未知错误'});
  }

  final node = result.dataOrNull;
  if (node == null) {
    return jsonEncode(null);
  }

  return jsonEncode(node);
}

/// 根据标题查找节点
Future<String> _jsFindNodeByTitle(Map<String, dynamic> params) async {
  final String? notebookId = params['notebookId'];
  if (notebookId == null || notebookId.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: notebookId'});
  }

  final String? title = params['title'];
  if (title == null || title.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: title'});
  }

  final bool findAll = params['findAll'] ?? false;

  final result = await NodesPlugin.instance.useCase.searchNodes({
    'notebookId': notebookId,
    'titleKeyword': title,
  });

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message ?? '未知错误'});
  }

  final nodes = result.dataOrNull ?? [];

  if (!findAll && nodes is List && nodes.isNotEmpty) {
    return jsonEncode(nodes.first);
  }

  return jsonEncode(nodes);
}

// ==================== 辅助方法 ====================

/// 将节点转换为 JSON(可选包含子节点)
// ignore: unused_element
Map<String, dynamic> _nodeToJson(Node node, {bool includeChildren = false}) {
  final json = {
    'id': node.id,
    'title': node.title,
    'createdAt': node.createdAt.toIso8601String(),
    'tags': node.tags,
    'status': node.status.toString().split('.').last,
    'startDate': node.startDate?.toIso8601String(),
    'endDate': node.endDate?.toIso8601String(),
    'customFields':
        node.customFields
            .map((f) => {'key': f.key, 'value': f.value})
            .toList(),
    'notes': node.notes,
    'parentId': node.parentId,
    'color': node.color.value,
    'pathValue': node.pathValue,
    'childrenCount': node.children.length,
  };

  if (includeChildren && node.children.isNotEmpty) {
    json['children'] =
        node.children
            .map((c) => _nodeToJson(c, includeChildren: true))
            .toList();
  }

  return json;
}

/// 解析节点状态
// ignore: unused_element
NodeStatus _parseNodeStatus(dynamic status) {
  if (status is String) {
    switch (status.toLowerCase()) {
      case 'todo':
        return NodeStatus.todo;
      case 'doing':
        return NodeStatus.doing;
      case 'done':
        return NodeStatus.done;
      default:
        return NodeStatus.none;
    }
  } else if (status is int &&
      status >= 0 &&
      status < NodeStatus.values.length) {
    return NodeStatus.values[status];
  }
  return NodeStatus.none;
}

/// 分页辅助方法
///
/// 根据 offset 和 count 参数对列表进行分页
/// - 如果 offset 和 count 都为 null,返回原格式(列表)
/// - 如果提供了分页参数,返回包含 items、total、offset、count 的对象
// ignore: unused_element
dynamic _paginate(List<dynamic> items, Map<String, dynamic> params) {
  final int? offset = params['offset'];
  final int? count = params['count'];

  // 无分页参数:返回原格式(列表)
  if (offset == null && count == null) {
    return items;
  }

  // 有分页参数:返回分页对象
  final int actualOffset = offset ?? 0;
  final int actualCount = count ?? items.length;
  final List<dynamic> paginatedItems =
      items.skip(actualOffset).take(actualCount).toList();

  return {
    'items': paginatedItems,
    'total': items.length,
    'offset': actualOffset,
    'count': paginatedItems.length,
  };
}

// 从 JSON 中计算节点总数
int _countAllNodesFromJson(List<dynamic> nodesJson) {
  int count = nodesJson.length;
  for (var nodeJson in nodesJson) {
    final children = nodeJson['children'] as List?;
    if (children != null && children.isNotEmpty) {
      count += _countAllNodesFromJson(children);
    }
  }
  return count;
}
