/// Agent 链节点的上下文模式
///
/// 定义了在链式调用中，当前 agent 如何接收上下文信息
enum AgentContextMode {
  /// 使用会话的历史上下文消息（遵循 contextMessageCount 设置）
  conversationContext,

  /// 使用链中所有前序 agent 的输出作为上下文
  chainContext,

  /// 仅使用上一个 agent 的输出作为输入
  previousOnly,
}

/// Agent 链中的单个节点配置
///
/// 描述了链中一个 agent 的配置信息，包括使用哪个 agent、
/// 采用什么上下文模式、以及在链中的执行顺序
class AgentChainNode {
  /// Agent ID
  final String agentId;

  /// 上下文模式
  final AgentContextMode contextMode;

  /// 节点在链中的顺序（从0开始）
  final int order;

  AgentChainNode({
    required this.agentId,
    this.contextMode = AgentContextMode.conversationContext,
    required this.order,
  });

  /// 从 JSON 创建实例
  factory AgentChainNode.fromJson(Map<String, dynamic> json) {
    return AgentChainNode(
      agentId: json['agentId'] as String,
      contextMode: AgentContextMode.values.firstWhere(
        (e) => e.name == json['contextMode'],
        orElse: () => AgentContextMode.conversationContext,
      ),
      order: json['order'] as int,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'contextMode': contextMode.name,
      'order': order,
    };
  }

  /// 创建副本
  AgentChainNode copyWith({
    String? agentId,
    AgentContextMode? contextMode,
    int? order,
  }) {
    return AgentChainNode(
      agentId: agentId ?? this.agentId,
      contextMode: contextMode ?? this.contextMode,
      order: order ?? this.order,
    );
  }

  @override
  String toString() {
    return 'AgentChainNode(agentId: $agentId, contextMode: $contextMode, order: $order)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AgentChainNode &&
        other.agentId == agentId &&
        other.contextMode == contextMode &&
        other.order == order;
  }

  @override
  int get hashCode {
    return agentId.hashCode ^ contextMode.hashCode ^ order.hashCode;
  }
}
