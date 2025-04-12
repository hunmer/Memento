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
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final VoidCallback? onAvatarTap;
  final bool showAvatar;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSelected,
    required this.isMultiSelectMode,
    required this.onEdit,
    required this.onDelete,
    required this.onCopy,
    required this.onSetFixedSymbol,
    this.onLongPress,
    this.onTap,
    this.onAvatarTap,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = message.user.id == 'current_user_id'; // 替换为实际逻辑
    
    return GestureDetector(
      onLongPress: onLongPress,  // 现在可以为null
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
            if (!isCurrentUser && showAvatar)
              GestureDetector(
                onTap: onAvatarTap,
                child: CircleAvatar(
                  backgroundImage: message.user.iconPath != null
                      ? NetworkImage(message.user.iconPath!)
                      : null,
                  child: message.user.iconPath == null
                      ? Text(message.user.username.isNotEmpty
                          ? message.user.username[0]
                          : '?')
                      : null,
                ),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: MarkdownBody(
                            data: message.content,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isCurrentUser && message.fixedSymbol != null)
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Text(
                            message.fixedSymbol!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ),
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
                      if (isCurrentUser && message.fixedSymbol != null)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Text(
                            message.fixedSymbol!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade800,
                            ),
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
                  PopupMenuItem(
                    value: 'pin',
                    child: Row(
                      children: [
                        const Text('设置固定字符'),
                        const SizedBox(width: 8),
                        if (message.fixedSymbol != null)
                          Text(
                            '(${message.fixedSymbol})',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (message.fixedSymbol != null)
                    const PopupMenuItem(
                      value: 'unpin',
                      child: Text('取消固定字符'),
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
                      // 弹出对话框让用户输入固定字符
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('设置固定字符'),
                          content: TextField(
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: '请输入固定字符',
                            ),
                            onSubmitted: (value) {
                              onSetFixedSymbol(value.isEmpty ? null : value);
                              Navigator.of(context).pop();
                            },
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () {
                                // 获取当前对话框中的文本字段值
                                final TextEditingController? controller = 
                                    (context.findAncestorWidgetOfExactType<TextField>())?.controller;
                                if (controller != null) {
                                  final text = controller.text;
                                  onSetFixedSymbol(text.isEmpty ? null : text);
                                }
                                Navigator.of(context).pop();
                              },
                              child: const Text('确定'),
                            ),
                          ],
                        ),
                      );
                      break;
                    case 'unpin':
                      onSetFixedSymbol(null);
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