import 'package:flutter/material.dart';
import 'channel.dart';
import 'message.dart';
import 'user.dart';

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
      'userId': message.user.id,
      'date': message.date.toIso8601String(),
      'type': message.type.toString().split('.').last,
      'editedAt': message.editedAt?.toIso8601String(),
    };
  }

  static Message fromJson(Map<String, dynamic> json, List<User> users) {
    // 查找用户
    final userId = json['userId'] as String;
    final user = users.firstWhere(
      (u) => u.id == userId,
      orElse: () => User(id: userId, username: 'Unknown User'),
    );

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
    );
  }

  // 将IconData转换为字符串
  static String _iconDataToString(IconData icon) {
    return '${icon.codePoint}:${icon.fontFamily}:${icon.fontPackage}';
  }

  // 将字符串转换为IconData
  static IconData _stringToIconData(String iconString) {
    final parts = iconString.split(':');
    return IconData(
      int.parse(parts[0]),
      fontFamily: parts[1] == 'null' ? null : parts[1],
      fontPackage: parts.length > 2 && parts[2] != 'null' ? parts[2] : null,
    );
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
