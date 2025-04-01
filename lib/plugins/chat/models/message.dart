import 'user.dart';

enum MessageType { received, sent }

class Message {
  final String content;
  final User user;
  final DateTime date;
  final MessageType type;

  Message({
    required this.content,
    required this.user,
    required this.type,
    DateTime? date,
  }) : date = date ?? DateTime.now();
}