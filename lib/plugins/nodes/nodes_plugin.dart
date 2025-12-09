import 'package:get/get.dart';
import 'dart:convert';
import 'package:Memento/core/config_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/core/plugin_base.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'controllers/nodes_controller.dart';
import 'screens/notebooks_screen.dart';
import 'models/node.dart';
import 'models/notebook.dart';

class NodesMainView extends StatefulWidget {
  const NodesMainView({super.key});

  @override
  State<NodesMainView> createState() => _NodesMainViewState();
}

class _NodesMainViewState extends State<NodesMainView> {
  late NodesPlugin _plugin;

  @override
  void initState() {
    super.initState();
    _plugin = NodesPlugin.instance;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _plugin.controller,
      child: const NotebooksScreen(),
    );
  }
}

class NodesPlugin extends PluginBase with JSBridgePlugin {
  static NodesPlugin? _instance;
  static NodesPlugin get instance {
    if (_instance == null) {
      _instance = PluginManager.instance.getPlugin('nodes') as NodesPlugin?;
      if (_instance == null) {
        throw StateError('NodesPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  late NodesController _controller;
  bool _isInitialized = false;

  NodesPlugin();

  NodesController get controller => _controller;

  // ========== 小组件统计方法 ==========

  /// 获取笔记本总数
  int getNotebookCount() {
    return _controller.notebooks.length;
  }

  /// 获取所有节点总数（递归统计）
  int getTotalNodeCount() {
    int count = 0;
    for (var notebook in _controller.notebooks) {
      count += _countAllNodes(notebook.nodes);
    }
    return count;
  }

  /// 获取今日新增节点数
  int getTodayAddedNodeCount() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    int count = 0;
    for (var notebook in _controller.notebooks) {
      count += _countNodesCreatedAfter(notebook.nodes, todayStart);
    }
    return count;
  }

  /// 递归统计某个时间之后创建的节点数量
  int _countNodesCreatedAfter(List<Node> nodes, DateTime after) {
    int count = 0;
    for (var node in nodes) {
      if (node.createdAt.isAfter(after)) {
        count++;
      }
      count += _countNodesCreatedAfter(node.children, after);
    }
    return count;
  }

  @override
  String get id => 'nodes';

  @override
  Color get color => Colors.amber;

  @override
  Future<void> initialize() async {
    _controller = NodesController(storage);

    _isInitialized = true;

    // 注册 JS API（最后一步）
    await registerJSAPI();
  }

  @override
  String? getPluginName(context) {
    return 'nodes_name'.tr;
  }

  @override
  Future<void> registerToApp(
    
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 插件已在 initialize() 中完成初始化
    // 这里可以添加额外的应用级注册逻辑
  }

  @override
  Widget buildMainView(BuildContext context) {
    // 确保controller已经初始化
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NodesController>.value(value: _controller),
      ],
      child: const NodesMainView(),
    );
  }

  @override
  Widget buildSettingsView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('nodes_nodesSettings'.tr)),
      body: super.buildSettingsView(context),
    );
  }

  @override
  IconData get icon => Icons.account_tree;

  // ==================== JS API 定义 ====================

  @override
  Map<String, Function> defineJSAPI() {
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
    final notebooks = _controller.notebooks;
    final notebookList = notebooks.map((nb) => {
      'id': nb.id,
      'title': nb.title,
      'icon': nb.icon.codePoint,
      'color': nb.color.value,
      'nodeCount': _countAllNodes(nb.nodes),
    }).toList();

    // 应用分页
    final result = _paginate(notebookList, params);
    return jsonEncode(result);
  }

  /// 获取指定笔记本详情
  Future<String> _jsGetNotebook(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? notebookId = params['notebookId'];
    if (notebookId == null || notebookId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: notebookId'});
    }

    final notebook = _controller.getNotebook(notebookId);
    if (notebook == null || notebook.id.isEmpty) {
      return jsonEncode({'error': '笔记本不存在'});
    }

    return jsonEncode({
      'id': notebook.id,
      'title': notebook.title,
      'icon': notebook.icon.codePoint,
      'color': notebook.color.value,
      'nodeCount': _countAllNodes(notebook.nodes),
      'nodes': notebook.nodes.map((n) => _nodeToJson(n)).toList(),
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

    final icon = iconCodePoint != null
        ? IconData(iconCodePoint, fontFamily: 'MaterialIcons')
        : Icons.book;
    final color = colorValue != null ? Color(colorValue) : Colors.blue;

    await _controller.addNotebook(title, icon, id: id, color: color);

    // 查找刚创建的笔记本（如果提供了ID则用ID查找，否则用标题查找）
    final notebook = id != null
        ? _controller.getNotebook(id)
        : _controller.notebooks.firstWhere(
            (nb) => nb.title == title,
            orElse: () => Notebook(id: '', title: ''),
          );

    if (notebook == null || notebook.id.isEmpty) {
      return jsonEncode({'error': '创建笔记本失败'});
    }

    return jsonEncode({
      'id': notebook.id,
      'title': notebook.title,
      'icon': notebook.icon.codePoint,
      'color': notebook.color.value,
    });
  }

  /// 更新笔记本
  Future<String> _jsUpdateNotebook(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? notebookId = params['notebookId'];
    if (notebookId == null || notebookId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: notebookId'});
    }

    final notebook = _controller.getNotebook(notebookId);
    if (notebook == null || notebook.id.isEmpty) {
      return jsonEncode({'error': '笔记本不存在'});
    }

    // 可选参数（从 updates 子对象获取）
    final Map<String, dynamic>? updates = params['updates'];
    if (updates == null) {
      return jsonEncode({'error': '缺少必需参数: updates'});
    }

    // 应用更新
    final updatedNotebook = Notebook(
      id: notebook.id,
      title: updates['title'] ?? notebook.title,
      icon: updates['icon'] != null
          ? IconData(updates['icon'] as int, fontFamily: 'MaterialIcons')
          : notebook.icon,
      color: updates['color'] != null ? Color(updates['color'] as int) : notebook.color,
      nodes: notebook.nodes,
    );

    await _controller.updateNotebook(updatedNotebook);
    return jsonEncode({'success': true});
  }

  /// 删除笔记本
  Future<String> _jsDeleteNotebook(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? notebookId = params['notebookId'];
    if (notebookId == null || notebookId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: notebookId'});
    }

    await _controller.deleteNotebook(notebookId);
    return jsonEncode({'success': true});
  }

  /// 获取节点列表（可选父节点ID）
  Future<String> _jsGetNodes(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? notebookId = params['notebookId'];
    if (notebookId == null || notebookId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: notebookId'});
    }

    // 可选参数
    final String? parentId = params['parentId'];

    final notebook = _controller.getNotebook(notebookId);
    if (notebook == null || notebook.id.isEmpty) {
      return jsonEncode({'error': '笔记本不存在'});
    }

    List<Node> nodes;
    if (parentId == null || parentId.isEmpty) {
      // 获取根节点
      nodes = notebook.nodes;
    } else {
      // 获取指定父节点的子节点
      final parentNode = _controller.findNodeById(notebookId, parentId);
      if (parentNode == null) {
        return jsonEncode({'error': '父节点不存在'});
      }
      nodes = parentNode.children;
    }

    final nodeList = nodes.map((n) => _nodeToJson(n, includeChildren: false)).toList();

    // 应用分页
    final result = _paginate(nodeList, params);
    return jsonEncode(result);
  }

  /// 获取节点详情
  Future<String> _jsGetNode(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? notebookId = params['notebookId'];
    final String? nodeId = params['nodeId'];

    if (notebookId == null || notebookId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: notebookId'});
    }
    if (nodeId == null || nodeId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: nodeId'});
    }

    final node = _controller.findNodeById(notebookId, nodeId);
    if (node == null) {
      return jsonEncode({'error': '节点不存在'});
    }

    return jsonEncode(_nodeToJson(node, includeChildren: true));
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

    // 可选的自定义 ID，未提供则自动生成
    final String nodeId = nodeData['id'] ?? const Uuid().v4();

    final newNode = Node(
      id: nodeId,
      title: nodeData['title'] ?? '新节点',
      createdAt: DateTime.now(),
      tags: (nodeData['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      status: _parseNodeStatus(nodeData['status']),
      startDate: nodeData['startDate'] != null
          ? DateTime.parse(nodeData['startDate'])
          : null,
      endDate: nodeData['endDate'] != null
          ? DateTime.parse(nodeData['endDate'])
          : null,
      customFields: (nodeData['customFields'] as List<dynamic>?)
          ?.map((f) => CustomField(
                key: f['key'] ?? '',
                value: f['value'] ?? '',
              ))
          .toList() ?? [],
      notes: nodeData['notes'] ?? '',
      parentId: nodeData['parentId'] ?? '',
      color: nodeData['color'] != null ? Color(nodeData['color'] as int) : Colors.grey,
      pathValue: nodeData['title'] ?? '新节点',
    );

    await _controller.addNode(notebookId, newNode, parentId: newNode.parentId.isNotEmpty ? newNode.parentId : null);

    return jsonEncode({
      'id': newNode.id,
      'title': newNode.title,
      'status': newNode.status.toString().split('.').last,
    });
  }

  /// 更新节点
  Future<String> _jsUpdateNode(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? notebookId = params['notebookId'];
    final String? nodeId = params['nodeId'];

    if (notebookId == null || notebookId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: notebookId'});
    }
    if (nodeId == null || nodeId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: nodeId'});
    }

    final node = _controller.findNodeById(notebookId, nodeId);
    if (node == null) {
      return jsonEncode({'error': '节点不存在'});
    }

    // 可选参数（从 updates 子对象获取）
    final Map<String, dynamic>? updates = params['updates'];
    if (updates == null) {
      return jsonEncode({'error': '缺少必需参数: updates'});
    }

    // 应用更新
    final updatedNode = Node(
      id: node.id,
      title: updates['title'] ?? node.title,
      createdAt: node.createdAt,
      tags: updates['tags'] != null
          ? (updates['tags'] as List<dynamic>).map((e) => e.toString()).toList()
          : node.tags,
      status: updates['status'] != null ? _parseNodeStatus(updates['status']) : node.status,
      startDate: updates['startDate'] != null
          ? DateTime.parse(updates['startDate'])
          : node.startDate,
      endDate: updates['endDate'] != null
          ? DateTime.parse(updates['endDate'])
          : node.endDate,
      customFields: updates['customFields'] != null
          ? (updates['customFields'] as List<dynamic>)
              .map((f) => CustomField(
                    key: f['key'] ?? '',
                    value: f['value'] ?? '',
                  ))
              .toList()
          : node.customFields,
      notes: updates['notes'] ?? node.notes,
      parentId: node.parentId,
      color: updates['color'] != null ? Color(updates['color'] as int) : node.color,
      pathValue: node.pathValue,
      children: node.children,
      isExpanded: node.isExpanded,
    );

    await _controller.updateNode(notebookId, updatedNode);
    return jsonEncode({'success': true});
  }

  /// 删除节点
  Future<String> _jsDeleteNode(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? notebookId = params['notebookId'];
    final String? nodeId = params['nodeId'];

    if (notebookId == null || notebookId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: notebookId'});
    }
    if (nodeId == null || nodeId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: nodeId'});
    }

    await _controller.deleteNode(notebookId, nodeId);
    return jsonEncode({'success': true});
  }

  /// 移动节点到新的父节点下
  Future<String> _jsMoveNode(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? notebookId = params['notebookId'];
    final String? nodeId = params['nodeId'];
    final String? newParentId = params['newParentId'];

    if (notebookId == null || notebookId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: notebookId'});
    }
    if (nodeId == null || nodeId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: nodeId'});
    }
    if (newParentId == null) {
      return jsonEncode({'error': '缺少必需参数: newParentId'});
    }

    final node = _controller.findNodeById(notebookId, nodeId);
    if (node == null) {
      return jsonEncode({'error': '节点不存在'});
    }

    // 创建更新后的节点（更改 parentId）
    final movedNode = Node(
      id: node.id,
      title: node.title,
      createdAt: node.createdAt,
      tags: node.tags,
      status: node.status,
      startDate: node.startDate,
      endDate: node.endDate,
      customFields: node.customFields,
      notes: node.notes,
      parentId: newParentId,
      color: node.color,
      pathValue: node.pathValue,
      children: node.children,
      isExpanded: node.isExpanded,
    );

    // 先删除原位置的节点
    await _controller.deleteNode(notebookId, nodeId);

    // 在新位置添加节点
    await _controller.addNode(
      notebookId,
      movedNode,
      parentId: newParentId.isNotEmpty ? newParentId : null,
    );

    return jsonEncode({'success': true});
  }

  /// 获取完整节点树
  Future<String> _jsGetNodeTree(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? notebookId = params['notebookId'];
    if (notebookId == null || notebookId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: notebookId'});
    }

    final notebook = _controller.getNotebook(notebookId);
    if (notebook == null || notebook.id.isEmpty) {
      return jsonEncode({'error': '笔记本不存在'});
    }

    return jsonEncode({
      'notebookId': notebook.id,
      'notebookTitle': notebook.title,
      'tree': notebook.nodes.map((n) => _nodeToJson(n, includeChildren: true)).toList(),
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

    final pathTitles = _controller.getNodePath(notebookId, nodeId);
    final pathIds = _controller.getNodePathIds(notebookId, nodeId);

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

    final notebooks = _controller.notebooks;
    final matches = <Notebook>[];

    for (var notebook in notebooks) {
      bool isMatch = false;

      switch (field.toLowerCase()) {
        case 'id':
          isMatch = notebook.id == value;
          break;
        case 'title':
          isMatch = notebook.title == value;
          break;
        default:
          // 尝试通过反射或直接比较
          isMatch = false;
      }

      if (isMatch) {
        if (!findAll) {
          return jsonEncode({
            'id': notebook.id,
            'title': notebook.title,
            'icon': notebook.icon.codePoint,
            'color': notebook.color.value,
            'nodeCount': _countAllNodes(notebook.nodes),
          });
        }
        matches.add(notebook);
      }
    }

    if (findAll) {
      return jsonEncode(matches.map((nb) => {
        'id': nb.id,
        'title': nb.title,
        'icon': nb.icon.codePoint,
        'color': nb.color.value,
        'nodeCount': _countAllNodes(nb.nodes),
      }).toList());
    }

    return jsonEncode(null);
  }

  /// 根据ID查找笔记本
  Future<String> _jsFindNotebookById(Map<String, dynamic> params) async {
    final String? id = params['id'];
    if (id == null || id.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: id'});
    }

    final notebook = _controller.getNotebook(id);
    if (notebook == null || notebook.id.isEmpty) {
      return jsonEncode(null);
    }

    return jsonEncode({
      'id': notebook.id,
      'title': notebook.title,
      'icon': notebook.icon.codePoint,
      'color': notebook.color.value,
      'nodeCount': _countAllNodes(notebook.nodes),
    });
  }

  /// 根据标题查找笔记本
  Future<String> _jsFindNotebookByTitle(Map<String, dynamic> params) async {
    final String? title = params['title'];
    if (title == null || title.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: title'});
    }

    final bool fuzzy = params['fuzzy'] ?? false;
    final bool findAll = params['findAll'] ?? false;

    final notebooks = _controller.notebooks;
    final matches = <Notebook>[];

    for (var notebook in notebooks) {
      final isMatch = fuzzy
          ? notebook.title.toLowerCase().contains(title.toLowerCase())
          : notebook.title == title;

      if (isMatch) {
        if (!findAll) {
          return jsonEncode({
            'id': notebook.id,
            'title': notebook.title,
            'icon': notebook.icon.codePoint,
            'color': notebook.color.value,
            'nodeCount': _countAllNodes(notebook.nodes),
          });
        }
        matches.add(notebook);
      }
    }

    if (findAll) {
      return jsonEncode(matches.map((nb) => {
        'id': nb.id,
        'title': nb.title,
        'icon': nb.icon.codePoint,
        'color': nb.color.value,
        'nodeCount': _countAllNodes(nb.nodes),
      }).toList());
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

    final notebook = _controller.getNotebook(notebookId);
    if (notebook == null || notebook.id.isEmpty) {
      return jsonEncode({'error': '���记本不存在'});
    }

    final matches = <Node>[];

    void searchNodes(List<Node> nodes) {
      for (var node in nodes) {
        bool isMatch = false;

        switch (field.toLowerCase()) {
          case 'id':
            isMatch = node.id == value;
            break;
          case 'title':
            isMatch = node.title == value;
            break;
          case 'status':
            isMatch = node.status.toString().split('.').last == value;
            break;
          default:
            isMatch = false;
        }

        if (isMatch) {
          if (!findAll) {
            return;
          }
          matches.add(node);
        }

        searchNodes(node.children);
      }
    }

    searchNodes(notebook.nodes);

    if (!findAll && matches.isNotEmpty) {
      return jsonEncode(_nodeToJson(matches.first, includeChildren: false));
    }

    if (findAll) {
      return jsonEncode(matches.map((n) => _nodeToJson(n, includeChildren: false)).toList());
    }

    return jsonEncode(null);
  }

  /// 根据ID查找节点
  Future<String> _jsFindNodeById(Map<String, dynamic> params) async {
    final String? notebookId = params['notebookId'];
    if (notebookId == null || notebookId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: notebookId'});
    }

    final String? nodeId = params['nodeId'];
    if (nodeId == null || nodeId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: nodeId'});
    }

    final node = _controller.findNodeById(notebookId, nodeId);
    if (node == null) {
      return jsonEncode(null);
    }

    return jsonEncode(_nodeToJson(node, includeChildren: false));
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

    final bool fuzzy = params['fuzzy'] ?? false;
    final bool findAll = params['findAll'] ?? false;

    final notebook = _controller.getNotebook(notebookId);
    if (notebook == null || notebook.id.isEmpty) {
      return jsonEncode({'error': '笔记本不存在'});
    }

    final matches = <Node>[];

    void searchNodes(List<Node> nodes) {
      for (var node in nodes) {
        final isMatch = fuzzy
            ? node.title.toLowerCase().contains(title.toLowerCase())
            : node.title == title;

        if (isMatch) {
          matches.add(node);
          if (!findAll) {
            return;
          }
        }

        searchNodes(node.children);
      }
    }

    searchNodes(notebook.nodes);

    if (!findAll && matches.isNotEmpty) {
      return jsonEncode(_nodeToJson(matches.first, includeChildren: false));
    }

    if (findAll) {
      return jsonEncode(matches.map((n) => _nodeToJson(n, includeChildren: false)).toList());
    }

    return jsonEncode(null);
  }

  // ==================== 辅助方法 ====================

  /// 将节点转换为 JSON（可选包含子节点）
  Map<String, dynamic> _nodeToJson(Node node, {bool includeChildren = false}) {
    final json = {
      'id': node.id,
      'title': node.title,
      'createdAt': node.createdAt.toIso8601String(),
      'tags': node.tags,
      'status': node.status.toString().split('.').last,
      'startDate': node.startDate?.toIso8601String(),
      'endDate': node.endDate?.toIso8601String(),
      'customFields': node.customFields.map((f) => {
        'key': f.key,
        'value': f.value,
      }).toList(),
      'notes': node.notes,
      'parentId': node.parentId,
      'color': node.color.value,
      'pathValue': node.pathValue,
      'childrenCount': node.children.length,
    };

    if (includeChildren && node.children.isNotEmpty) {
      json['children'] = node.children.map((c) => _nodeToJson(c, includeChildren: true)).toList();
    }

    return json;
  }

  /// 解析节点状态
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
    } else if (status is int && status >= 0 && status < NodeStatus.values.length) {
      return NodeStatus.values[status];
    }
    return NodeStatus.none;
  }

  /// 分页辅助方法
  ///
  /// 根据 offset 和 count 参数对列表进行分页
  /// - 如果 offset 和 count 都为 null,返回原格式(列表)
  /// - 如果提供了分页参数,返回包含 items、total、offset、count 的对象
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
    final List<dynamic> paginatedItems = items.skip(actualOffset).take(actualCount).toList();

    return {
      'items': paginatedItems,
      'total': items.length,
      'offset': actualOffset,
      'count': paginatedItems.length,
    };
  }

  // 计算所有笔记本中的节点总数
  int _countAllNodes(List<Node> nodes) {
    int count = nodes.length;
    for (var node in nodes) {
      count += _countAllNodes(node.children);
    }
    return count;
  }

  // 计算所有待办节点数量
  int _countTodoNodes(List<Node> nodes) {
    int count = 0;
    for (var node in nodes) {
      if (node.status == NodeStatus.todo) {
        count++;
      }
      count += _countTodoNodes(node.children);
    }
    return count;
  }

  @override
  Widget buildCardView(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<(int, int, int)>(
      future: Future(() {
        final notebookCount = _controller.notebooks.length;

        int totalNodes = 0;
        int todoNodes = 0;

        for (var notebook in _controller.notebooks) {
          totalNodes += _countAllNodes(notebook.nodes);
          todoNodes += _countTodoNodes(notebook.nodes);
        }

        return (notebookCount, totalNodes, todoNodes);
      }),
      builder: (context, snapshot) {
        final notebookCount = snapshot.data?.$1 ?? 0;
        final nodeCount = snapshot.data?.$2 ?? 0;
        final todoCount = snapshot.data?.$3 ?? 0;

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
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 24, color: color),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'nodes_name'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Column(
                children: [
                  // 第一行 - 笔记本数量和节点数量
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // 笔记本数量
                      Column(
                        children: [
                          Text(
                            'nodes_notebooksCount'.tr,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '$notebookCount',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // 节点数量
                      Column(
                        children: [
                          Text(
                            'nodes_nodesCount'.tr,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '$nodeCount',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 第二行 - 待办节点数
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            'nodes_pendingNodesCount'.tr,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '$todoCount',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
