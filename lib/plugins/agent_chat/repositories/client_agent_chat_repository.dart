/// Agent Chat 插件 - 客户端 Repository 实现
///
/// 通过适配现有的 ConversationService 和 MessageService 来实现 IAgentChatRepository 接口

library;

import 'package:Memento/plugins/agent_chat/services/conversation_service.dart';
import 'package:Memento/plugins/agent_chat/services/message_service.dart';
import 'package:Memento/plugins/agent_chat/models/conversation.dart';
import 'package:Memento/plugins/agent_chat/models/conversation_group.dart';
import 'package:Memento/plugins/agent_chat/models/chat_message.dart';
import 'package:Memento/plugins/agent_chat/models/file_attachment.dart';
import 'package:Memento/plugins/agent_chat/models/tool_call_step.dart';
import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

/// 客户端 AgentChat Repository 实现
class ClientAgentChatRepository extends IAgentChatRepository {
  final ConversationService conversationService;
  final MessageService messageService;
  final Color pluginColor;

  ClientAgentChatRepository({
    required this.conversationService,
    required this.messageService,
    required this.pluginColor,
  });

  // ============ 会话操作 ============

  @override
  Future<Result<List<AgentChatConversationDto>>> getConversations({
    PaginationParams? pagination,
  }) async {
    try {
      final conversations = conversationService.conversations;
      final dtos = conversations.map(_conversationToDto).toList();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('获取会话列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AgentChatConversationDto?>> getConversationById(String id) async {
    try {
      final conversation = conversationService.getConversation(id);
      if (conversation == null) {
        return Result.success(null);
      }
      return Result.success(_conversationToDto(conversation));
    } catch (e) {
      return Result.failure('获取会话失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AgentChatConversationDto>> createConversation(
    AgentChatConversationDto dto,
  ) async {
    try {
      final conversation = Conversation(
        id: dto.id,
        title: dto.title,
        agentId: dto.agentId,
        groups: dto.groups,
        contextMessageCount: dto.contextMessageCount,
        createdAt: dto.createdAt,
        lastMessageAt: dto.lastMessageAt,
        isPinned: dto.isPinned,
        lastMessagePreview: dto.lastMessagePreview,
        unreadCount: dto.unreadCount,
        metadata: dto.metadata,
      );

      await conversationService.createConversation(
        title: conversation.title,
        agentId: conversation.agentId,
        groups: conversation.groups,
        contextMessageCount: conversation.contextMessageCount,
      );

      return Result.success(_conversationToDto(conversation));
    } catch (e) {
      return Result.failure('创建会话失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AgentChatConversationDto>> updateConversation(
    String id,
    AgentChatConversationDto dto,
  ) async {
    try {
      final conversation = conversationService.getConversation(id);
      if (conversation == null) {
        return Result.failure('会话不存在', code: ErrorCodes.notFound);
      }

      // 由于 agentId 是 final 字段，需要通过创建新实例来更新
      final updatedConversation = Conversation(
        id: conversation.id,
        title: dto.title,
        agentId: dto.agentId ?? conversation.agentId,
        groups: dto.groups,
        contextMessageCount: dto.contextMessageCount,
        createdAt: conversation.createdAt,
        lastMessageAt: dto.lastMessageAt,
        isPinned: dto.isPinned,
        lastMessagePreview: dto.lastMessagePreview,
        unreadCount: dto.unreadCount,
        metadata: dto.metadata,
      );

      await conversationService.updateConversation(updatedConversation);

      return Result.success(_conversationToDto(updatedConversation));
    } catch (e) {
      return Result.failure('更新会话失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteConversation(String id) async {
    try {
      await conversationService.deleteConversation(id);
      // 同时删除该会话的所有消息
      await messageService.clearAllMessages(id);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除会话失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<AgentChatConversationDto>>> searchConversations(
    AgentChatConversationQuery query,
  ) async {
    try {
      final conversations = conversationService.conversations;
      final matches = <Conversation>[];

      for (final conversation in conversations) {
        bool isMatch = true;

        // 应用过滤器
        if (query.agentId != null && conversation.agentId != query.agentId) {
          isMatch = false;
        }

        if (query.groupId != null &&
            !conversation.groups.contains(query.groupId)) {
          isMatch = false;
        }

        if (query.isPinned != null && conversation.isPinned != query.isPinned) {
          isMatch = false;
        }

        // 搜索关键词
        if (query.keyword != null && query.keyword!.isNotEmpty) {
          final keyword = query.keyword!.toLowerCase();
          final titleMatch =
              conversation.title.toLowerCase().contains(keyword);
          final previewMatch =
              (conversation.lastMessagePreview ?? '')
                  .toLowerCase()
                  .contains(keyword);
          if (!titleMatch && !previewMatch) {
            isMatch = false;
          }
        }

        if (isMatch) {
          matches.add(conversation);
        }
      }

      final dtos = matches.map(_conversationToDto).toList();

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('搜索会话失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 分组操作 ============

  @override
  Future<Result<List<AgentChatGroupDto>>> getGroups() async {
    try {
      final groups = conversationService.groups;
      return Result.success(groups.map(_groupToDto).toList());
    } catch (e) {
      return Result.failure('获取分组列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AgentChatGroupDto?>> getGroupById(String id) async {
    try {
      final group =
          conversationService.groups.where((g) => g.id == id).firstOrNull;
      if (group == null) {
        return Result.success(null);
      }
      return Result.success(_groupToDto(group));
    } catch (e) {
      return Result.failure('获取分组失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AgentChatGroupDto>> createGroup(AgentChatGroupDto dto) async {
    try {
      final group = ConversationGroup(
        id: dto.id,
        name: dto.name,
        icon: dto.icon,
        color: dto.color,
        order: dto.order,
        createdAt: dto.createdAt,
      );

      await conversationService.createGroup(
        name: group.name,
        icon: group.icon,
        color: group.color,
      );

      return Result.success(_groupToDto(group));
    } catch (e) {
      return Result.failure('创建分组失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AgentChatGroupDto>> updateGroup(
    String id,
    AgentChatGroupDto dto,
  ) async {
    try {
      final group =
          conversationService.groups.where((g) => g.id == id).firstOrNull;
      if (group == null) {
        return Result.failure('分组不存在', code: ErrorCodes.notFound);
      }

      // 更新字段
      group.name = dto.name;
      group.icon = dto.icon;
      group.color = dto.color;
      group.order = dto.order;

      await conversationService.updateGroup(group);

      return Result.success(_groupToDto(group));
    } catch (e) {
      return Result.failure('更新分组失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteGroup(String id) async {
    try {
      await conversationService.deleteGroup(id);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除分组失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 消息操作 ============

  @override
  Future<Result<List<AgentChatMessageDto>>> getMessages(
    String conversationId, {
    PaginationParams? pagination,
  }) async {
    try {
      final messages = await messageService.getMessages(conversationId);
      final dtos = messages.map((m) => _messageToDto(m)).toList();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('获取消息列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AgentChatMessageDto?>> getMessageById(String id) async {
    try {
      // 遍历所有会话的消息查找指定ID的消息
      for (final conversation in conversationService.conversations) {
        final message = messageService.getMessage(conversation.id, id);
        if (message != null) {
          return Result.success(_messageToDto(message));
        }
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure('获取消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AgentChatMessageDto>> createMessage(
    AgentChatMessageDto dto,
  ) async {
    try {
      final message = ChatMessage(
        id: dto.id,
        conversationId: dto.conversationId,
        content: dto.content,
        isUser: dto.isUser,
        timestamp: dto.timestamp,
        tokenCount: dto.tokenCount,
        attachments: dto.attachments
            .map((a) => FileAttachment(
                  id: a.id,
                  filePath: a.filePath,
                  fileName: a.fileName,
                  fileType: a.fileType,
                  fileSize: a.fileSize,
                  thumbnailPath: a.thumbnailPath,
                ))
            .toList(),
        editedAt: dto.editedAt,
        isGenerating: dto.isGenerating,
        metadata: dto.metadata,
        toolCall: dto.toolCall != null
            ? ToolCallResponse(
                steps: dto.toolCall!.steps
                    .map((s) => ToolCallStep(
                          method: s.method,
                          title: s.title,
                          desc: s.desc,
                          data: s.data,
                          status: ToolCallStatus.values.firstWhere(
                            (status) => status.name == s.status,
                            orElse: () => ToolCallStatus.pending,
                          ),
                          result: s.result,
                          error: s.error,
                        ))
                    .toList(),
              )
            : null,
        matchedTemplateIds: dto.matchedTemplateIds,
        parentId: dto.parentId,
        isSessionDivider: dto.isSessionDivider,
      );

      await messageService.addMessage(message);

      // 由于 Conversation 的 agentId 是 final，需要通过创建新实例来更新
      final conversation = conversationService.getConversation(dto.conversationId);
      if (conversation != null) {
        final updatedConversation = Conversation(
          id: conversation.id,
          title: conversation.title,
          agentId: conversation.agentId,
          groups: conversation.groups,
          contextMessageCount: conversation.contextMessageCount,
          createdAt: conversation.createdAt,
          lastMessageAt: message.timestamp,
          isPinned: conversation.isPinned,
          lastMessagePreview: message.content.length > 50
              ? '${message.content.substring(0, 50)}...'
              : message.content,
          unreadCount: conversation.unreadCount,
          metadata: conversation.metadata,
        );
        await conversationService.updateConversation(updatedConversation);
      }

      return Result.success(dto);
    } catch (e) {
      return Result.failure('创建消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AgentChatMessageDto>> updateMessage(
    String id,
    AgentChatMessageDto dto,
  ) async {
    try {
      final message = messageService.getMessage(dto.conversationId, id);
      if (message == null) {
        return Result.failure('消息不存在', code: ErrorCodes.notFound);
      }

      // 更新字段
      message.content = dto.content;
      message.tokenCount = dto.tokenCount;
      message.editedAt = dto.editedAt;
      message.isGenerating = dto.isGenerating;
      message.metadata = dto.metadata;

      await messageService.updateMessage(message);

      return Result.success(_messageToDto(message));
    } catch (e) {
      return Result.failure('更新消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteMessage(String id) async {
    try {
      // 遍历所有会话的消息查找指定ID的消息
      for (final conversation in conversationService.conversations) {
        final message = messageService.getMessage(conversation.id, id);
        if (message != null) {
          await messageService.deleteMessage(conversation.id, id);
          return Result.success(true);
        }
      }
      return Result.failure('消息不存在', code: ErrorCodes.notFound);
    } catch (e) {
      return Result.failure('删除消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<AgentChatMessageDto>>> searchMessages(
    AgentChatMessageQuery query,
  ) async {
    try {
      final messages = await messageService.getMessages(query.conversationId);
      final matches = <ChatMessage>[];

      for (final message in messages) {
        bool isMatch = true;

        // 应用过滤器
        if (query.isUser != null && message.isUser != query.isUser) {
          isMatch = false;
        }

        if (query.startTime != null &&
            message.timestamp.isBefore(query.startTime!)) {
          isMatch = false;
        }

        if (query.endTime != null && message.timestamp.isAfter(query.endTime!)) {
          isMatch = false;
        }

        // 搜索关键词
        if (query.keyword != null && query.keyword!.isNotEmpty) {
          final keyword = query.keyword!.toLowerCase();
          final contentMatch = message.content.toLowerCase().contains(keyword);
          if (!contentMatch) {
            isMatch = false;
          }
        }

        if (isMatch) {
          matches.add(message);
        }
      }

      final dtos = matches.map(_messageToDto).toList();

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('搜索消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteMessagesByConversation(String conversationId) async {
    try {
      await messageService.clearAllMessages(conversationId);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除会话消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 工具模板操作 ============

  @override
  Future<Result<List<AgentChatToolTemplateDto>>> getToolTemplates({
    PaginationParams? pagination,
  }) async {
    try {
      // AgentChat 插件暂时不实现工具模板功能
      // 返回空列表，避免影响其他功能
      return Result.success([]);
    } catch (e) {
      return Result.failure('获取工具模板列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AgentChatToolTemplateDto?>> getToolTemplateById(String id) async {
    try {
      return Result.success(null);
    } catch (e) {
      return Result.failure('获取工具模板失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AgentChatToolTemplateDto>> createToolTemplate(
    AgentChatToolTemplateDto template,
  ) async {
    try {
      return Result.failure('暂不支持创建工具模板', code: ErrorCodes.serverError);
    } catch (e) {
      return Result.failure('创建工具模板失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AgentChatToolTemplateDto>> updateToolTemplate(
    String id,
    AgentChatToolTemplateDto template,
  ) async {
    try {
      return Result.failure('暂不支持更新工具模板', code: ErrorCodes.serverError);
    } catch (e) {
      return Result.failure('更新工具模板失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteToolTemplate(String id) async {
    try {
      return Result.failure('暂不支持删除工具模板', code: ErrorCodes.serverError);
    } catch (e) {
      return Result.failure('删除工具模板失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<AgentChatToolTemplateDto>>> searchToolTemplates(
    AgentChatTemplateQuery query,
  ) async {
    try {
      return Result.success([]);
    } catch (e) {
      return Result.failure('搜索工具模板失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 统计操作 ============

  @override
  Future<Result<int>> getConversationCount() async {
    try {
      return Result.success(conversationService.conversations.length);
    } catch (e) {
      return Result.failure('获取会话数量失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<int>> getMessageCount(String conversationId) async {
    try {
      final messages = await messageService.getMessages(conversationId);
      return Result.success(messages.length);
    } catch (e) {
      return Result.failure('获取消息数量失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<Map<String, int>>> getTemplateUsageStats() async {
    try {
      // AgentChat 插件暂时不实现工具模板功能
      return Result.success({});
    } catch (e) {
      return Result.failure('获取模板使用统计失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 转换方法 ============

  AgentChatConversationDto _conversationToDto(Conversation conversation) {
    return AgentChatConversationDto(
      id: conversation.id,
      title: conversation.title,
      agentId: conversation.agentId,
      groups: conversation.groups,
      contextMessageCount: conversation.contextMessageCount,
      createdAt: conversation.createdAt,
      lastMessageAt: conversation.lastMessageAt,
      isPinned: conversation.isPinned,
      lastMessagePreview: conversation.lastMessagePreview,
      unreadCount: conversation.unreadCount,
      metadata: conversation.metadata,
    );
  }

  AgentChatGroupDto _groupToDto(ConversationGroup group) {
    return AgentChatGroupDto(
      id: group.id,
      name: group.name,
      icon: group.icon,
      color: group.color,
      order: group.order,
      createdAt: group.createdAt,
    );
  }

  AgentChatMessageDto _messageToDto(ChatMessage message) {
    return AgentChatMessageDto(
      id: message.id,
      conversationId: message.conversationId,
      content: message.content,
      isUser: message.isUser,
      timestamp: message.timestamp,
      tokenCount: message.tokenCount,
      attachments: message.attachments
          .map((a) => AgentChatAttachmentDto(
                id: a.id,
                filePath: a.filePath,
                fileName: a.fileName,
                fileType: a.fileType,
                fileSize: a.fileSize,
                thumbnailPath: a.thumbnailPath,
              ))
          .toList(),
      editedAt: message.editedAt,
      isGenerating: message.isGenerating,
      metadata: message.metadata,
      toolCall: message.toolCall != null
          ? AgentChatToolCallDto(
              steps: message.toolCall!.steps
                  .map((s) => AgentChatToolCallStepDto(
                        method: s.method,
                        title: s.title,
                        desc: s.desc,
                        data: s.data,
                        status: s.status.name,
                        result: s.result,
                        error: s.error,
                      ))
                  .toList(),
            )
          : null,
      matchedTemplateIds: message.matchedTemplateIds,
      parentId: message.parentId,
      isSessionDivider: message.isSessionDivider,
    );
  }
}
