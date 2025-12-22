import 'package:uuid/uuid.dart';
import 'agent_chain_node.dart';

/// Agent 链预设
///
/// 用于保存和复用常用的 Agent 链配置
class AgentChainPreset {
  /// 预设 ID
  final String id;

  /// 预设名称
  final String name;

  /// 预设描述（可选）
  final String? description;

  /// Agent 链配置
  final List<AgentChainNode> chain;

  /// 创建时间
  final DateTime createdAt;

  /// 最后更新时间
  final DateTime updatedAt;

  AgentChainPreset({
    String? id,
    required this.name,
    this.description,
    required this.chain,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 从 JSON 创建实例
  factory AgentChainPreset.fromJson(Map<String, dynamic> json) {
    return AgentChainPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      chain: (json['chain'] as List)
          .map((e) => AgentChainNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'chain': chain.map((node) => node.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 创建副本
  AgentChainPreset copyWith({
    String? id,
    String? name,
    String? description,
    List<AgentChainNode>? chain,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AgentChainPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      chain: chain ?? List.from(this.chain),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AgentChainPreset(id: $id, name: $name, chain: ${chain.length} nodes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AgentChainPreset && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
