import 'package:flutter/material.dart';
import '../constants/app_icons.dart';
import '../plugins/chat/models/channel.dart';
import '../plugins/chat/models/message.dart';
import '../plugins/chat/models/user.dart';

// 使用 AppIcons 中的预定义图标映射表
final Map<String, IconData> predefinedIcons = AppIcons.predefinedIcons;

/// 用户序列化/反序列化
class UserSerializer {
  static Map<String, dynamic> toJson(User user) {
    return {
      'id': user.id,
      'username': user.username,
      'iconPath': user.iconPath,
    };
  }

  static User fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      iconPath: json['iconPath'] as String?,
    );
  }
}

/// 消息序列化/反序列化
class MessageSerializer {
  static Map<String, dynamic> toJson(Message message) {
    return {
      'id': message.id,
      'content': message.content,
      'user': UserSerializer.toJson(message.user),
      'date': message.date.toIso8601String(),
      'type': message.type.toString().split('.').last,
      'editedAt': message.editedAt?.toIso8601String(),
      'fixedSymbol': message.fixedSymbol,
      'bubbleColor': message.bubbleColor?.value, // 添加bubbleColor字段
      'metadata': message.metadata,
    };
  }

  static Message fromJson(Map<String, dynamic> json, List<User> users) {
    // 从消息中直接获取完整的用户信息
    final user = UserSerializer.fromJson(json['user'] as Map<String, dynamic>);

    return Message(
      id: json['id'] as String,
      content: json['content'] as String,
      user: user,
      type: MessageType.values.firstWhere(
        (t) => t.toString().split('.').last == json['type'],
        orElse: () => MessageType.received,
      ),
      date: DateTime.parse(json['date'] as String),
      editedAt:
          json['editedAt'] != null
              ? DateTime.parse(json['editedAt'] as String)
              : null,
      fixedSymbol: json['fixedSymbol'] as String?,
      bubbleColor: json['bubbleColor'] != null ? Color(json['bubbleColor'] as int) : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// 频道序列化/反序列化
class ChannelSerializer {
  static Map<String, dynamic> toJson(Channel channel) {
    return {
      'id': channel.id,
      'title': channel.title,
      'icon': _iconDataToString(channel.icon),
      'priority': channel.priority,
      'members': channel.members.map((u) => UserSerializer.toJson(u)).toList(),
      'groups': channel.groups,
      'backgroundColor': channel.backgroundColor.value,
      'fixedSymbol': channel.fixedSymbol,
    };
  }

  static Channel fromJson(
    Map<String, dynamic> json, {
    List<Message>? messages,
  }) {
    final List<dynamic> membersJson = json['members'] as List<dynamic>;
    final List<User> members =
        membersJson
            .map((m) => UserSerializer.fromJson(m as Map<String, dynamic>))
            .toList();

    return Channel(
      id: json['id'] as String,
      title: json['title'] as String,
      icon: _stringToIconData(json['icon'] as String),
      priority: json['priority'] as int? ?? 0,
      members: members,
      messages: messages ?? [],
      groups: (json['groups'] as List<dynamic>?)?.cast<String>() ?? [],
      backgroundColor: Color(
        json['backgroundColor'] as int? ?? Colors.blue.value,
      ),
      fixedSymbol: json['fixedSymbol'] as String?,
    );
  }

  // 将IconData转换为字符串（使用图标名称）
  static String _iconDataToString(IconData icon) {
    // 查找图标名称
    final iconName =
        predefinedIcons.entries
            .firstWhere(
              (entry) => entry.value == icon,
              orElse: () => const MapEntry('default', AppIcons.defaultIcon),
            )
            .key;
    return iconName;
  }

  // 将字符串（图标名称）转换为IconData
  static IconData _stringToIconData(String iconName) {
    return AppIcons.getIconByName(iconName);
  }
}

/// 消息列表序列化/反序列化
class MessagesSerializer {
  static Map<String, dynamic> toJson(List<Message> messages) {
    return {
      'messages': messages.map((m) => MessageSerializer.toJson(m)).toList(),
    };
  }

  static List<Message> fromJson(Map<String, dynamic> json, List<User> users) {
    final List<dynamic> messagesJson = json['messages'] as List<dynamic>;
    return messagesJson
        .map(
          (m) => MessageSerializer.fromJson(m as Map<String, dynamic>, users),
        )
        .toList();
  }
}
