import 'package:flutter/material.dart';
import '../../../../../plugins/chat/models/message.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCopy;
  final Function(String?) onSetFixedSymbol;
  final VoidCallback onLongPress;
  final VoidCallback? onTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSelected,
    required this.isMultiSelectMode,
    required this.onEdit,
    required this.onDelete,
    required this.onCopy,
    required this.onSetFixedSymbol,
    required this.onLongPress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = message.user.id == 'current_user_id'; // 替换为实际逻辑
    
    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withAlpha(25)
              : Colors.transparent,
          border: isSelected
              ? Border.all(color: Colors.blue, width: 1)
              : null,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisAlignment:
              isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isCurrentUser)
              CircleAvatar(
                backgroundImage: message.user.iconPath != null
                    ? NetworkImage(message.user.iconPath!)
                    : null,
                child: message.user.iconPath == null
                    ? Text(message.user.username.isNotEmpty
                        ? message.user.username[0]
                        : '?')
                    : null,
              ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: isCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.user.username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: isCurrentUser
                          ? Colors.blue[100]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.date),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (message.isEdited)
                        Text(
                          ' (已编辑)',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isCurrentUser && !isMultiSelectMode)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 16, color: Colors.grey[600]),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('编辑'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('删除'),
                  ),
                  const PopupMenuItem(
                    value: 'copy',
                    child: Text('复制'),
                  ),
                  const PopupMenuItem(
                    value: 'pin',
                    child: Text('置顶'),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                    case 'copy':
                      onCopy();
                      break;
                    case 'pin':
                      onSetFixedSymbol('pin');
                      break;
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}