import 'message.dart';
import 'user.dart';

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

class MessageSerializer {
  static Map<String, dynamic> toJson(Message message) {
    return {
      'id': message.id,
      'content': message.content,
      'user': UserSerializer.toJson(message.user),
      'type': message.type.toString().split('.').last,
      'date': message.date.toIso8601String(),
      'editedAt': message.editedAt?.toIso8601String(),
      'fixedSymbol': message.fixedSymbol,
      'metadata': message.metadata,
    };
  }

  static Message fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      content: json['content'] as String,
      user: UserSerializer.fromJson(json['user'] as Map<String, dynamic>),
      type: MessageType.values.firstWhere(
        (type) => type.toString().split('.').last == json['type'],
      ),
      date: DateTime.parse(json['date'] as String),
      editedAt: json['editedAt'] != null 
          ? DateTime.parse(json['editedAt'] as String)
          : null,
      fixedSymbol: json['fixedSymbol'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}