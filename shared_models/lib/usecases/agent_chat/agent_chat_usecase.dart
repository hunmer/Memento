/// Agent Chat 插件 - UseCase 业务逻辑层

import 'package:uuid/uuid.dart';
import 'package:shared_models/repositories/agent_chat/agent_chat_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:shared_models/utils/validation.dart';

/// Agent Chat 插件 UseCase - 封装所有业务逻辑
class AgentChatUseCase {
  final IAgentChatRepository repository;
  final Uuid _uuid = const Uuid();

  AgentChatUseCase(this.repository);

  // ============ 会话 CRUD 操作 ============

  /// 获取会话列表
  Future<Result<dynamic>> getConversations(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getConversations(pagination: pagination);

      return result.map((conversations) {
        final jsonList = conversations.map((c) => c.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: pagination.offset,
            count: pagination.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取会话列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取会话
  Future<Result<Map<String, dynamic>?>> getConversationById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getConversationById(id);
      return result.map((conversation) => conversation?.toJson());
    } catch (e) {
      return Result.failure('获取会话失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建会话
  Future<Result<Map<String, dynamic>>> createConversation(
    Map<String, dynamic> params,
  ) async {
    // 参数验证
    final titleValidation = ParamValidator.requireString(params, 'title');
    if (!titleValidation.isValid) {
      return Result.failure(
        titleValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final now = DateTime.now();
      final conversation = AgentChatConversationDto(
        id: params['id'] as String? ?? _uuid.v4(),
        title: params['title'] as String,
        agentId: params['agentId'] as String?,
        groups: (params['groups'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        contextMessageCount: params['contextMessageCount'] as int?,
        createdAt: now,
        lastMessageAt: now,
        isPinned: params['isPinned'] as bool? ?? false,
        lastMessagePreview: params['lastMessagePreview'] as String?,
        unreadCount: params['unreadCount'] as int? ?? 0,
        metadata: params['metadata'] as Map<String, dynamic>?,
      );

      final result = await repository.createConversation(conversation);
      return result.map((c) => c.toJson());
    } catch (e) {
      return Result.failure('创建会话失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新会话
  Future<Result<Map<String, dynamic>>> updateConversation(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有数据
      final existingResult = await repository.getConversationById(id);
      if (existingResult.isFailure) {
        return Result.failure('会话不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('会话不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        title: params['title'] as String?,
        agentId: params.containsKey('agentId')
            ? params['agentId'] as String?
            : existing.agentId,
        groups: params.containsKey('groups')
            ? (params['groups'] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList() ??
                existing.groups
            : existing.groups,
        contextMessageCount: params.containsKey('contextMessageCount')
            ? params['contextMessageCount'] as int?
            : existing.contextMessageCount,
        lastMessageAt: params.containsKey('lastMessageAt')
            ? DateTime.parse(params['lastMessageAt'] as String)
            : existing.lastMessageAt,
        isPinned: params['isPinned'] as bool? ?? existing.isPinned,
        lastMessagePreview: params.containsKey('lastMessagePreview')
            ? params['lastMessagePreview'] as String?
            : existing.lastMessagePreview,
        unreadCount: params['unreadCount'] as int? ?? existing.unreadCount,
        metadata: params.containsKey('metadata')
            ? params['metadata'] as Map<String, dynamic>?
            : existing.metadata,
      );

      final result = await repository.updateConversation(id, updated);
      return result.map((c) => c.toJson());
    } catch (e) {
      return Result.failure('更新会话失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除会话
  Future<Result<bool>> deleteConversation(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 同时删除会话的所有消息
      await repository.deleteMessagesByConversation(id);
      return repository.deleteConversation(id);
    } catch (e) {
      return Result.failure('删除会话失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索会话
  Future<Result<dynamic>> searchConversations(
    Map<String, dynamic> params,
  ) async {
    try {
      final query = AgentChatConversationQuery(
        agentId: params['agentId'] as String?,
        groupId: params['groupId'] as String?,
        isPinned: params['isPinned'] as bool?,
        keyword: params['keyword'] as String?,
        pagination: _extractPagination(params),
      );

      final result = await repository.searchConversations(query);
      return result.map((conversations) {
        final jsonList = conversations.map((c) => c.toJson()).toList();

        if (query.pagination != null && query.pagination!.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: query.pagination!.offset,
            count: query.pagination!.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('搜索会话失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 分组 CRUD 操作 ============

  /// 获取分组列表
  Future<Result<List<Map<String, dynamic>>>> getGroups(
    Map<String, dynamic> params,
  ) async {
    try {
      final result = await repository.getGroups();
      return result.map((groups) => groups.map((g) => g.toJson()).toList());
    } catch (e) {
      return Result.failure('获取分组列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取分组
  Future<Result<Map<String, dynamic>?>> getGroupById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getGroupById(id);
      return result.map((group) => group?.toJson());
    } catch (e) {
      return Result.failure('获取分组失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建分组
  Future<Result<Map<String, dynamic>>> createGroup(
    Map<String, dynamic> params,
  ) async {
    // 参数验证
    final nameValidation = ParamValidator.requireString(params, 'name');
    if (!nameValidation.isValid) {
      return Result.failure(
        nameValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final group = AgentChatGroupDto(
        id: params['id'] as String? ?? _uuid.v4(),
        name: params['name'] as String,
        icon: params['icon'] as String?,
        color: params['color'] as String?,
        order: params['order'] as int? ?? 0,
        createdAt: DateTime.now(),
      );

      final result = await repository.createGroup(group);
      return result.map((g) => g.toJson());
    } catch (e) {
      return Result.failure('创建分组失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新分组
  Future<Result<Map<String, dynamic>>> updateGroup(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有数据
      final existingResult = await repository.getGroupById(id);
      if (existingResult.isFailure) {
        return Result.failure('分组不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('分组不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        name: params['name'] as String?,
        icon: params.containsKey('icon')
            ? params['icon'] as String?
            : existing.icon,
        color: params.containsKey('color')
            ? params['color'] as String?
            : existing.color,
        order: params['order'] as int? ?? existing.order,
      );

      final result = await repository.updateGroup(id, updated);
      return result.map((g) => g.toJson());
    } catch (e) {
      return Result.failure('更新分组失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除分组
  Future<Result<bool>> deleteGroup(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteGroup(id);
    } catch (e) {
      return Result.failure('删除分组失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 消息 CRUD 操作 ============

  /// 获取消息列表
  Future<Result<dynamic>> getMessages(Map<String, dynamic> params) async {
    final conversationId = params['conversationId'] as String?;
    if (conversationId == null || conversationId.isEmpty) {
      return Result.failure(
        '缺少必需参数: conversationId',
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final pagination = _extractPagination(params);
      final result = await repository.getMessages(
        conversationId,
        pagination: pagination,
      );

      return result.map((messages) {
        final jsonList = messages.map((m) => m.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: pagination.offset,
            count: pagination.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取消息列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取消息
  Future<Result<Map<String, dynamic>?>> getMessageById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getMessageById(id);
      return result.map((message) => message?.toJson());
    } catch (e) {
      return Result.failure('获取消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建消息
  Future<Result<Map<String, dynamic>>> createMessage(
    Map<String, dynamic> params,
  ) async {
    // 参数验证
    final conversationIdValidation =
        ParamValidator.requireString(params, 'conversationId');
    if (!conversationIdValidation.isValid) {
      return Result.failure(
        conversationIdValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    final contentValidation = ParamValidator.requireString(params, 'content');
    if (!contentValidation.isValid) {
      return Result.failure(
        contentValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final attachments = (params['attachments'] as List<dynamic>?)
              ?.map((e) =>
                  AgentChatAttachmentDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [];

      final toolCall = params['toolCall'] != null
          ? AgentChatToolCallDto.fromJson(
              params['toolCall'] as Map<String, dynamic>)
          : null;

      final message = AgentChatMessageDto(
        id: params['id'] as String? ?? _uuid.v4(),
        conversationId: params['conversationId'] as String,
        content: params['content'] as String,
        isUser: params['isUser'] as bool? ?? true,
        timestamp: DateTime.now(),
        tokenCount: params['tokenCount'] as int? ?? 0,
        attachments: attachments,
        isGenerating: params['isGenerating'] as bool? ?? false,
        metadata: params['metadata'] as Map<String, dynamic>?,
        toolCall: toolCall,
        matchedTemplateIds: (params['matchedTemplateIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        parentId: params['parentId'] as String?,
        isSessionDivider: params['isSessionDivider'] as bool? ?? false,
      );

      final result = await repository.createMessage(message);

      // 更新会话的最后消息时间和预览
      if (result.isSuccess) {
        await _updateConversationLastMessage(
          params['conversationId'] as String,
          message.content,
        );
      }

      return result.map((m) => m.toJson());
    } catch (e) {
      return Result.failure('创建消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新消息
  Future<Result<Map<String, dynamic>>> updateMessage(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有数据
      final existingResult = await repository.getMessageById(id);
      if (existingResult.isFailure) {
        return Result.failure('消息不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('消息不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        content: params['content'] as String?,
        tokenCount: params['tokenCount'] as int?,
        editedAt: params.containsKey('content') ? DateTime.now() : null,
        isGenerating: params['isGenerating'] as bool?,
        metadata: params.containsKey('metadata')
            ? params['metadata'] as Map<String, dynamic>?
            : existing.metadata,
        toolCall: params.containsKey('toolCall') && params['toolCall'] != null
            ? AgentChatToolCallDto.fromJson(
                params['toolCall'] as Map<String, dynamic>)
            : existing.toolCall,
        matchedTemplateIds: params.containsKey('matchedTemplateIds')
            ? (params['matchedTemplateIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList()
            : existing.matchedTemplateIds,
      );

      final result = await repository.updateMessage(id, updated);
      return result.map((m) => m.toJson());
    } catch (e) {
      return Result.failure('更新消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除消息
  Future<Result<bool>> deleteMessage(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteMessage(id);
    } catch (e) {
      return Result.failure('删除消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索消息
  Future<Result<dynamic>> searchMessages(Map<String, dynamic> params) async {
    final conversationId = params['conversationId'] as String?;
    if (conversationId == null || conversationId.isEmpty) {
      return Result.failure(
        '缺少必需参数: conversationId',
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final query = AgentChatMessageQuery(
        conversationId: conversationId,
        startTime: params['startTime'] != null
            ? DateTime.parse(params['startTime'] as String)
            : null,
        endTime: params['endTime'] != null
            ? DateTime.parse(params['endTime'] as String)
            : null,
        isUser: params['isUser'] as bool?,
        keyword: params['keyword'] as String?,
        pagination: _extractPagination(params),
      );

      final result = await repository.searchMessages(query);
      return result.map((messages) {
        final jsonList = messages.map((m) => m.toJson()).toList();

        if (query.pagination != null && query.pagination!.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: query.pagination!.offset,
            count: query.pagination!.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('搜索消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 工具模板 CRUD 操作 ============

  /// 获取工具模板列表
  Future<Result<dynamic>> getToolTemplates(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getToolTemplates(pagination: pagination);

      return result.map((templates) {
        final jsonList = templates.map((t) => t.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: pagination.offset,
            count: pagination.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取工具模板列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取工具模板
  Future<Result<Map<String, dynamic>?>> getToolTemplateById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getToolTemplateById(id);
      return result.map((template) => template?.toJson());
    } catch (e) {
      return Result.failure('获取工具模板失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建工具模板
  Future<Result<Map<String, dynamic>>> createToolTemplate(
    Map<String, dynamic> params,
  ) async {
    // 参数验证
    final nameValidation = ParamValidator.requireString(params, 'name');
    if (!nameValidation.isValid) {
      return Result.failure(
        nameValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final steps = (params['steps'] as List<dynamic>?)
              ?.map((e) =>
                  AgentChatToolCallStepDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [];

      final template = AgentChatToolTemplateDto(
        id: params['id'] as String? ?? _uuid.v4(),
        name: params['name'] as String,
        description: params['description'] as String?,
        steps: steps,
        createdAt: DateTime.now(),
        usageCount: 0,
        declaredTools: (params['declaredTools'] as List<dynamic>?)
                ?.map((e) => Map<String, String>.from(e as Map))
                .toList() ??
            const [],
        tags: (params['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
      );

      final result = await repository.createToolTemplate(template);
      return result.map((t) => t.toJson());
    } catch (e) {
      return Result.failure('创建工具模板失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新工具模板
  Future<Result<Map<String, dynamic>>> updateToolTemplate(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有数据
      final existingResult = await repository.getToolTemplateById(id);
      if (existingResult.isFailure) {
        return Result.failure('工具模板不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('工具模板不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        name: params['name'] as String?,
        description: params.containsKey('description')
            ? params['description'] as String?
            : existing.description,
        steps: params.containsKey('steps')
            ? (params['steps'] as List<dynamic>?)
                    ?.map((e) => AgentChatToolCallStepDto.fromJson(
                        e as Map<String, dynamic>))
                    .toList() ??
                existing.steps
            : existing.steps,
        lastUsedAt: params.containsKey('lastUsedAt')
            ? DateTime.parse(params['lastUsedAt'] as String)
            : existing.lastUsedAt,
        usageCount: params['usageCount'] as int? ?? existing.usageCount,
        declaredTools: params.containsKey('declaredTools')
            ? (params['declaredTools'] as List<dynamic>?)
                    ?.map((e) => Map<String, String>.from(e as Map))
                    .toList() ??
                existing.declaredTools
            : existing.declaredTools,
        tags: params.containsKey('tags')
            ? (params['tags'] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList() ??
                existing.tags
            : existing.tags,
      );

      final result = await repository.updateToolTemplate(id, updated);
      return result.map((t) => t.toJson());
    } catch (e) {
      return Result.failure('更新工具模板失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除工具模板
  Future<Result<bool>> deleteToolTemplate(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteToolTemplate(id);
    } catch (e) {
      return Result.failure('删除工具模板失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索工具模板
  Future<Result<dynamic>> searchToolTemplates(
    Map<String, dynamic> params,
  ) async {
    try {
      final query = AgentChatTemplateQuery(
        keyword: params['keyword'] as String?,
        tags: (params['tags'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        pagination: _extractPagination(params),
      );

      final result = await repository.searchToolTemplates(query);
      return result.map((templates) {
        final jsonList = templates.map((t) => t.toJson()).toList();

        if (query.pagination != null && query.pagination!.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: query.pagination!.offset,
            count: query.pagination!.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('搜索工具模板失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 标记模板为已使用
  Future<Result<Map<String, dynamic>>> markTemplateAsUsed(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有数据
      final existingResult = await repository.getToolTemplateById(id);
      if (existingResult.isFailure) {
        return Result.failure('工具模板不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('工具模板不存在', code: ErrorCodes.notFound);
      }

      // 更新使用信息
      final updated = existing.copyWith(
        lastUsedAt: DateTime.now(),
        usageCount: existing.usageCount + 1,
      );

      final result = await repository.updateToolTemplate(id, updated);
      return result.map((t) => t.toJson());
    } catch (e) {
      return Result.failure('更新模板使用记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 统计操作 ============

  /// 获取会话数量
  Future<Result<int>> getConversationCount(Map<String, dynamic> params) async {
    try {
      return repository.getConversationCount();
    } catch (e) {
      return Result.failure('获取会话数量失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取消息数量
  Future<Result<int>> getMessageCount(Map<String, dynamic> params) async {
    final conversationId = params['conversationId'] as String?;
    if (conversationId == null || conversationId.isEmpty) {
      return Result.failure(
        '缺少必需参数: conversationId',
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      return repository.getMessageCount(conversationId);
    } catch (e) {
      return Result.failure('获取消息数量失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取模板使用统计
  Future<Result<Map<String, int>>> getTemplateUsageStats(
    Map<String, dynamic> params,
  ) async {
    try {
      return repository.getTemplateUsageStats();
    } catch (e) {
      return Result.failure('获取模板使用统计失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 辅助方法 ============

  PaginationParams? _extractPagination(Map<String, dynamic> params) {
    final offset = params['offset'] as int?;
    final count = params['count'] as int?;

    if (offset == null && count == null) return null;

    return PaginationParams(
      offset: offset ?? 0,
      count: count ?? 100,
    );
  }

  /// 更新会话的最后消息信息
  Future<void> _updateConversationLastMessage(
    String conversationId,
    String content,
  ) async {
    try {
      final existingResult = await repository.getConversationById(conversationId);
      if (existingResult.isSuccess && existingResult.dataOrNull != null) {
        final existing = existingResult.dataOrNull!;
        final preview = content.length > 50
            ? '${content.substring(0, 50)}...'
            : content;

        final updated = existing.copyWith(
          lastMessageAt: DateTime.now(),
          lastMessagePreview: preview,
        );

        await repository.updateConversation(conversationId, updated);
      }
    } catch (_) {
      // 静默失败，不影响主要操作
    }
  }
}
