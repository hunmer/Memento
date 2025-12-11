/// Chat 插件 - 客户端 Repository 实现
///
/// 通过适配现有的 ChannelService 和 UserService 来实现 IChatRepository 接口
library;

import 'package:shared_models/shared_models.dart';
import 'package:Memento/plugins/chat/services/channel_service.dart';
import 'package:Memento/plugins/chat/services/user_service.dart';
import 'package:Memento/plugins/chat/models/channel.dart';
import 'package:Memento/plugins/chat/models/message.dart';
import 'package:Memento/plugins/chat/models/user.dart';
import 'package:flutter/material.dart';

/// 客户端 Chat Repository 实现
class ClientChatRepository extends IChatRepository {
  final ChannelService channelService;
  final UserService userService;
  final Color pluginColor;

  ClientChatRepository({
    required this.channelService,
    required this.userService,
    required this.pluginColor,
  });

  // ============ 频道操作 ============

  @override
  Future<Result<List<ChannelDto>>> getChannels({
    PaginationParams? pagination,
  }) async {
    try {
      final channels = channelService.channels;
      final dtos = channels.map(_channelToDto).toList();

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
      return Result.failure('获取频道失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ChannelDto?>> getChannelById(String id) async {
    try {
      final channel =
          channelService.channels.where((c) => c.id == id).firstOrNull;
      if (channel == null) {
        return Result.success(null);
      }
      return Result.success(_channelToDto(channel));
    } catch (e) {
      return Result.failure('获取频道失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ChannelDto>> createChannel(ChannelDto dto) async {
    try {
      final channel = Channel(
        id: dto.id,
        title: dto.title,
        icon:
            dto.iconCodePoint != null
                ? IconData(
                  dto.iconCodePoint!,
                  fontFamily: dto.iconFontFamily ?? 'MaterialIcons',
                )
                : Icons.chat,
        messages: [],
        backgroundColor:
            dto.backgroundColor != null
                ? Color(
                  int.parse(
                        dto.backgroundColor!.replaceFirst('#', ''),
                        radix: 16,
                      ) |
                      0xFF000000,
                )
                : pluginColor,
        priority: dto.priority,
        groups: dto.groups,
      );
      await channelService.createChannel(channel);
      return Result.success(_channelToDto(channel));
    } catch (e) {
      return Result.failure('创建频道失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ChannelDto>> updateChannel(String id, ChannelDto dto) async {
    try {
      // 获取现有频道
      final existingChannel =
          channelService.channels.where((c) => c.id == id).firstOrNull;
      if (existingChannel == null) {
        return Result.failure('频道不存在', code: ErrorCodes.notFound);
      }

      // ChannelService 没有通用的 updateChannel 方法
      // 使用现有的方法更新颜色
      if (dto.backgroundColor != null) {
        final color = Color(
          int.parse(dto.backgroundColor!.replaceFirst('#', ''), radix: 16) |
              0xFF000000,
        );
        await channelService.updateChannelColor(id, color);
      }

      // 返回更新后的 DTO（实际上只更新了颜色）
      final updatedChannel =
          channelService.channels.where((c) => c.id == id).first;
      return Result.success(_channelToDto(updatedChannel));
    } catch (e) {
      return Result.failure('更新频道失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteChannel(String id) async {
    try {
      await channelService.deleteChannel(id);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除频道失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<ChannelDto>>> findChannels(ChannelQuery query) async {
    try {
      final channels = channelService.channels;
      final matches = <Channel>[];

      for (final channel in channels) {
        bool isMatch = false;
        final channelJson = channel.toJson();

        switch (query.field) {
          case 'id':
            isMatch = channel.id == query.value;
            break;
          case 'title':
            if (query.fuzzy) {
              isMatch = channel.title.toLowerCase().contains(
                (query.value ?? '').toLowerCase(),
              );
            } else {
              isMatch = channel.title == query.value;
            }
            break;
          default:
            // 通用字段查找
            final fieldValue = channelJson[query.field]?.toString() ?? '';
            if (query.fuzzy) {
              isMatch = fieldValue.toLowerCase().contains(
                (query.value ?? '').toLowerCase(),
              );
            } else {
              isMatch = fieldValue == query.value;
            }
        }

        if (isMatch) {
          matches.add(channel);
          if (!query.findAll) break;
        }
      }

      final dtos = matches.map(_channelToDto).toList();

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
      final messages = await channelService.getChannelMessages(channelId);
      if (messages == null) {
        return Result.success([]);
      }

      final dtos = <MessageDto>[];
      for (final message in messages) {
        dtos.add(await _messageToDto(message, channelId));
      }

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
      return Result.failure('获取消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<MessageDto>> sendMessage(
    String channelId,
    MessageDto dto,
  ) async {
    try {
      // 将 DTO 转换为 Message
      final user = _dtoToUser(dto.user);
      final message = Message(
        id: dto.id,
        content: dto.content,
        user: user,
        type: MessageType.values.firstWhere(
          (t) => t.name.toLowerCase() == dto.type.toLowerCase(),
          orElse: () => MessageType.sent,
        ),
        date: dto.date,
        replyToId: dto.replyToId,
        metadata: dto.metadata,
      );

      await channelService.addMessage(channelId, message);
      return Result.success(dto);
    } catch (e) {
      return Result.failure('发送消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteMessage(String channelId, String messageId) async {
    try {
      final message = channelService.getMessageById(messageId);
      if (message == null) {
        return Result.failure('消息不存在', code: ErrorCodes.notFound);
      }

      final success = await channelService.deleteMessage(message);
      return Result.success(success);
    } catch (e) {
      return Result.failure('删除消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<MessageDto>>> findMessages(MessageQuery query) async {
    try {
      final messages = await channelService.getChannelMessages(query.channelId);
      if (messages == null) {
        return Result.success([]);
      }

      final matches = <Message>[];

      for (final message in messages) {
        bool isMatch = false;
        final messageJson = await message.toJson();

        switch (query.field) {
          case 'id':
            isMatch = message.id == query.value;
            break;
          case 'content':
            if (query.fuzzy) {
              isMatch = message.content.toLowerCase().contains(
                (query.value ?? '').toLowerCase(),
              );
            } else {
              isMatch = message.content == query.value;
            }
            break;
          default:
            // 通用字段查找
            final fieldValue = messageJson[query.field]?.toString() ?? '';
            if (query.fuzzy) {
              isMatch = fieldValue.toLowerCase().contains(
                (query.value ?? '').toLowerCase(),
              );
            } else {
              isMatch = fieldValue == query.value;
            }
        }

        if (isMatch) {
          matches.add(message);
          if (!query.findAll) break;
        }
      }

      final dtos = <MessageDto>[];
      for (final message in matches) {
        dtos.add(await _messageToDto(message, query.channelId));
      }

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
      return Result.failure('查找消息失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 用户操作 ============

  @override
  Future<Result<UserDto>> getCurrentUser() async {
    try {
      final user = userService.currentUser;
      return Result.success(_userToDto(user));
    } catch (e) {
      return Result.failure('获取当前用户失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<UserDto?>> getAIUser() async {
    try {
      // User 模型没有 isAI 字段，暂时返回 null
      // 如果需要支持 AI 用户，需要扩展 User 模型
      return Result.success(null);
    } catch (e) {
      return Result.failure('获取 AI 用户失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<UserDto>>> getUsers() async {
    try {
      final users = userService.getAllUsers();
      return Result.success(users.map(_userToDto).toList());
    } catch (e) {
      return Result.failure('获取用户列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 转换方法 ============

  ChannelDto _channelToDto(Channel channel) {
    return ChannelDto(
      id: channel.id,
      title: channel.title,
      iconCodePoint: channel.icon.codePoint,
      iconFontFamily: channel.icon.fontFamily,
      backgroundColor:
          '#${channel.backgroundColor.value.toRadixString(16).padLeft(8, '0')}',
      priority: channel.priority,
      groups: channel.groups,
      lastMessageTime: channel.lastMessageTime,
      metadata: channel.metadata,
    );
  }

  Future<MessageDto> _messageToDto(Message message, String channelId) async {
    return MessageDto(
      id: message.id,
      content: message.content,
      channelId: channelId,
      user: _userToDto(message.user),
      type: message.type.name,
      date: message.date,
      replyToId: message.replyToId,
      metadata: message.metadata,
    );
  }

  UserDto _userToDto(User user) {
    return UserDto(
      id: user.id,
      name: user.username, // User 模型使用 username
      avatarPath: user.iconPath, // User 模型使用 iconPath
      isAI: false, // User 模型没有 isAI 字段
    );
  }

  User _dtoToUser(UserDto dto) {
    return User(
      id: dto.id,
      username: dto.name, // 映射到 username
      iconPath: dto.avatarPath, // 映射到 iconPath
    );
  }
}
