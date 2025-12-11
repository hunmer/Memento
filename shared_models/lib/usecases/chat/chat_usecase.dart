/// Chat 插件 - UseCase 业务逻辑层
///
/// 此文件包含共享的业务逻辑，客户端和服务端都使用此层
/// 通过依赖 IChatRepository 接口实现解耦
library;

import 'package:uuid/uuid.dart';

import 'package:shared_models/repositories/chat/chat_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:shared_models/utils/validation.dart';

/// Chat UseCase - 封装所有业务逻辑
class ChatUseCase {
  final IChatRepository repository;
  final Uuid _uuid = const Uuid();

  ChatUseCase(this.repository);

  // ============ 频道操作 ============

  /// 获取所有频道（支持分页）
  ///
  /// [params] 支持的参数:
  /// - `offset`: 起始偏移量
  /// - `count`: 返回数量
  Future<Result<dynamic>> getChannels(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getChannels(pagination: pagination);

      return result.map((channels) {
        final jsonList = channels.map((c) => c.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList,
              offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取频道失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建频道
  ///
  /// [params] 必需参数:
  /// - `name`: 频道名称
  /// 可选参数:
  /// - `channelId`: 自定义 ID
  /// - `icon`: 图标代码点
  /// - `backgroundColor`: 背景色
  /// - `priority`: 优先级
  /// - `groups`: 分组列表
  /// - `metadata`: 元数据
  Future<Result<Map<String, dynamic>>> createChannel(
    Map<String, dynamic> params,
  ) async {
    // 参数验证
    final nameValidation = ParamValidator.requireString(params, 'name');
    if (!nameValidation.isValid) {
      return Result.failure(nameValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    try {
      final channelId = params['channelId'] as String? ?? _uuid.v4();
      final channel = ChannelDto(
        id: channelId,
        title: params['name'] as String,
        iconCodePoint: params['icon'] as int?,
        iconFontFamily: params['iconFontFamily'] as String?,
        backgroundColor: params['backgroundColor'] as String?,
        priority: params['priority'] as int? ?? 0,
        groups: (params['groups'] as List<dynamic>?)?.cast<String>() ?? [],
        lastMessageTime: DateTime.now(),
        metadata: params['metadata'] as Map<String, dynamic>?,
      );

      final result = await repository.createChannel(channel);
      return result.map((c) => c.toJson());
    } catch (e) {
      return Result.failure('创建频道失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除频道
  ///
  /// [params] 必需参数:
  /// - `id` 或 `channelId`: 频道 ID
  Future<Result<bool>> deleteChannel(Map<String, dynamic> params) async {
    final id = params['id'] as String? ?? params['channelId'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id 或 channelId',
          code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteChannel(id);
    } catch (e) {
      return Result.failure('删除频道失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取频道
  ///
  /// [params] 必需参数:
  /// - `id`: 频道 ID
  Future<Result<Map<String, dynamic>?>> getChannelById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getChannelById(id);
      return result.map((c) => c?.toJson());
    } catch (e) {
      return Result.failure('获取频道失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新频道
  ///
  /// [params] 必需参数:
  /// - `id`: 频道 ID
  /// 可选参数:
  /// - `title`: 新标题
  /// - `icon`: 新图标
  /// - `backgroundColor`: 新背景色
  /// - `priority`: 新优先级
  /// - `groups`: 新分组
  /// - `metadata`: 新元数据
  Future<Result<Map<String, dynamic>>> updateChannel(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 先获取现有频道
      final existingResult = await repository.getChannelById(id);
      if (existingResult.isFailure) {
        return Result.failure('频道不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('频道不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = ChannelDto(
        id: existing.id,
        title: params['title'] as String? ?? existing.title,
        iconCodePoint: params['icon'] as int? ?? existing.iconCodePoint,
        iconFontFamily:
            params['iconFontFamily'] as String? ?? existing.iconFontFamily,
        backgroundColor:
            params['backgroundColor'] as String? ?? existing.backgroundColor,
        priority: params['priority'] as int? ?? existing.priority,
        groups: (params['groups'] as List<dynamic>?)?.cast<String>() ??
            existing.groups,
        lastMessageTime: existing.lastMessageTime,
        metadata:
            params['metadata'] as Map<String, dynamic>? ?? existing.metadata,
      );

      final result = await repository.updateChannel(id, updated);
      return result.map((c) => c.toJson());
    } catch (e) {
      return Result.failure('更新频道失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 消息操作 ============

  /// 获取频道消息
  ///
  /// [params] 必需参数:
  /// - `channelId`: 频道 ID
  /// 可选参数:
  /// - `offset`: 起始偏移量
  /// - `count`: 返回数量
  Future<Result<dynamic>> getMessages(Map<String, dynamic> params) async {
    final idValidation = ParamValidator.requireString(params, 'channelId');
    if (!idValidation.isValid) {
      return Result.failure(idValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    try {
      final channelId = params['channelId'] as String;
      final pagination = _extractPagination(params);
      final result =
          await repository.getMessages(channelId, pagination: pagination);

      return result.map((messages) {
        final jsonList = messages.map((m) => m.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList,
              offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 发送消息
  ///
  /// [params] 必需参数:
  /// - `channelId`: 频道 ID
  /// - `content`: 消息内容
  /// 可选参数:
  /// - `type`: 消息类型 (sent/received/system)
  /// - `replyToId`: 回复的消息 ID
  /// - `metadata`: 元数据
  /// - `user`: 自定义发送者信息
  Future<Result<Map<String, dynamic>>> sendMessage(
    Map<String, dynamic> params, {
    UserDto? defaultUser,
  }) async {
    // 参数验证
    final channelValidation = ParamValidator.requireString(params, 'channelId');
    if (!channelValidation.isValid) {
      return Result.failure(channelValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    final contentValidation = ParamValidator.requireString(params, 'content');
    if (!contentValidation.isValid) {
      return Result.failure(contentValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    try {
      final channelId = params['channelId'] as String;

      // 获取用户信息
      UserDto user;
      if (params['user'] != null) {
        user = UserDto.fromJson(params['user'] as Map<String, dynamic>);
      } else if (defaultUser != null) {
        user = defaultUser;
      } else {
        final userResult = await repository.getCurrentUser();
        if (userResult.isFailure) {
          return Result.failure('获取当前用户失败', code: ErrorCodes.serverError);
        }
        user = userResult.dataOrNull!;
      }

      final message = MessageDto(
        id: params['id'] as String? ?? _uuid.v4(),
        content: params['content'] as String,
        channelId: channelId,
        user: user,
        type: params['type'] as String? ?? 'sent',
        date: DateTime.now(),
        replyToId: params['replyToId'] as String?,
        metadata: params['metadata'] as Map<String, dynamic>?,
      );

      final result = await repository.sendMessage(channelId, message);
      return result.map((m) => m.toJson());
    } catch (e) {
      return Result.failure('发送消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除消息
  ///
  /// [params] 必需参数:
  /// - `channelId`: 频道 ID
  /// - `messageId`: 消息 ID
  Future<Result<bool>> deleteMessage(Map<String, dynamic> params) async {
    final channelValidation = ParamValidator.requireString(params, 'channelId');
    if (!channelValidation.isValid) {
      return Result.failure(channelValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    final messageValidation = ParamValidator.requireString(params, 'messageId');
    if (!messageValidation.isValid) {
      return Result.failure(messageValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteMessage(
        params['channelId'] as String,
        params['messageId'] as String,
      );
    } catch (e) {
      return Result.failure('删除消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 查找操作 ============

  /// 通用频道查找
  ///
  /// [params] 参数:
  /// - `field`: 查找字段 (id/title/...)
  /// - `value`: 查找值
  /// - `fuzzy`: 是否模糊匹配
  /// - `findAll`: 是否返回所有匹配项
  Future<Result<dynamic>> findChannelBy(Map<String, dynamic> params) async {
    final field = params['field'] as String?;
    final value = params['value'] as String?;

    if (field == null || value == null) {
      return Result.failure('缺少必需参数: field, value',
          code: ErrorCodes.invalidParams);
    }

    try {
      final fuzzy = params['fuzzy'] as bool? ?? false;
      final findAll = params['findAll'] as bool? ?? false;
      final pagination = _extractPagination(params);

      final query = ChannelQuery(
        field: field,
        value: value,
        fuzzy: fuzzy,
        findAll: findAll,
        pagination: pagination,
      );

      final result = await repository.findChannels(query);

      return result.map((channels) {
        if (!findAll && channels.isNotEmpty) {
          return channels.first.toJson();
        }

        final jsonList = channels.map((c) => c.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList,
              offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('查找频道失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 按 ID 查找频道
  Future<Result<Map<String, dynamic>?>> findChannelById(
    Map<String, dynamic> params,
  ) async {
    final idValidation = ParamValidator.requireString(params, 'channelId');
    if (!idValidation.isValid) {
      return Result.failure(idValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    try {
      final result =
          await repository.getChannelById(params['channelId'] as String);
      return result.map((c) => c?.toJson());
    } catch (e) {
      return Result.failure('查找频道失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 按标题查找频道
  Future<Result<dynamic>> findChannelByTitle(
      Map<String, dynamic> params) async {
    final titleValidation = ParamValidator.requireString(params, 'title');
    if (!titleValidation.isValid) {
      return Result.failure(titleValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    final modifiedParams = Map<String, dynamic>.from(params);
    modifiedParams['field'] = 'title';
    modifiedParams['value'] = params['title'];

    return findChannelBy(modifiedParams);
  }

  /// 通用消息查找
  Future<Result<dynamic>> findMessageBy(Map<String, dynamic> params) async {
    final channelValidation = ParamValidator.requireString(params, 'channelId');
    if (!channelValidation.isValid) {
      return Result.failure(channelValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    final field = params['field'] as String?;
    final value = params['value'] as String?;

    if (field == null || value == null) {
      return Result.failure('缺少必需参数: field, value',
          code: ErrorCodes.invalidParams);
    }

    try {
      final fuzzy = params['fuzzy'] as bool? ?? false;
      final findAll = params['findAll'] as bool? ?? false;
      final pagination = _extractPagination(params);

      final query = MessageQuery(
        channelId: params['channelId'] as String,
        field: field,
        value: value,
        fuzzy: fuzzy,
        findAll: findAll,
        pagination: pagination,
      );

      final result = await repository.findMessages(query);

      return result.map((messages) {
        if (!findAll && messages.isNotEmpty) {
          return messages.first.toJson();
        }

        final jsonList = messages.map((m) => m.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList,
              offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('查找消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 按 ID 查找消息
  Future<Result<Map<String, dynamic>?>> findMessageById(
    Map<String, dynamic> params,
  ) async {
    final channelValidation = ParamValidator.requireString(params, 'channelId');
    if (!channelValidation.isValid) {
      return Result.failure(channelValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    final messageValidation = ParamValidator.requireString(params, 'messageId');
    if (!messageValidation.isValid) {
      return Result.failure(messageValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    final modifiedParams = Map<String, dynamic>.from(params);
    modifiedParams['field'] = 'id';
    modifiedParams['value'] = params['messageId'];
    modifiedParams['findAll'] = false;

    final result = await findMessageBy(modifiedParams);
    return result.map((data) {
      if (data is Map<String, dynamic>) return data;
      return null;
    });
  }

  /// 按内容查找消息
  Future<Result<dynamic>> findMessageByContent(
      Map<String, dynamic> params) async {
    final contentValidation = ParamValidator.requireString(params, 'content');
    if (!contentValidation.isValid) {
      return Result.failure(contentValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    final modifiedParams = Map<String, dynamic>.from(params);
    modifiedParams['field'] = 'content';
    modifiedParams['value'] = params['content'];

    return findMessageBy(modifiedParams);
  }

  /// 查找频道（别名方法，用于 HTTP 路由）
  ///
  /// 与 findChannelBy 相同，但方法名更符合 REST 风格
  Future<Result<dynamic>> findChannels(Map<String, dynamic> params) async {
    return findChannelBy(params);
  }

  /// 查找消息（别名方法，用于 HTTP 路由）
  ///
  /// 与 findMessageBy 相同，但方法名更符合 REST 风格
  /// 注意：channelId 可选，如果不提供则在所有频道中搜索
  Future<Result<dynamic>> findMessages(Map<String, dynamic> params) async {
    // 如果没有提供 channelId，需要在所有频道中搜索
    if (params['channelId'] == null) {
      return _findMessagesInAllChannels(params);
    }
    return findMessageBy(params);
  }

  /// 在所有频道中查找消息
  Future<Result<dynamic>> _findMessagesInAllChannels(
      Map<String, dynamic> params) async {
    final field = params['field'] as String?;
    final value = params['value'] as String?;

    if (field == null || value == null) {
      return Result.failure('缺少必需参数: field, value',
          code: ErrorCodes.invalidParams);
    }

    try {
      final fuzzy = params['fuzzy'] as bool? ?? false;
      final findAll = params['findAll'] as bool? ?? false;
      final pagination = _extractPagination(params);

      // 获取所有频道
      final channelsResult = await repository.getChannels();
      if (channelsResult.isFailure) {
        return channelsResult;
      }

      // 在每个频道中搜索
      final allMatches = <MessageDto>[];
      for (final channel in channelsResult.dataOrNull ?? <ChannelDto>[]) {
        final query = MessageQuery(
          channelId: channel.id,
          field: field,
          value: value,
          fuzzy: fuzzy,
          findAll: true, // 在每个频道中获取所有匹配
        );

        final messagesResult = await repository.findMessages(query);
        if (messagesResult.isSuccess) {
          allMatches.addAll(messagesResult.dataOrNull ?? []);
        }
      }

      // 应用 findAll 逻辑
      if (!findAll && allMatches.isNotEmpty) {
        return Result.success(allMatches.first.toJson());
      }

      final jsonList = allMatches.map((m) => m.toJson()).toList();

      // 应用分页
      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          jsonList,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success({
          'data': paginated.data,
          'offset': paginated.offset,
          'count': paginated.count,
          'total': paginated.total,
          'hasMore': paginated.hasMore,
        });
      }

      return Result.success(jsonList);
    } catch (e) {
      return Result.failure('查找消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 用户操作 ============

  /// 获取当前用户
  Future<Result<Map<String, dynamic>>> getCurrentUser(
      Map<String, dynamic>? params) async {
    try {
      final result = await repository.getCurrentUser();
      return result.map((u) => u.toJson());
    } catch (e) {
      return Result.failure('获取当前用户失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取所有用户列表
  Future<Result<List<Map<String, dynamic>>>> getUsers(
      Map<String, dynamic>? params) async {
    try {
      final result = await repository.getUsers();
      return result.map((users) => users.map((u) => u.toJson()).toList());
    } catch (e) {
      return Result.failure('获取用户列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取 AI 用户
  Future<Result<Map<String, dynamic>?>> getAIUser() async {
    try {
      final result = await repository.getAIUser();
      return result.map((u) => u?.toJson());
    } catch (e) {
      return Result.failure('获取 AI 用户失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 辅助方法 ============

  /// 提取分页参数
  PaginationParams? _extractPagination(Map<String, dynamic> params) {
    final offset = params['offset'] as int?;
    final count = params['count'] as int?;

    if (offset == null && count == null) return null;

    return PaginationParams(
      offset: offset ?? 0,
      count: count ?? 100,
    );
  }
}

/// JSAPI 适配器 - 将 UseCase 结果转换为 JSAPI 格式
extension ChatUseCaseJsApiAdapter on ChatUseCase {
  /// 将结果转换为 JSON 字符串（用于客户端 JSAPI）
  Future<String> callAsJsApi(
    String method,
    Map<String, dynamic> params, {
    UserDto? defaultUser,
  }) async {
    final Result<dynamic> result;

    switch (method) {
      case 'getChannels':
        result = await getChannels(params);
        break;
      case 'createChannel':
        result = await createChannel(params);
        break;
      case 'deleteChannel':
        result = await deleteChannel(params);
        break;
      case 'getMessages':
        result = await getMessages(params);
        break;
      case 'sendMessage':
        result = await sendMessage(params, defaultUser: defaultUser);
        break;
      case 'deleteMessage':
        result = await deleteMessage(params);
        break;
      case 'findChannelBy':
        result = await findChannelBy(params);
        break;
      case 'findChannelById':
        result = await findChannelById(params);
        break;
      case 'findChannelByTitle':
        result = await findChannelByTitle(params);
        break;
      case 'findMessageBy':
        result = await findMessageBy(params);
        break;
      case 'findMessageById':
        result = await findMessageById(params);
        break;
      case 'findMessageByContent':
        result = await findMessageByContent(params);
        break;
      case 'getCurrentUser':
        result = await getCurrentUser(params);
        break;
      case 'getAIUser':
        result = await getAIUser();
        break;
      default:
        result = Result.failure('未知方法: $method', code: ErrorCodes.notFound);
    }

    return result.toJsonString();
  }
}
