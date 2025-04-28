import 'dart:async';
import 'dart:io';
import 'package:Memento/core/event/event.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../../../plugins/chat/models/message.dart';
import '../../../../../plugins/chat/models/file_message.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../../plugins/chat/widgets/image_message_widget.dart';
import '../../../../../widgets/file_preview/index.dart';
import 'audio_message_bubble.dart';

class MessageBubble extends StatefulWidget {
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
  final bool isHighlighted;
  final Function(String)? onReplyTap; // 添加回复消息点击回调

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
    this.isHighlighted = false,
    this.onReplyTap,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  Message? replyMessage;
  late String _messageUpdateSubscriptionId;

  @override
  void initState() {
    super.initState();
    _loadReplyMessage();
    // 订阅消息更新事件
    _messageUpdateSubscriptionId = eventManager.subscribe(
      'onMessageUpdated',
      _handleMessageUpdated,
    );
  }

  @override
  void dispose() {
    eventManager.unsubscribeById(_messageUpdateSubscriptionId);
    super.dispose();
  }

  void _handleMessageUpdated(EventArgs args) {
    if (args is! Value<Message>) return;

    final updatedMessage = args.value;
    // 如果当前消息或回复消息被更新，刷新UI
    if (updatedMessage.id == widget.message.id ||
        (widget.message.replyToId != null &&
            updatedMessage.id == widget.message.replyToId)) {
      if (mounted) {
        setState(() {
          // 强制刷新UI
        });
      }
    }
  }

  Future<String> _getAbsolutePath(String relativePath) async {
    final appDir = await getApplicationDocumentsDirectory();

    // 规范化路径，确保使用正确的路径分隔符
    String normalizedPath = relativePath.replaceFirst('./', '');
    normalizedPath = normalizedPath.replaceAll('/', path.separator);

    // 检查是否需要添加app_data前缀
    if (!normalizedPath.startsWith('app_data${path.separator}')) {
      return path.join(appDir.path, 'app_data', normalizedPath);
    }

    return path.join(appDir.path, normalizedPath);
  }

