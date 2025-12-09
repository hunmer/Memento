import 'package:uuid/uuid.dart';
import 'package:get/get.dart';

const _uuid = Uuid();

/// 会话模型
///
/// 代表一个与特定Agent的聊天会话
class Conversation {
  /// 会话ID
  final String id;

  /// 会话标题
  String title;

  /// 绑定的Agent ID（可选，可在聊天时选择）
  final String? agentId;

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
    required this.agentId,
    this.groups = const [],
    this.contextMessageCount,
    required this.createdAt,
    required this.lastMessageAt,
    this.isPinned = false,
    this.lastMessagePreview,
    this.unreadCount = 0,
    this.metadata,
  });

  /// 创建新会话的工厂方法
  factory Conversation.create({
    required String title,
    String? agentId,
    List<String>? groups,
    int? contextMessageCount,
  }) {
    final now = DateTime.now();
    return Conversation(
      id: _uuid.v4(),
      title: title,
      agentId: agentId,
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
