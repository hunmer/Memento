import 'package:flutter/material.dart';
import '../../../../../../core/event/event.dart';
import '../../../../../../plugins/chat/chat_plugin.dart';
import '../../../../../../plugins/chat/models/message.dart';
import 'components/avatar.dart';
import 'components/fixed_symbol.dart';
import 'components/message_actions.dart';
import 'components/message_content.dart';
import 'components/message_timestamp.dart';
import 'components/reply_widget.dart';

// 获取ChatPlugin单例实例
final chatPlugin = ChatPlugin.instance;

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
  final Function(String)? onReplyTap;

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
     if (args is! Values<Message, String>) {
      return;
    }
    // if (args is! Value<Message>) return;

    final updatedMessage = args.value1 as Message;
    if (updatedMessage.id == widget.message.id ||
        (widget.message.replyToId != null &&
            updatedMessage.id == widget.message.replyToId)) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _loadReplyMessage() async {
    if (widget.message.replyToId != null) {
      final reply = await chatPlugin.getMessage(widget.message.replyToId!);
      if (mounted) {
        setState(() {
          replyMessage = reply;
        });
      }
    }
  }

  bool get _isCurrentUser => widget.message.user.id == widget.currentUserId;

  Color _getBackgroundColor(BuildContext context) {
    // 优先使用消息的自定义气泡颜色
    if (widget.message.bubbleColor != null) {
      return widget.message.bubbleColor!;
    }
    
    // 如果没有自定义颜色，则使用默认主题颜色
    if (widget.isSelected) {
      return Theme.of(context).colorScheme.primaryContainer;
    }
    if (widget.isHighlighted) {
      return Theme.of(context).colorScheme.tertiaryContainer;
    }
    return _isCurrentUser
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surfaceVariant;
  }

  Color _getTextColor(BuildContext context) {
    if (widget.isSelected) {
      return Theme.of(context).colorScheme.onPrimaryContainer;
    }
    if (widget.isHighlighted) {
      return Theme.of(context).colorScheme.onTertiaryContainer;
    }
    return _isCurrentUser
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Theme.of(context).colorScheme.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor(context);
    final textColor = _getTextColor(context);

    return GestureDetector(
      onLongPress: widget.isMultiSelectMode ? null : widget.onLongPress,
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
              _isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!_isCurrentUser && widget.showAvatar)
              MessageAvatar(
                user: widget.message.user,
                onTap: widget.onAvatarTap,
              )
            else
              const SizedBox(width: 40),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: _isCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_isCurrentUser)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              widget.message.user.username,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        if (replyMessage != null && widget.onReplyTap != null)
                          ReplyWidget(
                            replyMessage: replyMessage!,
                            onTap: widget.onReplyTap!,
                          ),
                        MessageContent(
                          message: widget.message,
                          textColor: textColor,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_isCurrentUser)
                        MessageActions(
                          onEdit: widget.onEdit,
                          onDelete: widget.onDelete,
                          onCopy: widget.onCopy,
                          onSetFixedSymbol: widget.onSetFixedSymbol,
                        ),
                      if (widget.message.fixedSymbol != null)
                        FixedSymbolWidget(symbol: widget.message.fixedSymbol!),
                      const SizedBox(width: 5),
                      MessageTimestamp(
                        date: widget.message.updatedAt ?? widget.message.createdAt,
                        isEdited: widget.message.updatedAt != null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (_isCurrentUser && widget.showAvatar)
              MessageAvatar(
                user: widget.message.user,
                onTap: widget.onAvatarTap,
              )
            else
              const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }
}