  Widget _buildDefaultAvatar() {
    return Builder(
      builder:
          (context) => Center(
            child: Text(
              widget.message.user.username.isNotEmpty
                  ? widget.message.user.username[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
    );
  }

  @override
  void didUpdateWidget(MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message.replyToId != oldWidget.message.replyToId) {
      _loadReplyMessage();
    }
  }

  Future<void> _loadReplyMessage() async {
    if (widget.message.replyToId != null) {
      final reply = ChatPlugin.instance.channelService.getMessageById(
        widget.message.replyToId!,
      );
      if (mounted && reply != null) {
        setState(() {
          replyMessage = reply;
          widget.message.replyTo = reply;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = widget.message.user.id == widget.currentUserId;

    return GestureDetector(
      onLongPress: widget.onLongPress,
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 回复引用将在气泡内部显示
          Container(
            margin: EdgeInsets.only(
              left: isCurrentUser ? 48.0 : (widget.showAvatar ? 0 : 8.0),
              right: isCurrentUser ? 8.0 : 48.0,
              top: 8.0, // 添加顶部间距
              bottom: 8.0, // 添加底部间距
            ),
            decoration: BoxDecoration(
              color:
                  widget.isHighlighted
                      ? Colors.yellow.withAlpha(50)
                      : (widget.isSelected
                          ? Colors.blue.withAlpha(25)
                          : Colors.transparent),
              border:
                  widget.isSelected
                      ? Border.all(color: Colors.blue, width: 1)
                      : (widget.isHighlighted
                          ? Border.all(color: Colors.yellow.shade700, width: 1)
                          : null),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser && widget.showAvatar) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 8.0,
                    ), // 添加顶部间距，使头像不会完全贴在顶部
                    child: GestureDetector(
                      onTap: widget.onAvatarTap,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primaryContainer,
                        ),
                        child:
                            widget.message.user.iconPath != null
                                ? FutureBuilder<String>(
                                  future: _getAbsolutePath(
                                    widget.message.user.iconPath!,
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData &&
                                        snapshot.data != null) {
                                      return ClipOval(
                                        child: Image.file(
                                          File(snapshot.data!),
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    }
                                    return _buildDefaultAvatar();
                                  },
                                )
                                : _buildDefaultAvatar(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (isCurrentUser && widget.showAvatar)
                  const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        isCurrentUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.message.user.username,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
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
                                    if (widget.message.fixedSymbol != null)
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade100,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: Colors.amber.shade200,
                                          ),
                                        ),
                                        child: Text(
                                          widget.message.fixedSymbol!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.amber.shade800,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      _formatTime(widget.message.date),
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
                                                widget.message.bubbleColor ??
                                                (isCurrentUser
                                                    ? const Color(
                                                      0xFFD6E4FF,
                                                    ) // 更深的蓝色背景，提高对比度
                                                    : Colors.grey[200]),
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
                                    if (widget.message.fixedSymbol != null)
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade100,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: Colors.amber.shade200,
                                          ),
                                        ),
                                        child: Text(
                                          widget.message.fixedSymbol!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.amber.shade800,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      _formatTime(widget.message.date),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (widget.message.isEdited)
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
                if (isCurrentUser && widget.showAvatar) ...[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 8.0,
                    ), // 添加顶部间距，使头像不会完全贴在顶部
                    child: GestureDetector(
                      onTap: widget.onAvatarTap,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primaryContainer,
                        ),
                        child:
                            widget.message.user.iconPath != null
                                ? FutureBuilder<String>(
                                  future: _getAbsolutePath(
                                    widget.message.user.iconPath!,
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData &&
                                        snapshot.data != null) {
                                      return ClipOval(
                                        child: Image.file(
                                          File(snapshot.data!),
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    }
                                    return _buildDefaultAvatar();
                                  },
                                )
                                : _buildDefaultAvatar(),
                      ),
                    ),
                  ),
                ] else if (!isCurrentUser && !widget.showAvatar) ...[
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // 判断是否应该显示背景
  bool _shouldShowBackground() {
    // 音频和图片消息不显示背景
    return widget.message.type != MessageType.audio &&
        widget.message.type != MessageType.image;
  }

  Widget _buildMessageContent(BuildContext context) {
    final isCurrentUser = widget.message.user.id == widget.currentUserId;

    // 构建回复引用组件
    Widget? replyWidget;
    if (widget.message.replyTo != null) {
      replyWidget = GestureDetector(
        onTap: () => widget.onReplyTap?.call(replyMessage!.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "${widget.message.replyTo!.user.username}: ${widget.message.replyTo!.content}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      );
    }

    // 根据消息类型选择不同的渲染方式
    Widget content = Container(); // 初始化一个空的Widget
    switch (widget.message.type) {
      case MessageType.audio:
        content = AudioMessageBubble(
          message: widget.message,
          isCurrentUser: isCurrentUser,
        );
        break;
      case MessageType.image:
        content = ImageMessageWidget(
          message: widget.message,
          isOutgoing: isCurrentUser,
        );
        break;
      case MessageType.video:
        if (widget.message.metadata?[Message.metadataKeyFileInfo] != null) {
          final fileInfo = FileMessage.fromJson(
            Map<String, dynamic>.from(
              widget.message.metadata![Message.metadataKeyFileInfo],
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
                        mimeType: fileInfo.mimeType ?? 'video/mp4',
                        fileSize: fileInfo.fileSize,
                        isVideo: true,
                      ),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.video_file,
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
          content = const Text('Invalid video message format');
        }
        break;
      case MessageType.file:
        if (widget.message.metadata?[Message.metadataKeyFileInfo] != null) {
          final fileInfo = FileMessage.fromJson(
            Map<String, dynamic>.from(
              widget.message.metadata![Message.metadataKeyFileInfo],
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
            data: widget.message.content,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(fontSize: 14),
              blockSpacing: 0,
              listIndent: 8,
            ),
          );
        }
        break;
      default:
        // case MessageType.sent:
        // case MessageType.received:
        content = MarkdownBody(
          data: widget.message.content,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(fontSize: 14),
            blockSpacing: 0,
            listIndent: 8,
          ),
        );
    }

    // 如果有回复引用，将其添加到消息内容上方
    if (widget.message.replyTo != null) {
      return DefaultTextStyle(
        style: const TextStyle(fontSize: 14, height: 1.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [replyWidget!, content],
        ),
      );
    } else {
      return DefaultTextStyle(
        style: const TextStyle(fontSize: 14, height: 1.4),
        child: content,
      );
    }
  }
}
