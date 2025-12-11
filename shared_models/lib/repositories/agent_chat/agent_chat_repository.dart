/// Agent Chat 插件 - Repository 接口定义

import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';

// ============ DTOs ============

/// 会话 DTO
class AgentChatConversationDto {
  final String id;
  final String title;
  final String? agentId;
  final List<String> groups;
  final int? contextMessageCount;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final bool isPinned;
  final String? lastMessagePreview;
  final int unreadCount;
  final Map<String, dynamic>? metadata;

  const AgentChatConversationDto({
    required this.id,
    required this.title,
    this.agentId,
    this.groups = const [],
    this.contextMessageCount,
    required this.createdAt,
    required this.lastMessageAt,
    this.isPinned = false,
    this.lastMessagePreview,
    this.unreadCount = 0,
    this.metadata,
  });

  factory AgentChatConversationDto.fromJson(Map<String, dynamic> json) {
    return AgentChatConversationDto(
      id: json['id'] as String,
      title: json['title'] as String,
      agentId: json['agentId'] as String?,
      groups: (json['groups'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      contextMessageCount: json['contextMessageCount'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
      lastMessagePreview: json['lastMessagePreview'] as String?,
      unreadCount: json['unreadCount'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

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

  AgentChatConversationDto copyWith({
    String? id,
    String? title,
    String? agentId,
    List<String>? groups,
    int? contextMessageCount,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    bool? isPinned,
    String? lastMessagePreview,
    int? unreadCount,
    Map<String, dynamic>? metadata,
  }) {
    return AgentChatConversationDto(
      id: id ?? this.id,
      title: title ?? this.title,
      agentId: agentId ?? this.agentId,
      groups: groups ?? this.groups,
      contextMessageCount: contextMessageCount ?? this.contextMessageCount,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isPinned: isPinned ?? this.isPinned,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      unreadCount: unreadCount ?? this.unreadCount,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 会话分组 DTO
class AgentChatGroupDto {
  final String id;
  final String name;
  final String? icon;
  final String? color;
  final int order;
  final DateTime createdAt;

  const AgentChatGroupDto({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    this.order = 0,
    required this.createdAt,
  });

  factory AgentChatGroupDto.fromJson(Map<String, dynamic> json) {
    return AgentChatGroupDto(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      order: json['order'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  AgentChatGroupDto copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    int? order,
    DateTime? createdAt,
  }) {
    return AgentChatGroupDto(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// 文件附件 DTO
class AgentChatAttachmentDto {
  final String id;
  final String filePath;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String? thumbnailPath;

  const AgentChatAttachmentDto({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    this.thumbnailPath,
  });

  factory AgentChatAttachmentDto.fromJson(Map<String, dynamic> json) {
    return AgentChatAttachmentDto(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
      fileType: json['fileType'] as String,
      fileSize: json['fileSize'] as int,
      thumbnailPath: json['thumbnailPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
    };
  }
}

/// 工具调用步骤 DTO
class AgentChatToolCallStepDto {
  final String method;
  final String title;
  final String desc;
  final String data;
  final String status;
  final String? result;
  final String? error;

  const AgentChatToolCallStepDto({
    required this.method,
    required this.title,
    required this.desc,
    required this.data,
    this.status = 'pending',
    this.result,
    this.error,
  });

  factory AgentChatToolCallStepDto.fromJson(Map<String, dynamic> json) {
    return AgentChatToolCallStepDto(
      method: json['method'] as String? ?? 'run_js',
      title: json['title'] as String? ?? '',
      desc: json['desc'] as String? ?? '',
      data: json['data'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      result: json['result'] as String?,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'title': title,
      'desc': desc,
      'data': data,
      'status': status,
      if (result != null) 'result': result,
      if (error != null) 'error': error,
    };
  }
}

/// 工具调用响应 DTO
class AgentChatToolCallDto {
  final List<AgentChatToolCallStepDto> steps;

  const AgentChatToolCallDto({
    required this.steps,
  });

  factory AgentChatToolCallDto.fromJson(Map<String, dynamic> json) {
    return AgentChatToolCallDto(
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) =>
                  AgentChatToolCallStepDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'steps': steps.map((s) => s.toJson()).toList(),
    };
  }
}

/// 聊天消息 DTO
class AgentChatMessageDto {
  final String id;
  final String conversationId;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final int tokenCount;
  final List<AgentChatAttachmentDto> attachments;
  final DateTime? editedAt;
  final bool isGenerating;
  final Map<String, dynamic>? metadata;
  final AgentChatToolCallDto? toolCall;
  final List<String>? matchedTemplateIds;
  final String? parentId;
  final bool isSessionDivider;

  const AgentChatMessageDto({
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
  });

  factory AgentChatMessageDto.fromJson(Map<String, dynamic> json) {
    return AgentChatMessageDto(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      content: json['content'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      tokenCount: json['tokenCount'] as int? ?? 0,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) =>
                  AgentChatAttachmentDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'] as String)
          : null,
      isGenerating: json['isGenerating'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      toolCall: json['toolCall'] != null
          ? AgentChatToolCallDto.fromJson(
              json['toolCall'] as Map<String, dynamic>)
          : null,
      matchedTemplateIds: (json['matchedTemplateIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      parentId: json['parentId'] as String?,
      isSessionDivider: json['isSessionDivider'] as bool? ?? false,
    );
  }

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
    };
  }

  AgentChatMessageDto copyWith({
    String? id,
    String? conversationId,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    int? tokenCount,
    List<AgentChatAttachmentDto>? attachments,
    DateTime? editedAt,
    bool? isGenerating,
    Map<String, dynamic>? metadata,
    AgentChatToolCallDto? toolCall,
    List<String>? matchedTemplateIds,
    String? parentId,
    bool? isSessionDivider,
  }) {
    return AgentChatMessageDto(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      tokenCount: tokenCount ?? this.tokenCount,
      attachments: attachments ?? this.attachments,
      editedAt: editedAt ?? this.editedAt,
      isGenerating: isGenerating ?? this.isGenerating,
      metadata: metadata ?? this.metadata,
      toolCall: toolCall ?? this.toolCall,
      matchedTemplateIds: matchedTemplateIds ?? this.matchedTemplateIds,
      parentId: parentId ?? this.parentId,
      isSessionDivider: isSessionDivider ?? this.isSessionDivider,
    );
  }
}

/// 保存的工具模板 DTO
class AgentChatToolTemplateDto {
  final String id;
  final String name;
  final String? description;
  final List<AgentChatToolCallStepDto> steps;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final int usageCount;
  final List<Map<String, String>> declaredTools;
  final List<String> tags;

  const AgentChatToolTemplateDto({
    required this.id,
    required this.name,
    this.description,
    required this.steps,
    required this.createdAt,
    this.lastUsedAt,
    this.usageCount = 0,
    this.declaredTools = const [],
    this.tags = const [],
  });

  factory AgentChatToolTemplateDto.fromJson(Map<String, dynamic> json) {
    return AgentChatToolTemplateDto(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      steps: (json['steps'] as List<dynamic>)
          .map((e) =>
              AgentChatToolCallStepDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
      usageCount: json['usageCount'] as int? ?? 0,
      declaredTools: (json['declaredTools'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          const [],
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'steps': steps.map((s) => s.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      if (lastUsedAt != null) 'lastUsedAt': lastUsedAt!.toIso8601String(),
      'usageCount': usageCount,
      if (declaredTools.isNotEmpty) 'declaredTools': declaredTools,
      if (tags.isNotEmpty) 'tags': tags,
    };
  }

  AgentChatToolTemplateDto copyWith({
    String? id,
    String? name,
    String? description,
    List<AgentChatToolCallStepDto>? steps,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    int? usageCount,
    List<Map<String, String>>? declaredTools,
    List<String>? tags,
  }) {
    return AgentChatToolTemplateDto(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      steps: steps ?? this.steps,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      usageCount: usageCount ?? this.usageCount,
      declaredTools: declaredTools ?? this.declaredTools,
      tags: tags ?? this.tags,
    );
  }
}

// ============ Query Objects ============

/// 会话查询参数
class AgentChatConversationQuery {
  final String? agentId;
  final String? groupId;
  final bool? isPinned;
  final String? keyword;
  final PaginationParams? pagination;

  const AgentChatConversationQuery({
    this.agentId,
    this.groupId,
    this.isPinned,
    this.keyword,
    this.pagination,
  });
}

/// 消息查询参数
class AgentChatMessageQuery {
  final String conversationId;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool? isUser;
  final String? keyword;
  final PaginationParams? pagination;

  const AgentChatMessageQuery({
    required this.conversationId,
    this.startTime,
    this.endTime,
    this.isUser,
    this.keyword,
    this.pagination,
  });
}

/// 工具模板查询参数
class AgentChatTemplateQuery {
  final String? keyword;
  final List<String>? tags;
  final PaginationParams? pagination;

  const AgentChatTemplateQuery({
    this.keyword,
    this.tags,
    this.pagination,
  });
}

// ============ Repository Interface ============

/// Agent Chat 插件 Repository 接口
abstract class IAgentChatRepository {
  // ============ 会话操作 ============

  /// 获取所有会话
  Future<Result<List<AgentChatConversationDto>>> getConversations({
    PaginationParams? pagination,
  });

  /// 根据 ID 获取会话
  Future<Result<AgentChatConversationDto?>> getConversationById(String id);

  /// 创建会话
  Future<Result<AgentChatConversationDto>> createConversation(
    AgentChatConversationDto conversation,
  );

  /// 更新会话
  Future<Result<AgentChatConversationDto>> updateConversation(
    String id,
    AgentChatConversationDto conversation,
  );

  /// 删除会话
  Future<Result<bool>> deleteConversation(String id);

  /// 搜索会话
  Future<Result<List<AgentChatConversationDto>>> searchConversations(
    AgentChatConversationQuery query,
  );

  // ============ 分组操作 ============

  /// 获取所有分组
  Future<Result<List<AgentChatGroupDto>>> getGroups();

  /// 根据 ID 获取分组
  Future<Result<AgentChatGroupDto?>> getGroupById(String id);

  /// 创建分组
  Future<Result<AgentChatGroupDto>> createGroup(AgentChatGroupDto group);

  /// 更新分组
  Future<Result<AgentChatGroupDto>> updateGroup(
    String id,
    AgentChatGroupDto group,
  );

  /// 删除分组
  Future<Result<bool>> deleteGroup(String id);

  // ============ 消息操作 ============

  /// 获取会话的消息
  Future<Result<List<AgentChatMessageDto>>> getMessages(
    String conversationId, {
    PaginationParams? pagination,
  });

  /// 根据 ID 获取消息
  Future<Result<AgentChatMessageDto?>> getMessageById(String id);

  /// 创建消息
  Future<Result<AgentChatMessageDto>> createMessage(AgentChatMessageDto message);

  /// 更新消息
  Future<Result<AgentChatMessageDto>> updateMessage(
    String id,
    AgentChatMessageDto message,
  );

  /// 删除消息
  Future<Result<bool>> deleteMessage(String id);

  /// 搜索消息
  Future<Result<List<AgentChatMessageDto>>> searchMessages(
    AgentChatMessageQuery query,
  );

  /// 删除会话的所有消息
  Future<Result<bool>> deleteMessagesByConversation(String conversationId);

  // ============ 工具模板操作 ============

  /// 获取所有工具模板
  Future<Result<List<AgentChatToolTemplateDto>>> getToolTemplates({
    PaginationParams? pagination,
  });

  /// 根据 ID 获取工具模板
  Future<Result<AgentChatToolTemplateDto?>> getToolTemplateById(String id);

  /// 创建工具模板
  Future<Result<AgentChatToolTemplateDto>> createToolTemplate(
    AgentChatToolTemplateDto template,
  );

  /// 更新工具模板
  Future<Result<AgentChatToolTemplateDto>> updateToolTemplate(
    String id,
    AgentChatToolTemplateDto template,
  );

  /// 删除工具模板
  Future<Result<bool>> deleteToolTemplate(String id);

  /// 搜索工具模板
  Future<Result<List<AgentChatToolTemplateDto>>> searchToolTemplates(
    AgentChatTemplateQuery query,
  );

  // ============ 统计操作 ============

  /// 获取会话数量
  Future<Result<int>> getConversationCount();

  /// 获取消息数量
  Future<Result<int>> getMessageCount(String conversationId);

  /// 获取模板使用统计
  Future<Result<Map<String, int>>> getTemplateUsageStats();
}
