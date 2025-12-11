/// Agent Chat 插件 - 服务端 Repository 实现
library;

import 'package:shared_models/shared_models.dart';
import '../services/plugin_data_service.dart';

class ServerAgentChatRepository implements IAgentChatRepository {
  final PluginDataService dataService;
  final String userId;

  static const String _pluginId = 'agent_chat';

  ServerAgentChatRepository({
    required this.dataService,
    required this.userId,
  });

  // ============ 内部方法 ============

  Future<List<AgentChatConversationDto>> _readAllConversations() async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      'conversations.json',
    );
    if (data == null) return [];

    final conversations = data['conversations'] as List<dynamic>? ?? [];
    return conversations
        .map(
            (e) => AgentChatConversationDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAllConversations(
      List<AgentChatConversationDto> conversations) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'conversations.json',
      {'conversations': conversations.map((c) => c.toJson()).toList()},
    );
  }

  Future<List<AgentChatGroupDto>> _readAllGroups() async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      'groups.json',
    );
    if (data == null) return [];

    final groups = data['groups'] as List<dynamic>? ?? [];
    return groups
        .map((e) => AgentChatGroupDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAllGroups(List<AgentChatGroupDto> groups) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'groups.json',
      {'groups': groups.map((g) => g.toJson()).toList()},
    );
  }

  Future<List<AgentChatMessageDto>> _readConversationMessages(
      String conversationId) async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      'messages_$conversationId.json',
    );
    if (data == null) return [];

    final messages = data['messages'] as List<dynamic>? ?? [];
    return messages
        .map((e) => AgentChatMessageDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveConversationMessages(
    String conversationId,
    List<AgentChatMessageDto> messages,
  ) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'messages_$conversationId.json',
      {'messages': messages.map((m) => m.toJson()).toList()},
    );
  }

  Future<List<AgentChatToolTemplateDto>> _readAllToolTemplates() async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      'tool_templates.json',
    );
    if (data == null) return [];

    final templates = data['templates'] as List<dynamic>? ?? [];
    return templates
        .map(
            (e) => AgentChatToolTemplateDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAllToolTemplates(
      List<AgentChatToolTemplateDto> templates) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'tool_templates.json',
      {'templates': templates.map((t) => t.toJson()).toList()},
    );
  }

  // ============ 会话操作实现 ============

  @override
  Future<Result<List<AgentChatConversationDto>>> getConversations({
    PaginationParams? pagination,
  }) async {
    try {
      var conversations = await _readAllConversations();

      // 按最后消息时间降序排序，置顶的在前
      conversations.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.lastMessageAt.compareTo(a.lastMessageAt);
      });

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          conversations,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(conversations);
    } catch (e) {
      return Result.failure('获取会话列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AgentChatConversationDto?>> getConversationById(
      String id) async {
    try {
      final conversations = await _readAllConversations();
      final conversation = conversations.where((c) => c.id == id).firstOrNull;
      return Result.success(conversation);
    } catch (e) {
      return Result.failure('获取会话失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AgentChatConversationDto>> createConversation(
    AgentChatConversationDto conversation,
  ) async {
    try {
      final conversations = await _readAllConversations();
      conversations.add(conversation);
      await _saveAllConversations(conversations);
      return Result.success(conversation);
    } catch (e) {
      return Result.failure('创建会话失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AgentChatConversationDto>> updateConversation(
    String id,
    AgentChatConversationDto conversation,
  ) async {
    try {
      final conversations = await _readAllConversations();
      final index = conversations.indexWhere((c) => c.id == id);

      if (index == -1) {
        return Result.failure('会话不存在', code: ErrorCodes.notFound);
      }

      conversations[index] = conversation;
      await _saveAllConversations(conversations);
      return Result.success(conversation);
    } catch (e) {
      return Result.failure('更新会话失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteConversation(String id) async {
    try {
      final conversations = await _readAllConversations();
      final initialLength = conversations.length;
      conversations.removeWhere((c) => c.id == id);

      if (conversations.length == initialLength) {
        return Result.failure('会话不存在', code: ErrorCodes.notFound);
      }

      await _saveAllConversations(conversations);
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
      var conversations = await _readAllConversations();

      if (query.agentId != null) {
        conversations =
            conversations.where((c) => c.agentId == query.agentId).toList();
      }

      if (query.groupId != null) {
        conversations = conversations
            .where((c) => c.groups.contains(query.groupId))
            .toList();
      }

      if (query.isPinned != null) {
        conversations =
            conversations.where((c) => c.isPinned == query.isPinned).toList();
      }

      if (query.keyword != null) {
        final keyword = query.keyword!.toLowerCase();
        conversations = conversations.where((c) {
          return c.title.toLowerCase().contains(keyword) ||
              (c.lastMessagePreview?.toLowerCase().contains(keyword) ?? false);
        }).toList();
      }

      // 排序
      conversations.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.lastMessageAt.compareTo(a.lastMessageAt);
      });

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          conversations,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(conversations);
    } catch (e) {
      return Result.failure('搜索会话失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 分组操作实现 ============

  @override
  Future<Result<List<AgentChatGroupDto>>> getGroups() async {
    try {
      var groups = await _readAllGroups();
      groups.sort((a, b) => a.order.compareTo(b.order));
      return Result.success(groups);
    } catch (e) {
      return Result.failure('获取分组列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AgentChatGroupDto?>> getGroupById(String id) async {
    try {
      final groups = await _readAllGroups();
      final group = groups.where((g) => g.id == id).firstOrNull;
      return Result.success(group);
    } catch (e) {
      return Result.failure('获取分组失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AgentChatGroupDto>> createGroup(AgentChatGroupDto group) async {
    try {
      final groups = await _readAllGroups();
      groups.add(group);
      await _saveAllGroups(groups);
      return Result.success(group);
    } catch (e) {
      return Result.failure('创建分组失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AgentChatGroupDto>> updateGroup(
      String id, AgentChatGroupDto group) async {
    try {
      final groups = await _readAllGroups();
      final index = groups.indexWhere((g) => g.id == id);

      if (index == -1) {
        return Result.failure('分组不存在', code: ErrorCodes.notFound);
      }

      groups[index] = group;
      await _saveAllGroups(groups);
      return Result.success(group);
    } catch (e) {
      return Result.failure('更新分组失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteGroup(String id) async {
    try {
      final groups = await _readAllGroups();
      final initialLength = groups.length;
      groups.removeWhere((g) => g.id == id);

      if (groups.length == initialLength) {
        return Result.failure('分组不存在', code: ErrorCodes.notFound);
      }

      await _saveAllGroups(groups);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除分组失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 消息操作实现 ============

  @override
  Future<Result<List<AgentChatMessageDto>>> getMessages(
    String conversationId, {
    PaginationParams? pagination,
  }) async {
    try {
      var messages = await _readConversationMessages(conversationId);

      // 按时间升序排序
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          messages,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(messages);
    } catch (e) {
      return Result.failure('获取消息列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AgentChatMessageDto?>> getMessageById(String id) async {
    try {
      // 需要遍历所有会话的消息
      final conversations = await _readAllConversations();
      for (final conversation in conversations) {
        final messages = await _readConversationMessages(conversation.id);
        final message = messages.where((m) => m.id == id).firstOrNull;
        if (message != null) {
          return Result.success(message);
        }
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure('获取消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AgentChatMessageDto>> createMessage(
      AgentChatMessageDto message) async {
    try {
      final messages = await _readConversationMessages(message.conversationId);
      messages.add(message);
      await _saveConversationMessages(message.conversationId, messages);
      return Result.success(message);
    } catch (e) {
      return Result.failure('创建消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AgentChatMessageDto>> updateMessage(
    String id,
    AgentChatMessageDto message,
  ) async {
    try {
      final messages = await _readConversationMessages(message.conversationId);
      final index = messages.indexWhere((m) => m.id == id);

      if (index == -1) {
        return Result.failure('消息不存在', code: ErrorCodes.notFound);
      }

      messages[index] = message;
      await _saveConversationMessages(message.conversationId, messages);
      return Result.success(message);
    } catch (e) {
      return Result.failure('更新消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteMessage(String id) async {
    try {
      // 需要遍历所有会话的消息
      final conversations = await _readAllConversations();
      for (final conversation in conversations) {
        final messages = await _readConversationMessages(conversation.id);
        final initialLength = messages.length;
        messages.removeWhere((m) => m.id == id);

        if (messages.length < initialLength) {
          await _saveConversationMessages(conversation.id, messages);
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
      var messages = await _readConversationMessages(query.conversationId);

      if (query.startTime != null) {
        messages = messages
            .where((m) => m.timestamp.isAfter(query.startTime!))
            .toList();
      }

      if (query.endTime != null) {
        messages = messages
            .where((m) => m.timestamp.isBefore(query.endTime!))
            .toList();
      }

      if (query.isUser != null) {
        messages = messages.where((m) => m.isUser == query.isUser).toList();
      }

      if (query.keyword != null) {
        final keyword = query.keyword!.toLowerCase();
        messages = messages.where((m) {
          return m.content.toLowerCase().contains(keyword);
        }).toList();
      }

      // 按时间升序排序
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          messages,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(messages);
    } catch (e) {
      return Result.failure('搜索消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteMessagesByConversation(
      String conversationId) async {
    try {
      await _saveConversationMessages(conversationId, []);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 工具模板操作实现 ============

  @override
  Future<Result<List<AgentChatToolTemplateDto>>> getToolTemplates({
    PaginationParams? pagination,
  }) async {
    try {
      var templates = await _readAllToolTemplates();

      // 按创建时间降序排序
      templates.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          templates,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(templates);
    } catch (e) {
      return Result.failure('获取工具模板列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AgentChatToolTemplateDto?>> getToolTemplateById(
      String id) async {
    try {
      final templates = await _readAllToolTemplates();
      final template = templates.where((t) => t.id == id).firstOrNull;
      return Result.success(template);
    } catch (e) {
      return Result.failure('获取工具模板失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AgentChatToolTemplateDto>> createToolTemplate(
    AgentChatToolTemplateDto template,
  ) async {
    try {
      final templates = await _readAllToolTemplates();
      templates.add(template);
      await _saveAllToolTemplates(templates);
      return Result.success(template);
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
      final templates = await _readAllToolTemplates();
      final index = templates.indexWhere((t) => t.id == id);

      if (index == -1) {
        return Result.failure('工具模板不存在', code: ErrorCodes.notFound);
      }

      templates[index] = template;
      await _saveAllToolTemplates(templates);
      return Result.success(template);
    } catch (e) {
      return Result.failure('更新工具模板失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteToolTemplate(String id) async {
    try {
      final templates = await _readAllToolTemplates();
      final initialLength = templates.length;
      templates.removeWhere((t) => t.id == id);

      if (templates.length == initialLength) {
        return Result.failure('工具模板不存在', code: ErrorCodes.notFound);
      }

      await _saveAllToolTemplates(templates);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除工具模板失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<AgentChatToolTemplateDto>>> searchToolTemplates(
    AgentChatTemplateQuery query,
  ) async {
    try {
      var templates = await _readAllToolTemplates();

      if (query.keyword != null) {
        final keyword = query.keyword!.toLowerCase();
        templates = templates.where((t) {
          return t.name.toLowerCase().contains(keyword) ||
              (t.description?.toLowerCase().contains(keyword) ?? false);
        }).toList();
      }

      if (query.tags != null && query.tags!.isNotEmpty) {
        templates = templates.where((t) {
          return query.tags!.any((tag) => t.tags.contains(tag));
        }).toList();
      }

      // 按创建时间降序排序
      templates.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          templates,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(templates);
    } catch (e) {
      return Result.failure('搜索工具模板失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 统计操作实现 ============

  @override
  Future<Result<int>> getConversationCount() async {
    try {
      final conversations = await _readAllConversations();
      return Result.success(conversations.length);
    } catch (e) {
      return Result.failure('获取会话数量失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<int>> getMessageCount(String conversationId) async {
    try {
      final messages = await _readConversationMessages(conversationId);
      return Result.success(messages.length);
    } catch (e) {
      return Result.failure('获取消息数量失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<Map<String, int>>> getTemplateUsageStats() async {
    try {
      final templates = await _readAllToolTemplates();
      final stats = <String, int>{};
      for (final template in templates) {
        stats[template.id] = template.usageCount;
      }
      return Result.success(stats);
    } catch (e) {
      return Result.failure('获取模板使用统计失败: $e', code: ErrorCodes.serverError);
    }
  }
}
