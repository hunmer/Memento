import 'package:uuid/uuid.dart';
import 'file_attachment.dart';
import 'tool_call_step.dart';

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

  /// 工具调用（仅 AI 消息，当 AI 返回工具调用时使用）
  ToolCallResponse? toolCall;

  /// 匹配的工具模版ID列表（仅 AI 消息，第零阶段模版匹配结果）
  List<String>? matchedTemplateIds;

  /// 父消息ID（用于建立消息父子关系）
  String? parentId;

  /// 是否为会话分隔符（用于标记新会话的开始）
  bool isSessionDivider;

  /// 生成此消息的 Agent ID（仅 AI 消息，链式模式下使用）
  String? generatedByAgentId;

  /// 在链式调用中的步骤索引（仅 AI 消息，链式模式下使用）
  int? chainStepIndex;

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
    this.toolCall,
    this.matchedTemplateIds,
    this.parentId,
    this.isSessionDivider = false,
    this.generatedByAgentId,
    this.chainStepIndex,
  });

  /// 创建用户消息
  factory ChatMessage.user({
    required String conversationId,
    required String content,
    List<FileAttachment>? attachments,
    int tokenCount = 0,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
      tokenCount: tokenCount,
      attachments: attachments ?? [],
      metadata: metadata,
    );
  }

  /// 创建AI消息
  factory ChatMessage.ai({
    required String conversationId,
    String content = '',
    int tokenCount = 0,
    bool isGenerating = true,
    Map<String, dynamic>? metadata,
    String? generatedByAgentId,
    int? chainStepIndex,
  }) {
    return ChatMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      tokenCount: tokenCount,
      isGenerating: isGenerating,
      metadata: metadata,
      generatedByAgentId: generatedByAgentId,
      chainStepIndex: chainStepIndex,
    );
  }

  /// 创建会话分隔符
  factory ChatMessage.sessionDivider({
    required String conversationId,
  }) {
    return ChatMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      content: '开启了新会话',
      isUser: false,
      timestamp: DateTime.now(),
      isSessionDivider: true,
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
      toolCall: json['toolCall'] != null
          ? ToolCallResponse.fromJson(json['toolCall'] as Map<String, dynamic>)
          : null,
      matchedTemplateIds: (json['matchedTemplateIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(),
      parentId: json['parentId'] as String?,
      isSessionDivider: json['isSessionDivider'] as bool? ?? false,
      generatedByAgentId: json['generatedByAgentId'] as String?,
      chainStepIndex: json['chainStepIndex'] as int?,
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
      if (toolCall != null) 'toolCall': toolCall!.toJson(),
      if (matchedTemplateIds != null && matchedTemplateIds!.isNotEmpty)
        'matchedTemplateIds': matchedTemplateIds,
      if (parentId != null) 'parentId': parentId,
      'isSessionDivider': isSessionDivider,
      if (generatedByAgentId != null) 'generatedByAgentId': generatedByAgentId,
      if (chainStepIndex != null) 'chainStepIndex': chainStepIndex,
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
    ToolCallResponse? toolCall,
    List<String>? matchedTemplateIds,
    String? parentId,
    bool? isSessionDivider,
    String? generatedByAgentId,
    int? chainStepIndex,
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
      toolCall: toolCall ?? this.toolCall,
      matchedTemplateIds: matchedTemplateIds ?? this.matchedTemplateIds,
      parentId: parentId ?? this.parentId,
      isSessionDivider: isSessionDivider ?? this.isSessionDivider,
      generatedByAgentId: generatedByAgentId ?? this.generatedByAgentId,
      chainStepIndex: chainStepIndex ?? this.chainStepIndex,
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
