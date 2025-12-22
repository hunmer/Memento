import 'package:uuid/uuid.dart';

import 'agent_chain_node.dart';

const _uuid = Uuid();

/// 工具调用 Agent 配置
class ToolAgentConfig {
  /// 服务商ID
  final String providerId;

  /// 模型ID
  final String modelId;

  /// 模型名称（用于显示）
  final String? modelName;

  const ToolAgentConfig({
    required this.providerId,
    required this.modelId,
    this.modelName,
  });

  factory ToolAgentConfig.fromJson(Map<String, dynamic> json) {
    return ToolAgentConfig(
      providerId: json['providerId'] as String,
      modelId: json['modelId'] as String,
      modelName: json['modelName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'providerId': providerId,
      'modelId': modelId,
      if (modelName != null) 'modelName': modelName,
    };
  }

  ToolAgentConfig copyWith({
    String? providerId,
    String? modelId,
    String? modelName,
  }) {
    return ToolAgentConfig(
      providerId: providerId ?? this.providerId,
      modelId: modelId ?? this.modelId,
      modelName: modelName ?? this.modelName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToolAgentConfig &&
        other.providerId == providerId &&
        other.modelId == modelId;
  }

  @override
  int get hashCode => Object.hash(providerId, modelId);
}

/// 会话模型
///
/// 代表一个与特定Agent的聊天会话
class Conversation {
  /// 会话ID
  final String id;

  /// 会话标题
  String title;

  /// 绑定的Agent ID（可选，单 agent 模式）
  /// 向后兼容：如果 agentChain 为空，则使用此字段
  final String? agentId;

  /// Agent 链配置（多 agent 链式调用模式）
  /// 如果非空，则忽略 agentId 字段
  final List<AgentChainNode>? agentChain;

  /// 工具需求识别专用 Agent 配置（第一阶段）
  /// 用于识别用户需求并返回 needed_tools
  /// 如果未配置，则使用默认 prompt 替换当前 agent 的 system prompt
  final ToolAgentConfig? toolDetectionConfig;

  /// 工具执行专用 Agent 配置（第二阶段）
  /// 用于生成工具调用的 JavaScript 代码
  /// 如果未配置，则使用默认 prompt 替换当前 agent 的 system prompt
  final ToolAgentConfig? toolExecutionConfig;

  /// 所属分组（支持多个分组）
  List<String> groups;

  /// 会话级上下文消息数量设置
  /// null表示使用全局设置
  int? contextMessageCount;

  /// 创建时间
  final DateTime createdAt;

  /// 最后一条消息的时间
  DateTime lastMessageAt;

  /// 是否置顶
  bool isPinned;

  /// 最后一条消息预览（用于列表显示）
  String? lastMessagePreview;

  /// 未读消息数
  int unreadCount;

  /// 元数据（扩展字段）
  Map<String, dynamic>? metadata;

  Conversation({
    required this.id,
    required this.title,
    this.agentId,
    this.agentChain,
    this.toolDetectionConfig,
    this.toolExecutionConfig,
    this.groups = const [],
    this.contextMessageCount,
    required this.createdAt,
    required this.lastMessageAt,
    this.isPinned = false,
    this.lastMessagePreview,
    this.unreadCount = 0,
    this.metadata,
  });

  /// 判断是否为链式模式
  bool get isChainMode => agentChain != null && agentChain!.isNotEmpty;

  /// 获取有效的 agent 列表（兼容单 agent 和链式模式）
  List<String> get effectiveAgentIds {
    if (isChainMode) {
      return agentChain!.map((node) => node.agentId).toList();
    } else if (agentId != null) {
      return [agentId!];
    }
    return [];
  }

  /// 创建新会话的工厂方法
  factory Conversation.create({
    required String title,
    String? agentId,
    List<AgentChainNode>? agentChain,
    ToolAgentConfig? toolDetectionConfig,
    ToolAgentConfig? toolExecutionConfig,
    List<String>? groups,
    int? contextMessageCount,
  }) {
    final now = DateTime.now();
    return Conversation(
      id: _uuid.v4(),
      title: title,
      agentId: agentId,
      agentChain: agentChain,
      toolDetectionConfig: toolDetectionConfig,
      toolExecutionConfig: toolExecutionConfig,
      groups: groups ?? [],
      contextMessageCount: contextMessageCount,
      createdAt: now,
      lastMessageAt: now,
    );
  }

  /// 从JSON反序列化
  factory Conversation.fromJson(Map<String, dynamic> json) {
    // 兼容旧版本：尝试从 toolDetectionAgentId/toolExecutionAgentId 迁移
    ToolAgentConfig? toolDetectionConfig;
    ToolAgentConfig? toolExecutionConfig;

    if (json.containsKey('toolDetectionAgentId') ||
        json.containsKey('toolExecutionAgentId')) {
      // 旧版本数据，直接迁移（使用默认配置）
      // 注意：这只是一个占位迁移，实际使用时需要用户提供正确的配置
      print('⚠️ 检测到旧版本工具 Agent 配置，建议重新配置工具调用设置');
    } else {
      // 新版本数据
      if (json.containsKey('toolDetectionConfig')) {
        toolDetectionConfig = ToolAgentConfig.fromJson(
          json['toolDetectionConfig'] as Map<String, dynamic>,
        );
      }
      if (json.containsKey('toolExecutionConfig')) {
        toolExecutionConfig = ToolAgentConfig.fromJson(
          json['toolExecutionConfig'] as Map<String, dynamic>,
        );
      }
    }

    return Conversation(
      id: json['id'] as String,
      title: json['title'] as String,
      agentId: json['agentId'] as String?,
      agentChain: (json['agentChain'] as List<dynamic>?)
          ?.map((e) => AgentChainNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      toolDetectionConfig: toolDetectionConfig,
      toolExecutionConfig: toolExecutionConfig,
      groups: (json['groups'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      contextMessageCount: json['contextMessageCount'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
      lastMessagePreview: json['lastMessagePreview'] as String?,
      unreadCount: json['unreadCount'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'agentId': agentId,
      if (agentChain != null && agentChain!.isNotEmpty)
        'agentChain': agentChain!.map((node) => node.toJson()).toList(),
      if (toolDetectionConfig != null)
        'toolDetectionConfig': toolDetectionConfig!.toJson(),
      if (toolExecutionConfig != null)
        'toolExecutionConfig': toolExecutionConfig!.toJson(),
      'groups': groups,
      'contextMessageCount': contextMessageCount,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'isPinned': isPinned,
      'lastMessagePreview': lastMessagePreview,
      'unreadCount': unreadCount,
      'metadata': metadata,
    };
  }

  /// 复制会话（用于修改）
  Conversation copyWith({
    String? title,
    String? agentId,
    List<AgentChainNode>? agentChain,
    bool clearAgentChain = false, // 用于清除链配置
    ToolAgentConfig? toolDetectionConfig,
    ToolAgentConfig? toolExecutionConfig,
    bool clearToolAgents = false, // 用于清除工具 Agent 配置
    List<String>? groups,
    int? contextMessageCount,
    DateTime? lastMessageAt,
    bool? isPinned,
    String? lastMessagePreview,
    int? unreadCount,
    Map<String, dynamic>? metadata,
  }) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      agentId: agentId ?? this.agentId,
      agentChain: clearAgentChain ? null : (agentChain ?? this.agentChain),
      toolDetectionConfig: clearToolAgents
          ? null
          : (toolDetectionConfig ?? this.toolDetectionConfig),
      toolExecutionConfig: clearToolAgents
          ? null
          : (toolExecutionConfig ?? this.toolExecutionConfig),
      groups: groups ?? this.groups,
      contextMessageCount: contextMessageCount ?? this.contextMessageCount,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isPinned: isPinned ?? this.isPinned,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      unreadCount: unreadCount ?? this.unreadCount,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 比较函数（用于排序）
  /// 置顶的在前，然后按最后消息时间降序
  static int compare(Conversation a, Conversation b) {
    // 置顶优先
    if (a.isPinned && !b.isPinned) return -1;
    if (!a.isPinned && b.isPinned) return 1;

    // 按最后消息时间降序
    return b.lastMessageAt.compareTo(a.lastMessageAt);
  }
}
