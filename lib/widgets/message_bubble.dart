import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../utils/date_formatter.dart';
import '../screens/user_profile_screen.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final Function(Message) onEdit;
  final Function(Message) onDelete;
  final Function(Message) onCopy;

  const MessageBubble({
    super.key,
    required this.message,
    required this.onEdit,
    required this.onDelete,
    required this.onCopy,
  });

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
                GestureDetector(
                  onLongPress: () => _showMessageOptions(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.content,
                          style: TextStyle(color: textColor),
                        ),
                        if (message.isEdited)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '(已编辑)',
                              style: TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                color:
                                    isSentMessage
                                        ? Colors.white70
                                        : Colors.black54,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    DateFormatter.formatDateTime(message.date),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
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

  void _showMessageOptions(BuildContext context) {
    final isSentMessage = message.type == MessageType.sent;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('复制消息'),
                onTap: () {
                  Navigator.pop(context);
                  onCopy(message);
                },
              ),
              if (isSentMessage) // 只有发送的消息才能编辑和删除
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('编辑消息'),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit(message);
                  },
                ),
              if (isSentMessage)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    '删除消息',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete(message);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(User user) {
    Widget avatar;
    if (user.iconPath != null) {
      avatar = CircleAvatar(
        backgroundImage: AssetImage(user.iconPath!),
        radius: 16,
      );
    } else {
      avatar = CircleAvatar(radius: 16, child: Text(user.username[0]));
    }

    return Builder(
      builder:
          (context) => GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UserProfileScreen(user: user),
                ),
              );
            },
            child: avatar,
          ),
    );
  }
}
