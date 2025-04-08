import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../utils/date_formatter.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isSentMessage = message.type == MessageType.sent;
    final backgroundColor =
        isSentMessage
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.shade200;
    final textColor = isSentMessage ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment:
            isSentMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSentMessage) _buildAvatar(message.user),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isSentMessage
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(color: textColor),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    DateFormatter.formatDateTime(message.date, context),
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isSentMessage) _buildAvatar(message.user),
        ],
      ),
    );
  }

  Widget _buildAvatar(User user) {
    if (user.iconPath != null) {
      return CircleAvatar(
        backgroundImage: AssetImage(user.iconPath!),
        radius: 16,
      );
    }
    return CircleAvatar(radius: 16, child: Text(user.username[0]));
  }
}