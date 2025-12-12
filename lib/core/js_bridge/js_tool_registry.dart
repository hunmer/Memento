import 'dart:convert';

/// JavaScript 工具配置模型
class JSToolConfig {
  /// 工具唯一标识
  final String id;

  /// 工具名称
  final String name;

  /// 工具描述
  final String description;

  /// JavaScript 代码
  final String code;

  /// 所属卡片 ID
  final String? cardId;

  JSToolConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.code,
    this.cardId,
  });

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'code': code,
      'cardId': cardId,
    };
  }

  /// 从 JSON 反序列化
  factory JSToolConfig.fromJson(Map<String, dynamic> json) {
    return JSToolConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      code: json['code'] as String,
      cardId: json['cardId'] as String?,
    );
  }

  @override
  String toString() {
    return 'JSToolConfig{id: $id, name: $name, description: $description, cardId: $cardId}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JSToolConfig &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          code == other.code &&
          cardId == other.cardId;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ description.hashCode ^ code.hashCode ^ cardId.hashCode;
}

/// JavaScript 工具注册表
class JSToolRegistry {
  static final JSToolRegistry _instance = JSToolRegistry._internal();
  factory JSToolRegistry() => _instance;
  JSToolRegistry._internal();

  /// 工具注册表：toolId -> JSToolConfig
  final Map<String, JSToolConfig> _tools = {};

  /// 注册工具
  void registerTool(JSToolConfig tool) {
    _tools[tool.id] = tool;
    print('JS 工具已注册: ${tool.id}');
  }

  /// 注销工具
  void unregisterTool(String toolId) {
    final removed = _tools.remove(toolId);
    if (removed != null) {
      print('JS 工具已注销: $toolId');
    }
  }

  /// 获取所有工具
  List<JSToolConfig> getAllTools() {
    return _tools.values.toList();
  }

  /// 获取指定工具
  JSToolConfig? getTool(String toolId) {
    return _tools[toolId];
  }

  /// 检查工具是否存在
  bool hasTool(String toolId) {
    return _tools.containsKey(toolId);
  }

  /// 清空所有工具
  void clearAll() {
    _tools.clear();
    print('所有 JS 工具已清空');
  }

  /// 获取工具数量
  int get toolCount => _tools.length;

  /// 按卡片 ID 获取工具
  List<JSToolConfig> getToolsByCardId(String cardId) {
    return _tools.values.where((tool) => tool.cardId == cardId).toList();
  }

  @override
  String toString() {
    return 'JSToolRegistry{tools: ${_tools.keys.toList()}, count: ${_tools.length}}';
  }
}
