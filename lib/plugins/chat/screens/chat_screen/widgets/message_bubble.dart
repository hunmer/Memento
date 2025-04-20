import 'package:flutter/material.dart';
import '../../../../../plugins/chat/models/message.dart';
import '../../../../../plugins/chat/models/file_message.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../../plugins/chat/widgets/image_message_widget.dart';
import '../../../../../widgets/file_preview/index.dart';
import 'audio_message_bubble.dart';

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
  final String currentUserId;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSelected,
    required this.isMultiSelectMode,
    required this.onEdit,
    required this.onDelete,
    required this.onCopy,
    required this.onSetFixedSymbol,
    required this.currentUserId,
    this.onLongPress,
    this.onTap,
    this.onAvatarTap,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = message.user.id == currentUserId;

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
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
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
            if (isCurrentUser && showAvatar) const SizedBox(width: 8),
            Expanded(
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (isCurrentUser) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
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
                              maxWidth: constraints.maxWidth * 0.7,
                              minWidth: 0,
                            ),
                            child:
                                _shouldShowBackground()
                                    ? Container(
                                      padding: const EdgeInsets.all(10.0),
                                      decoration: BoxDecoration(
                                        color:
                                            isCurrentUser
                                                ? const Color(
                                                  0xFFD6E4FF,
                                                ) // 更深的蓝色背景，提高对比度
                                                : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(
                                          12.0,
                                        ),
                                      ),
                                      child: _buildMessageContent(context),
                                    )
                                    : _buildMessageContent(context),
                          ),
                          if (!isCurrentUser) ...[
                            const SizedBox(width: 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
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
                      );
                    },
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

  // 判断是否应该显示背景
  bool _shouldShowBackground() {
    // 音频和图片消息不显示背景
    return message.type != MessageType.audio &&
        message.type != MessageType.image;
  }

  Widget _buildMessageContent(BuildContext context) {
    final isCurrentUser = message.user.id == currentUserId;

    // 根据消息类型选择不同的渲染方式
    Widget content;
    switch (message.type) {
      case MessageType.audio:
        content = AudioMessageBubble(
          message: message,
          isCurrentUser: isCurrentUser,
        );
        break;
      case MessageType.image:
        content = ImageMessageWidget(
          message: message,
          isOutgoing: isCurrentUser,
        );
        break;
      case MessageType.video:
      case MessageType.file:
        if (message.metadata?[Message.metadataKeyFileInfo] != null) {
          final fileInfo = FileMessage.fromJson(
            Map<String, dynamic>.from(
              message.metadata![Message.metadataKeyFileInfo],
            ),
          );
          content = GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (BuildContext ctx) => FilePreviewScreen(
                        filePath: fileInfo.filePath,
                        fileName: fileInfo.fileName,
                        mimeType:
                            fileInfo.mimeType ?? 'application/octet-stream',
                        fileSize: fileInfo.fileSize,
                      ),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  fileInfo.getIcon(),
                  size: 24,
                  color: isCurrentUser ? Colors.blue[900] : Colors.grey[800],
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fileInfo.originalFileName,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color:
                              isCurrentUser ? Colors.blue[900] : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        fileInfo.formattedSize,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isCurrentUser
                                  ? Colors.blue[700]
                                  : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          content = MarkdownBody(
            data: message.content,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(fontSize: 14),
              blockSpacing: 0,
              listIndent: 8,
            ),
          );
        }
        break;
      case MessageType.sent:
      case MessageType.received:
      default:
        content = MarkdownBody(
          data: message.content,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(fontSize: 14),
            blockSpacing: 0,
            listIndent: 8,
          ),
        );
    }

    return DefaultTextStyle(
      style: const TextStyle(fontSize: 14, height: 1.4),
      child: content,
    );
  }
}
