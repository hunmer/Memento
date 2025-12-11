/// Chat 插件 - Repository 抽象接口
///
/// 此文件定义数据访问的抽象层，客户端和服务端各自实现
/// - 客户端：通过内存中的 Service 访问数据
/// - 服务端：通过 PluginDataService 访问加密文件

import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';

/// 频道数据传输对象
class ChannelDto {
  final String id;
  final String title;
  final int? iconCodePoint;
  final String? iconFontFamily;
  final String? backgroundColor;
  final int priority;
  final List<String> groups;
  final DateTime? lastMessageTime;
  final Map<String, dynamic>? metadata;

  const ChannelDto({
    required this.id,
    required this.title,
    this.iconCodePoint,
    this.iconFontFamily,
    this.backgroundColor,
    this.priority = 0,
    this.groups = const [],
    this.lastMessageTime,
    this.metadata,
  });

  factory ChannelDto.fromJson(Map<String, dynamic> json) {
    return ChannelDto(
      id: json['id'] as String,
      title: json['title'] as String,
      iconCodePoint: json['icon'] as int?,
      iconFontFamily: json['iconFontFamily'] as String?,
      backgroundColor: json['backgroundColor'] as String?,
      priority: json['priority'] as int? ?? 0,
      groups: (json['groups'] as List<dynamic>?)?.cast<String>() ?? [],
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.tryParse(json['lastMessageTime'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (iconCodePoint != null) 'icon': iconCodePoint,
        if (iconFontFamily != null) 'iconFontFamily': iconFontFamily,
        if (backgroundColor != null) 'backgroundColor': backgroundColor,
        'priority': priority,
        'groups': groups,
        if (lastMessageTime != null)
          'lastMessageTime': lastMessageTime!.toIso8601String(),
        if (metadata != null) 'metadata': metadata,
      };

  ChannelDto copyWith({
    String? id,
    String? title,
    int? iconCodePoint,
    String? iconFontFamily,
    String? backgroundColor,
    int? priority,
    List<String>? groups,
    DateTime? lastMessageTime,
    Map<String, dynamic>? metadata,
  }) {
    return ChannelDto(
      id: id ?? this.id,
      title: title ?? this.title,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      priority: priority ?? this.priority,
      groups: groups ?? this.groups,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 消息数据传输对象
class MessageDto {
  final String id;
  final String content;
  final String channelId;
  final UserDto user;
  final String type;
  final DateTime date;
  final String? replyToId;
  final Map<String, dynamic>? metadata;

  const MessageDto({
    required this.id,
    required this.content,
    required this.channelId,
    required this.user,
    this.type = 'sent',
    required this.date,
    this.replyToId,
    this.metadata,
  });

  factory MessageDto.fromJson(Map<String, dynamic> json) {
    return MessageDto(
      id: json['id'] as String,
      content: json['content'] as String,
      channelId: json['channelId'] as String? ?? '',
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
      type: json['type'] as String? ?? 'sent',
      date: DateTime.parse(json['date'] as String),
      replyToId: json['replyToId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'channelId': channelId,
        'user': user.toJson(),
        'type': type,
        'date': date.toIso8601String(),
        if (replyToId != null) 'replyToId': replyToId,
        if (metadata != null) 'metadata': metadata,
      };
}

/// 用户数据传输对象
class UserDto {
  final String id;
  final String name;
  final String? avatarPath;
  final bool isAI;
  final Map<String, dynamic>? metadata;

  const UserDto({
    required this.id,
    required this.name,
    this.avatarPath,
    this.isAI = false,
    this.metadata,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarPath: json['avatarPath'] as String?,
      isAI: json['isAI'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (avatarPath != null) 'avatarPath': avatarPath,
        'isAI': isAI,
        if (metadata != null) 'metadata': metadata,
      };
}

/// 查询参数
class ChannelQuery {
  final String? field;
  final String? value;
  final bool fuzzy;
  final bool findAll;
  final PaginationParams? pagination;

  const ChannelQuery({
    this.field,
    this.value,
    this.fuzzy = false,
    this.findAll = false,
    this.pagination,
  });

  factory ChannelQuery.byId(String id) => ChannelQuery(field: 'id', value: id);
  factory ChannelQuery.byTitle(String title, {bool fuzzy = false}) =>
      ChannelQuery(field: 'title', value: title, fuzzy: fuzzy);
}

class MessageQuery {
  final String channelId;
  final String? field;
  final String? value;
  final bool fuzzy;
  final bool findAll;
  final PaginationParams? pagination;

  const MessageQuery({
    required this.channelId,
    this.field,
    this.value,
    this.fuzzy = false,
    this.findAll = false,
    this.pagination,
  });
}

/// Chat Repository 抽象接口
///
/// 客户端和服务端各自实现此接口
abstract class IChatRepository {
  // ============ 频道操作 ============

  /// 获取所有频道
  Future<Result<List<ChannelDto>>> getChannels({PaginationParams? pagination});

  /// 根据 ID 获取单个频道
  Future<Result<ChannelDto?>> getChannelById(String id);

  /// 创建频道
  Future<Result<ChannelDto>> createChannel(ChannelDto channel);

  /// 更新频道
  Future<Result<ChannelDto>> updateChannel(String id, ChannelDto channel);

  /// 删除频道
  Future<Result<bool>> deleteChannel(String id);

  /// 查找频道
  Future<Result<List<ChannelDto>>> findChannels(ChannelQuery query);

  // ============ 消息操作 ============

  /// 获取频道消息
  Future<Result<List<MessageDto>>> getMessages(
    String channelId, {
    PaginationParams? pagination,
  });

  /// 发送消息
  Future<Result<MessageDto>> sendMessage(String channelId, MessageDto message);

  /// 删除消息
  Future<Result<bool>> deleteMessage(String channelId, String messageId);

  /// 查找消息
  Future<Result<List<MessageDto>>> findMessages(MessageQuery query);

  // ============ 用户操作 ============

  /// 获取当前用户
  Future<Result<UserDto>> getCurrentUser();

  /// 获取 AI 用户
  Future<Result<UserDto?>> getAIUser();

  /// 获取所有用户
  Future<Result<List<UserDto>>> getUsers();
}
