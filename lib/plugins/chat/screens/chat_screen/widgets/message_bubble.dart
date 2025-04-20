import 'package:flutter/material.dart';
import '../../../../../plugins/chat/models/message.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../../plugins/chat/widgets/image_message_widget.dart';

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
    final isCurrentUser = message.type == MessageType.sent;

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withAlpha(25) : Colors.transparent,
          border: isSelected ? Border.all(color: Colors.blue, width: 1) : null,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisAlignment:
              isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isCurrentUser && showAvatar) ...[
              GestureDetector(
                onTap: onAvatarTap,
                child: CircleAvatar(
                  backgroundImage:
                      message.user.iconPath != null
                          ? NetworkImage(message.user.iconPath!)
                          : null,
                  child:
                      message.user.iconPath == null
                          ? Text(
                            message.user.username.isNotEmpty
                                ? message.user.username[0]
                                : '?',
                          )
                          : null,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (isCurrentUser && showAvatar) ...[
              const Spacer(),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment:
                    isCurrentUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser) // 只有非当前用户的消息才显示用户名
                    Text(
                      message.user.username,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  if (!isCurrentUser) const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isCurrentUser) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (message.fixedSymbol != null)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.amber.shade200,
                                  ),
                                ),
                                child: Text(
                                  message.fixedSymbol!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ),
                            Text(
                              _formatTime(message.date),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (message.isEdited)
                              Text(
                                '(已编辑)',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 4),
                      ],
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color:
                              isCurrentUser
                                  ? Colors.blue[100]
                                  : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [Flexible(child: _buildMessageContent())],
                        ),
                      ),
                      if (!isCurrentUser) ...[
                        const SizedBox(width: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (message.fixedSymbol != null)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.amber.shade200,
                                  ),
                                ),
                                child: Text(
                                  message.fixedSymbol!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ),
                            Text(
                              _formatTime(message.date),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (message.isEdited)
                              Text(
                                '(已编辑)',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isCurrentUser && showAvatar) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onAvatarTap,
                child: CircleAvatar(
                  backgroundImage:
                      message.user.iconPath != null
                          ? NetworkImage(message.user.iconPath!)
                          : null,
                  child:
                      message.user.iconPath == null
                          ? Text(
                            message.user.username.isNotEmpty
                                ? message.user.username[0]
                                : '?',
                          )
                          : null,
                ),
              ),
            ] else if (!isCurrentUser && !showAvatar) ...[
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMessageContent() {
    // 根据消息类型选择不同的渲染方式
    switch (message.type) {
      case MessageType.image:
        return ImageMessageWidget(
          message: message,
          isOutgoing: message.metadata?['isOutgoing'] as bool? ?? false,
        );
      case MessageType.video:
        // 如果有视频消息组件，可以在这里使用
        return MarkdownBody(
          data: message.content,
          styleSheet: MarkdownStyleSheet(p: const TextStyle(fontSize: 16)),
        );
      case MessageType.sent:
        return MarkdownBody(
          data: message.content,
          styleSheet: MarkdownStyleSheet(p: const TextStyle(fontSize: 16)),
        );
      case MessageType.received:
        return MarkdownBody(
          data: message.content,
          styleSheet: MarkdownStyleSheet(p: const TextStyle(fontSize: 16)),
        );
      default:
        return MarkdownBody(
          data: message.content,
          styleSheet: MarkdownStyleSheet(p: const TextStyle(fontSize: 16)),
        );
    }
  }
}
