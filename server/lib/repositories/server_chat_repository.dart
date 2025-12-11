/// Chat 插件 - 服务端 Repository 实现
///
/// 通过 PluginDataService 访问用户的加密数据文件

import 'package:shared_models/shared_models.dart';

import '../services/plugin_data_service.dart';

/// 服务端 Chat Repository 实现
class ServerChatRepository extends IChatRepository {
  final PluginDataService dataService;
  final String userId;

  static const String _pluginId = 'chat';

  ServerChatRepository({
    required this.dataService,
    required this.userId,
  });

  // ============ 频道操作 ============

  @override
  Future<Result<List<ChannelDto>>> getChannels({
    PaginationParams? pagination,
  }) async {
    try {
      // 读取频道 ID 列表
      final channelsListData = await dataService.readPluginData(
        userId,
        _pluginId,
        'channels.json',
      );

      if (channelsListData == null) {
        return Result.success([]);
      }

      final channelIds = (channelsListData['channels'] as List<dynamic>?)
              ?.cast<String>() ??
          [];

      // 读取每个频道的详细信息
      final channels = <ChannelDto>[];
      for (final channelId in channelIds) {
        final channelData = await dataService.readPluginData(
          userId,
          _pluginId,
          'channel/$channelId.json',
        );
        if (channelData != null && channelData.containsKey('channel')) {
          channels.add(ChannelDto.fromJson(
            channelData['channel'] as Map<String, dynamic>,
          ));
        }
      }

      // 应用分页
      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          channels,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(channels);
    } catch (e) {
      return Result.failure('获取频道失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ChannelDto?>> getChannelById(String id) async {
    try {
      final channelData = await dataService.readPluginData(
        userId,
        _pluginId,
        'channel/$id.json',
      );

      if (channelData == null || !channelData.containsKey('channel')) {
        return Result.success(null);
      }

      return Result.success(ChannelDto.fromJson(
        channelData['channel'] as Map<String, dynamic>,
      ));
    } catch (e) {
      return Result.failure('获取频道失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ChannelDto>> createChannel(ChannelDto dto) async {
    try {
      // 保存频道信息
      await dataService.writePluginData(
        userId,
        _pluginId,
        'channel/${dto.id}.json',
        {'channel': dto.toJson()},
      );

      // 创建空消息列表
      await dataService.writePluginData(
        userId,
        _pluginId,
        'messages/${dto.id}.json',
        {'messages': []},
      );

      // 更新频道 ID 列表
      final channelsListData = await dataService.readPluginData(
        userId,
        _pluginId,
        'channels.json',
      );

      final channelIds = (channelsListData?['channels'] as List<dynamic>?)
              ?.cast<String>()
              .toList() ??
          <String>[];

      if (!channelIds.contains(dto.id)) {
        channelIds.add(dto.id);
        await dataService.writePluginData(
          userId,
          _pluginId,
          'channels.json',
          {'channels': channelIds},
        );
      }

      return Result.success(dto);
    } catch (e) {
      return Result.failure('创建频道失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ChannelDto>> updateChannel(String id, ChannelDto dto) async {
    try {
      // 读取现有频道
      final channelData = await dataService.readPluginData(
        userId,
        _pluginId,
        'channel/$id.json',
      );

      if (channelData == null || !channelData.containsKey('channel')) {
        return Result.failure('频道不存在', code: ErrorCodes.notFound);
      }

      // 保存更新
      await dataService.writePluginData(
        userId,
        _pluginId,
        'channel/$id.json',
        {'channel': dto.toJson()},
      );

      return Result.success(dto);
    } catch (e) {
      return Result.failure('更新频道失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteChannel(String id) async {
    try {
      // 删除频道文件
      await dataService.deletePluginFile(userId, _pluginId, 'channel/$id.json');

      // 删除消息文件
      await dataService.deletePluginFile(userId, _pluginId, 'messages/$id.json');

      // 从频道列表中移除
      final channelsListData = await dataService.readPluginData(
        userId,
        _pluginId,
        'channels.json',
      );

      if (channelsListData != null) {
        final channelIds = (channelsListData['channels'] as List<dynamic>?)
                ?.cast<String>()
                .toList() ??
            <String>[];

        channelIds.remove(id);
        await dataService.writePluginData(
          userId,
          _pluginId,
          'channels.json',
          {'channels': channelIds},
        );
      }

      return Result.success(true);
    } catch (e) {
      return Result.failure('删除频道失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<ChannelDto>>> findChannels(ChannelQuery query) async {
    try {
      // 获取所有频道
      final channelsResult = await getChannels();
      if (channelsResult.isFailure) {
        return channelsResult;
      }

      final channels = channelsResult.dataOrNull ?? [];

      // 过滤匹配的频道
      final matches = channels.where((channel) {
        final json = channel.toJson();
        final fieldValue = json[query.field]?.toString() ?? '';

        if (query.fuzzy) {
          return fieldValue.toLowerCase().contains(
                (query.value ?? '').toLowerCase(),
              );
        }
        return fieldValue == query.value;
      }).toList();

      // 如果不是 findAll，只返回第一个
      if (!query.findAll && matches.isNotEmpty) {
        return Result.success([matches.first]);
      }

      // 应用分页
      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          matches,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(matches);
    } catch (e) {
      return Result.failure('查找频道失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 消息操作 ============

  @override
  Future<Result<List<MessageDto>>> getMessages(
    String channelId, {
    PaginationParams? pagination,
  }) async {
    try {
      final messagesData = await dataService.readPluginData(
        userId,
        _pluginId,
        'messages/$channelId.json',
      );

      if (messagesData == null) {
        return Result.success([]);
      }

      final messagesList = (messagesData['messages'] as List<dynamic>?) ?? [];
      final messages = messagesList
          .map((m) => MessageDto.fromJson(m as Map<String, dynamic>))
          .toList();

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
      return Result.failure('获取消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<MessageDto>> sendMessage(
    String channelId,
    MessageDto dto,
  ) async {
    try {
      // 读取现有消息
      final messagesData = await dataService.readPluginData(
        userId,
        _pluginId,
        'messages/$channelId.json',
      );

      final messages = (messagesData?['messages'] as List<dynamic>?)
              ?.toList() ??
          [];

      // 添加新消息
      messages.add(dto.toJson());

      // 保存消息列表
      await dataService.writePluginData(
        userId,
        _pluginId,
        'messages/$channelId.json',
        {'messages': messages},
      );

      // 更新频道最后消息时间
      final channelData = await dataService.readPluginData(
        userId,
        _pluginId,
        'channel/$channelId.json',
      );

      if (channelData != null && channelData.containsKey('channel')) {
        final channel = Map<String, dynamic>.from(
          channelData['channel'] as Map<String, dynamic>,
        );
        channel['lastMessageTime'] = DateTime.now().toIso8601String();
        await dataService.writePluginData(
          userId,
          _pluginId,
          'channel/$channelId.json',
          {'channel': channel},
        );
      }

      return Result.success(dto);
    } catch (e) {
      return Result.failure('发送消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteMessage(String channelId, String messageId) async {
    try {
      final messagesData = await dataService.readPluginData(
        userId,
        _pluginId,
        'messages/$channelId.json',
      );

      if (messagesData == null) {
        return Result.failure('频道不存在', code: ErrorCodes.notFound);
      }

      final messages = (messagesData['messages'] as List<dynamic>?)
              ?.toList() ??
          [];

      final initialLength = messages.length;
      messages.removeWhere((m) =>
          (m as Map<String, dynamic>)['id'] == messageId);

      if (messages.length == initialLength) {
        return Result.failure('消息不存在', code: ErrorCodes.notFound);
      }

      await dataService.writePluginData(
        userId,
        _pluginId,
        'messages/$channelId.json',
        {'messages': messages},
      );

      return Result.success(true);
    } catch (e) {
      return Result.failure('删除消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<MessageDto>>> findMessages(MessageQuery query) async {
    try {
      // 获取频道的所有消息
      final messagesResult = await getMessages(query.channelId);
      if (messagesResult.isFailure) {
        return messagesResult;
      }

      final messages = messagesResult.dataOrNull ?? [];

      // 过滤匹配的消息
      final matches = messages.where((message) {
        final json = message.toJson();
        final fieldValue = json[query.field]?.toString() ?? '';

        if (query.fuzzy) {
          return fieldValue.toLowerCase().contains(
                (query.value ?? '').toLowerCase(),
              );
        }
        return fieldValue == query.value;
      }).toList();

      // 如果不是 findAll，只返回第一个
      if (!query.findAll && matches.isNotEmpty) {
        return Result.success([matches.first]);
      }

      // 应用分页
      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          matches,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(matches);
    } catch (e) {
      return Result.failure('查找消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 用户操作 ============

  @override
  Future<Result<UserDto>> getCurrentUser() async {
    try {
      final usersData = await dataService.readPluginData(
        userId,
        _pluginId,
        'users.json',
      );

      final users = (usersData?['users'] as List<dynamic>?) ?? [];
      if (users.isEmpty) {
        // 返回默认用户
        return Result.success(UserDto(
          id: 'default_user',
          name: '用户',
          isAI: false,
        ));
      }

      final currentUser = users.firstWhere(
        (u) => (u as Map<String, dynamic>)['isAI'] != true,
        orElse: () => users.first,
      ) as Map<String, dynamic>;

      return Result.success(UserDto.fromJson(currentUser));
    } catch (e) {
      return Result.failure('获取当前用户失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<UserDto?>> getAIUser() async {
    try {
      final usersData = await dataService.readPluginData(
        userId,
        _pluginId,
        'users.json',
      );

      final users = (usersData?['users'] as List<dynamic>?) ?? [];

      final aiUser = users.where(
        (u) => (u as Map<String, dynamic>)['isAI'] == true,
      ).firstOrNull;

      if (aiUser == null) {
        return Result.success(null);
      }

      return Result.success(UserDto.fromJson(aiUser as Map<String, dynamic>));
    } catch (e) {
      return Result.failure('获取 AI 用户失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<UserDto>>> getUsers() async {
    try {
      final usersData = await dataService.readPluginData(
        userId,
        _pluginId,
        'users.json',
      );

      final users = (usersData?['users'] as List<dynamic>?) ?? [];

      return Result.success(
        users.map((u) => UserDto.fromJson(u as Map<String, dynamic>)).toList(),
      );
    } catch (e) {
      return Result.failure('获取用户列表失败: $e', code: ErrorCodes.serverError);
    }
  }
}
