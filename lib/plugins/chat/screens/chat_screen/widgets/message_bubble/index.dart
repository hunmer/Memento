import 'package:flutter/material.dart';
import '../../../../../../core/event/event.dart';
import '../../../../../../plugins/chat/chat_plugin.dart';
import '../../../../../../plugins/chat/models/message.dart';
import 'components/avatar.dart';
import 'components/favorite_icon.dart';
import 'components/fixed_symbol.dart';
import 'components/message_actions.dart';
import 'components/message_content.dart';
import 'components/message_timestamp.dart';
import 'components/reply_widget.dart';

// 获取ChatPlugin单例实例
final chatPlugin = ChatPlugin.instance;

// 定义回复消息加载状态
enum ReplyLoadingState {
  initial,
  loading,
  loaded,
  error
}

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
  final VoidCallback? onToggleFavorite;

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
    this.onToggleFavorite,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  Message? replyMessage;
  late String _messageUpdateSubscriptionId;
  // 保存当前消息的副本，以便在更新时替换
  late Message _currentMessage;
  String? _currentReplyToId;
  ReplyLoadingState _replyLoadingState = ReplyLoadingState.initial;
  
  @override
  void initState() {
    super.initState();
    // 初始化当前消息为widget传入的消息
    _currentMessage = widget.message;
    _currentReplyToId = widget.message.replyToId;
    _loadReplyMessage();
    _messageUpdateSubscriptionId = eventManager.subscribe(
      'onMessageUpdated',
      _handleMessageUpdated,
    );
  }

  @override
  void didUpdateWidget(MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当widget更新时，检查消息是否发生变化
    if (widget.message != oldWidget.message || 
        widget.message.replyToId != _currentReplyToId) {
      _currentMessage = widget.message;
      _currentReplyToId = widget.message.replyToId;
      _loadReplyMessage(); // 重新加载回复消息
    }
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
    final updatedMessage = args.value1;
    
    if (!mounted) return;

    if (updatedMessage.id == _currentMessage.id) {
      // 更新当前消息对象为最新的updatedMessage
      setState(() {
        final oldReplyToId = _currentMessage.replyToId;
        _currentMessage = updatedMessage;
        _currentReplyToId = updatedMessage.replyToId;
        
        // 只有当replyToId发生变化时才重新加载回复消息
        if (oldReplyToId != updatedMessage.replyToId) {
          _loadReplyMessage();
        }
      });
    } else if (_currentReplyToId != null && 
               updatedMessage.id == _currentReplyToId &&
               replyMessage?.id == updatedMessage.id) {
      // 只更新当前正在显示的回复消息
      setState(() {
        replyMessage = updatedMessage;
      });
    }
  }

  Future<void> _loadReplyMessage() async {
    if (!mounted) return;

    // 如果没有回复ID，直接清除状态
    if (_currentMessage.replyToId == null) {
      setState(() {
        replyMessage = null;
        _replyLoadingState = ReplyLoadingState.initial;
        _currentReplyToId = null;
      });
      return;
    }

    // 设置加载状态
    setState(() {
      _replyLoadingState = ReplyLoadingState.loading;
    });

    try {
      final replyToId = _currentMessage.replyToId!;
      final reply = await chatPlugin.getMessage(replyToId);
      
      // 确保在异步操作完成后组件仍然挂载且消息ID匹配
      if (!mounted || _currentMessage.replyToId != replyToId) {
        return;
      }

      setState(() {
        if (reply != null) {
          replyMessage = reply;
          _currentReplyToId = replyToId;
          _replyLoadingState = ReplyLoadingState.loaded;
        } else {
          replyMessage = null;
          _replyLoadingState = ReplyLoadingState.error;
        }
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        replyMessage = null;
        _replyLoadingState = ReplyLoadingState.error;
      });
    }
  }

  bool get _isCurrentUser => _currentMessage.user.id == widget.currentUserId;
  
  bool _isImageMessage() {
    final metadata = _currentMessage.metadata;
    if (metadata == null || !metadata.containsKey(Message.metadataKeyFileInfo)) {
      return false;
    }
    final fileInfo = metadata[Message.metadataKeyFileInfo] as Map<String, dynamic>;
    return fileInfo['type'] == 'image';
  }

  Color _getBackgroundColor(BuildContext context) {
    // 优先使用消息的自定义气泡颜色
    if (_currentMessage.bubbleColor != null) {
      return _currentMessage.bubbleColor!;
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
        : Theme.of(context).colorScheme.surfaceContainerHighest;
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
                user: _currentMessage.user,
                onTap: widget.onAvatarTap,
              )
            else if (!_isCurrentUser && !widget.showAvatar)
              const SizedBox(width: 0),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: _isCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: _isImageMessage() ? EdgeInsets.zero : const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: _isImageMessage() ? Colors.transparent : backgroundColor,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_isCurrentUser)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              _currentMessage.user.username,
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
                          message: _currentMessage,
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
                      if (_currentMessage.fixedSymbol != null)
                        FixedSymbolWidget(symbol: _currentMessage.fixedSymbol!),
                      if (widget.onToggleFavorite != null && _currentMessage.metadata?['isFavorite'] == true)
                        FavoriteIcon(
                          isFavorite: true,
                          onTap: widget.onToggleFavorite!,
                        ),
                      const SizedBox(width: 5),
                      MessageTimestamp(
                        date: _currentMessage.updatedAt ?? _currentMessage.createdAt,
                        isEdited: _currentMessage.updatedAt != null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (_isCurrentUser && widget.showAvatar)
              MessageAvatar(
                user: _currentMessage.user,
                onTap: widget.onAvatarTap,
              )
            else if (_isCurrentUser && !widget.showAvatar)
              const SizedBox(width: 0),
          ],
        ),
      ),
    );
  }
}