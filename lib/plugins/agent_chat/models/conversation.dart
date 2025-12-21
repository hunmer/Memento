import 'package:uuid/uuid.dart';

import 'agent_chain_node.dart';

const _uuid = Uuid();

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

  /// 工具需求识别专用 Agent ID（第一阶段）
  /// 用于识别用户需求并返回 needed_tools
  /// 如果未配置，则使用默认 prompt 替换当前 agent 的 system prompt
  final String? toolDetectionAgentId;

  /// 工具执行专用 Agent ID（第二阶段）
  /// 用于生成工具调用的 JavaScript 代码
  /// 如果未配置，则使用默认 prompt 替换当前 agent 的 system prompt
  final String? toolExecutionAgentId;

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
    this.toolDetectionAgentId,
    this.toolExecutionAgentId,
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
    String? toolDetectionAgentId,
    String? toolExecutionAgentId,
    List<String>? groups,
    int? contextMessageCount,
  }) {
    final now = DateTime.now();
    return Conversation(
      id: _uuid.v4(),
      title: title,
      agentId: agentId,
      agentChain: agentChain,
      toolDetectionAgentId: toolDetectionAgentId,
      toolExecutionAgentId: toolExecutionAgentId,
      groups: groups ?? [],
      contextMessageCount: contextMessageCount,
      createdAt: now,
      lastMessageAt: now,
    );
  }

  /// 从JSON反序列化
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      title: json['title'] as String,
      agentId: json['agentId'] as String?,
      agentChain: (json['agentChain'] as List<dynamic>?)
          ?.map((e) => AgentChainNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      toolDetectionAgentId: json['toolDetectionAgentId'] as String?,
      toolExecutionAgentId: json['toolExecutionAgentId'] as String?,
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
      'toolDetectionAgentId': toolDetectionAgentId,
      'toolExecutionAgentId': toolExecutionAgentId,
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
    String? toolDetectionAgentId,
    String? toolExecutionAgentId,
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
      toolDetectionAgentId: clearToolAgents
          ? null
          : (toolDetectionAgentId ?? this.toolDetectionAgentId),
      toolExecutionAgentId: clearToolAgents
          ? null
          : (toolExecutionAgentId ?? this.toolExecutionAgentId),
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
