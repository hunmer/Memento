/// 工具配置数据模型
///
/// 用于管理 AI Agent 可调用的 JavaScript 工具
library;

/// 工具参数配置
class ToolParameter {
  /// 参数名
  final String name;

  /// 参数类型
  final String type;

  /// 是否可选
  final bool optional;

  /// 参数描述
  final String description;

  ToolParameter({
    required this.name,
    required this.type,
    this.optional = false,
    required this.description,
  });

  factory ToolParameter.fromJson(Map<String, dynamic> json) {
    // 兼容 'optional' 和 'required' 两种字段名
    final bool optional;
    if (json.containsKey('optional')) {
      optional = json['optional'] as bool? ?? false;
    } else if (json.containsKey('required')) {
      // required 的反义是 optional
      optional = !(json['required'] as bool? ?? true);
    } else {
      optional = false;
    }

    return ToolParameter(
      name: json['name'] as String,
      type: json['type'] as String,
      optional: optional,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'optional': optional,
      'description': description,
    };
  }

  ToolParameter copyWith({
    String? name,
    String? type,
    bool? optional,
    String? description,
  }) {
    return ToolParameter(
      name: name ?? this.name,
      type: type ?? this.type,
      optional: optional ?? this.optional,
      description: description ?? this.description,
    );
  }
}

/// 工具返回值配置
class ToolReturns {
  /// 返回值类型
  final String type;

  /// 返回值描述
  final String description;

  ToolReturns({
    required this.type,
    required this.description,
  });

  factory ToolReturns.fromJson(Map<String, dynamic> json) {
    return ToolReturns(
      type: json['type'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
    };
  }

  ToolReturns copyWith({
    String? type,
    String? description,
  }) {
    return ToolReturns(
      type: type ?? this.type,
      description: description ?? this.description,
    );
  }
}

/// 工具示例代码
class ToolExample {
  /// 示例代码
  final String code;

  /// 示例说明
  final String comment;

  ToolExample({
    required this.code,
    required this.comment,
  });

  factory ToolExample.fromJson(Map<String, dynamic> json) {
    return ToolExample(
      code: json['code'] as String,
      // 兼容 'comment' 和 'title' 两种字段名
      comment: (json['comment'] ?? json['title'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'comment': comment,
    };
  }

  ToolExample copyWith({
    String? code,
    String? comment,
  }) {
    return ToolExample(
      code: code ?? this.code,
      comment: comment ?? this.comment,
    );
  }
}

/// 工具详细配置
class ToolConfig {
  /// 工具标题
  final String title;

  /// 工具描述
  final String description;

  /// 参数列表
  final List<ToolParameter> parameters;

  /// 返回值配置
  final ToolReturns returns;

  /// 示例代码列表
  final List<ToolExample> examples;

  /// 注意事项
  final String? notes;

  /// 是否启用
  final bool enabled;

  ToolConfig({
    required this.title,
    required this.description,
    this.parameters = const [],
    required this.returns,
    this.examples = const [],
    this.notes,
    this.enabled = true,
  });

  factory ToolConfig.fromJson(Map<String, dynamic> json) {
    return ToolConfig(
      title: json['title'] as String,
      description: json['description'] as String,
      parameters: (json['parameters'] as List<dynamic>?)
              ?.map((e) => ToolParameter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      returns: ToolReturns.fromJson(json['returns'] as Map<String, dynamic>),
      examples: (json['examples'] as List<dynamic>?)
              ?.map((e) => ToolExample.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: json['notes'] as String?,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'parameters': parameters.map((e) => e.toJson()).toList(),
      'returns': returns.toJson(),
      'examples': examples.map((e) => e.toJson()).toList(),
      if (notes != null) 'notes': notes,
      'enabled': enabled,
    };
  }

  ToolConfig copyWith({
    String? title,
    String? description,
    List<ToolParameter>? parameters,
    ToolReturns? returns,
    List<ToolExample>? examples,
    String? notes,
    bool? enabled,
  }) {
    return ToolConfig(
      title: title ?? this.title,
      description: description ?? this.description,
      parameters: parameters ?? this.parameters,
      returns: returns ?? this.returns,
      examples: examples ?? this.examples,
      notes: notes ?? this.notes,
      enabled: enabled ?? this.enabled,
    );
  }

  /// 生成工具签名字符串（用于显示）
  String getSignature(String toolId) {
    final params = parameters.map((p) {
      final optional = p.optional ? '?' : '';
      return '${p.name}$optional';
    }).join(', ');
    return '$toolId($params)';
  }

  /// 生成简要描述（用于工具索引）
  String getBriefDescription() {
    // 提取描述的第一句话
    final sentences = description.split(RegExp(r'[。\.]\s*'));
    final firstSentence = sentences.isNotEmpty ? sentences.first : description;
    return firstSentence.length > 50
        ? '${firstSentence.substring(0, 50)}...'
        : firstSentence;
  }
}

/// 插件工具集合
class PluginToolSet {
  /// 插件 ID
  final String pluginId;

  /// 工具配置映射 (toolId -> ToolConfig)
  final Map<String, ToolConfig> tools;

  PluginToolSet({
    required this.pluginId,
    required this.tools,
  });

  factory PluginToolSet.fromJson(String pluginId, Map<String, dynamic> json) {
    final tools = <String, ToolConfig>{};
    json.forEach((methodName, value) {
      // 生成完整的工具 ID (pluginId_methodName 格式)
      // 如果 methodName 已经包含插件前缀，则不重复添加
      String fullToolId;
      if (methodName.startsWith('${pluginId}_')) {
        fullToolId = methodName;
      } else {
        fullToolId = '${pluginId}_$methodName';
      }

      tools[fullToolId] = ToolConfig.fromJson(value as Map<String, dynamic>);
    });
    return PluginToolSet(
      pluginId: pluginId,
      tools: tools,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    tools.forEach((key, value) {
      json[key] = value.toJson();
    });
    return json;
  }

  /// 获取启用的工具列表
  List<String> getEnabledToolIds() {
    return tools.entries
        .where((e) => e.value.enabled)
        .map((e) => e.key)
        .toList();
  }

  /// 获取工具数量
  int get toolCount => tools.length;

  /// 获取启用的工具数量
  int get enabledToolCount => tools.values.where((t) => t.enabled).length;
}

/// 工具简要信息（用于第一阶段 AI 请求）
class ToolBrief {
  /// 工具 ID (格式: plugin_methodName)
  final String toolId;

  /// 简要描述
  final String brief;

  ToolBrief({
    required this.toolId,
    required this.brief,
  });

  /// 转换为数组格式 [toolId, brief]
  List<String> toArray() {
    return [toolId, brief];
  }

  /// 从数组格式解析
  factory ToolBrief.fromArray(List<dynamic> array) {
    return ToolBrief(
      toolId: array[0] as String,
      brief: array[1] as String,
    );
  }
}
