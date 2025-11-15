import 'package:uuid/uuid.dart';
import 'file_attachment.dart';

const _uuid = Uuid();

/// 聊天消息模型
class ChatMessage {
  /// 消息ID
  final String id;

  /// 所属会话ID
  final String conversationId;

  /// 消息内容（Markdown格式）
  String content;

  /// 是否为用户消息（true=用户，false=AI）
  final bool isUser;

  /// 消息时间戳
  final DateTime timestamp;

  /// Token数量（用于统计）
  int tokenCount;

  /// 附件列表
  List<FileAttachment> attachments;

  /// 编辑时间（null表示未编辑）
  DateTime? editedAt;

  /// 是否正在生成中（仅AI消息）
  bool isGenerating;

  /// 元数据（扩展字段）
  Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.tokenCount = 0,
    this.attachments = const [],
    this.editedAt,
    this.isGenerating = false,
    this.metadata,
  });

  /// 创建用户消息
  factory ChatMessage.user({
    required String conversationId,
    required String content,
    List<FileAttachment>? attachments,
    int tokenCount = 0,
  }) {
    return ChatMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
      tokenCount: tokenCount,
      attachments: attachments ?? [],
    );
  }

  /// 创建AI消息
  factory ChatMessage.ai({
    required String conversationId,
    String content = '',
    int tokenCount = 0,
    bool isGenerating = true,
  }) {
    return ChatMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      tokenCount: tokenCount,
      isGenerating: isGenerating,
    );
  }

  /// 从JSON反序列化
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      content: json['content'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      tokenCount: json['tokenCount'] as int? ?? 0,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) =>
                  FileAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'] as String)
          : null,
      isGenerating: json['isGenerating'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'tokenCount': tokenCount,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      if (editedAt != null) 'editedAt': editedAt!.toIso8601String(),
      'isGenerating': isGenerating,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// 复制消息（用于修改）
  ChatMessage copyWith({
    String? content,
    int? tokenCount,
    List<FileAttachment>? attachments,
    DateTime? editedAt,
    bool? isGenerating,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      content: content ?? this.content,
      isUser: isUser,
      timestamp: timestamp,
      tokenCount: tokenCount ?? this.tokenCount,
      attachments: attachments ?? this.attachments,
      editedAt: editedAt ?? this.editedAt,
      isGenerating: isGenerating ?? this.isGenerating,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 标记为已编辑
  ChatMessage markAsEdited(String newContent) {
    return copyWith(
      content: newContent,
      editedAt: DateTime.now(),
    );
  }

  /// 完成生成（仅AI消息）
  ChatMessage completeGeneration(int finalTokenCount) {
    return copyWith(
      isGenerating: false,
      tokenCount: finalTokenCount,
    );
  }
}
