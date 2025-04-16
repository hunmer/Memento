import 'package:flutter/material.dart';
import '../plugins/chat/models/channel.dart';
import '../plugins/chat/models/message.dart';
import '../plugins/chat/models/user.dart';

// 预定义的图标映射表，使用常量构造函数
final Map<String, IconData> predefinedIcons = {
  'message': Icons.message,
  'person': Icons.person,
  'group': Icons.group,
  'star': Icons.star,
  'favorite': Icons.favorite,
  'home': Icons.home,
  'settings': Icons.settings,
  'work': Icons.work,
  'school': Icons.school,
  'event': Icons.event,
  'chat': Icons.chat,
  'chat_bubble': Icons.chat_bubble,
  'notifications': Icons.notifications,
  'people': Icons.people,
  'sports': Icons.sports,
  'music_note': Icons.music_note,
  'movie': Icons.movie,
  'book': Icons.book,
  'shopping_cart': Icons.shopping_cart,
  'email': Icons.email,
  'phone': Icons.phone,
  'camera': Icons.camera,
  'photo': Icons.photo,
  'video_camera_back': Icons.video_camera_back,
  'restaurant': Icons.restaurant,
  'local_cafe': Icons.local_cafe,
  'local_bar': Icons.local_bar,
  'local_hotel': Icons.local_hotel,
  'flight': Icons.flight,
  'directions_car': Icons.directions_car,
  'directions_bike': Icons.directions_bike,
  'pets': Icons.pets,
  'nature': Icons.nature,
  'park': Icons.park,
  'beach_access': Icons.beach_access,
  'ac_unit': Icons.ac_unit,
  'whatshot': Icons.whatshot,
  'sports_esports': Icons.sports_esports,
  'sports_basketball': Icons.sports_basketball,
  'sports_football': Icons.sports_football,
  'celebration': Icons.celebration,
  'cake': Icons.cake,
};

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
              orElse: () => const MapEntry('message', Icons.message), // 默认图标
            )
            .key;
    return iconName;
  }

  // 将字符串（图标名称）转换为IconData
  static IconData _stringToIconData(String iconName) {
    // 从预定义图标中获取，如果不存在则使用默认图标
    return predefinedIcons[iconName] ?? Icons.message;
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
