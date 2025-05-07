import 'package:flutter/material.dart';
import '../../../models/message.dart';
import '../../../models/file_message.dart';
import '../../../utils/message_options_handler.dart';
import 'message_bubble.dart';
import '../widgets/date_separator.dart';
import '../../../utils/date_formatter.dart';
import '../../../../../widgets/file_preview/index.dart';

class MessageList extends StatelessWidget {
  final List<dynamic> items;
  final bool isMultiSelectMode;
  final Set<String> selectedMessageIds;
  final void Function(Message) onMessageEdit;
  final Future<void> Function(Message) onMessageDelete;
  final void Function(Message) onMessageCopy;
  final void Function(Message, String?) onSetFixedSymbol;
  final void Function(Message, Color?) onSetBubbleColor;
  final void Function(Message) onReply; // 添加回复消息回调
  final void Function(Message) onToggleFavorite; // 添加收藏消息回调
  final void Function(String) onToggleMessageSelection;
  final void Function(String) onReplyTap; // 添加回复消息点击回调
  final ScrollController scrollController;
  final void Function(Message)? onAvatarTap;
  final bool showAvatar;
  final String? currentUserId;
  final Message? highlightedMessage;
  final bool shouldHighlight;

  const MessageList({
    super.key,
    required this.items,
    required this.isMultiSelectMode,
    required this.selectedMessageIds,
    this.onAvatarTap,
    this.showAvatar = true,
    required this.onMessageEdit,
    required this.onMessageDelete,
    required this.onMessageCopy,
    required this.onSetFixedSymbol,
    required this.onSetBubbleColor,
    required this.onReply,
    required this.onToggleFavorite,
    required this.onToggleMessageSelection,
    required this.onReplyTap,
    required this.scrollController,
    this.currentUserId,
    this.highlightedMessage,
    this.shouldHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      reverse: true,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final nextItem = index > 0 ? items[index - 1] : null;

        // 处理日期分隔符
        Widget? dateSeparator;
        if (item is DateTime) {
          // 如果项目本身是日期，直接显示日期分隔符
          return DateSeparator(date: item);
        } else if (item is Message &&
            nextItem is Message &&
            _shouldShowDateSeparator(item, nextItem)) {
          // 如果当前消息和下一条消息不是同一天，显示日期分隔符
          dateSeparator = DateSeparator(date: item.date);
        }

        if (item is Message) {
          return Column(
            children: [
              if (dateSeparator != null) dateSeparator,
              GestureDetector(
                onLongPress: () {
                  // 使用统一的消息选项处理器
                  MessageOptionsHandler.showOptionsDialog(
                    context: context,
                    message: item,
                    onMessageEdit: onMessageEdit,
                    onMessageDelete: onMessageDelete,
                    onMessageCopy: onMessageCopy,
                    onSetFixedSymbol: onSetFixedSymbol,
                    onSetBubbleColor: onSetBubbleColor,
                    onReply: onReply,
                    onToggleFavorite: onToggleFavorite,
                  );
                },
                onDoubleTap: () {
                  // 使用统一的消息选项处理器，直接显示固态符号编辑对话框
                  MessageOptionsHandler.showOptionsDialog(
                    context: context,
                    message: item,
                    onMessageEdit: onMessageEdit,
                    onMessageDelete: onMessageDelete,
                    onMessageCopy: onMessageCopy,
                    onSetFixedSymbol: onSetFixedSymbol,
                    onSetBubbleColor: onSetBubbleColor,
                    onReply: onReply,
                    onToggleFavorite: onToggleFavorite,
                    initiallyShowFixedSymbolDialog: true, // 直接显示固态符号编辑对话框
                  );
                },
                child: MessageBubble(
                  message: item,
                  isSelected: selectedMessageIds.contains(item.id),
                  isMultiSelectMode: isMultiSelectMode,
                  onEdit: () => onMessageEdit(item),
                  onDelete: () => onMessageDelete(item),
                  onCopy: () => onMessageCopy(item),
                  onSetFixedSymbol: (symbol) => onSetFixedSymbol(item, symbol),
                  onLongPress: null, // 移除重复的长按处理
                  onTap:
                      isMultiSelectMode
                          ? () => onToggleMessageSelection(item.id)
                          : () {
                            if ((item.type == MessageType.file ||
                                    item.type == MessageType.video ||
                                    item.type == MessageType.image) &&
                                item.metadata != null &&
                                item.metadata![Message.metadataKeyFileInfo] !=
                                    null) {
                              try {
                                final fileInfo = FileMessage.fromJson(
                                  Map<String, dynamic>.from(
                                    item.metadata![Message.metadataKeyFileInfo],
                                  ),
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => FilePreviewScreen(
                                          filePath: fileInfo.filePath,
                                          fileName: fileInfo.fileName,
                                          mimeType:
                                              fileInfo.mimeType ??
                                              'application/octet-stream',
                                          fileSize: fileInfo.fileSize,
                                        ),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('无法打开文件: $e')),
                                );
                              }
                            }
                          },
                  onAvatarTap:
                      onAvatarTap != null ? () => onAvatarTap!(item) : null,
                  showAvatar: showAvatar,
                  currentUserId: currentUserId ?? '',
                  isHighlighted:
                      shouldHighlight &&
                      highlightedMessage != null &&
                      item.id == highlightedMessage?.id,
                  onToggleFavorite: () => onToggleFavorite(item),
                  onReplyTap: onReplyTap,
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  bool _shouldShowDateSeparator(Message currentMessage, Message nextMessage) {
    return !DateFormatter.isSameDay(currentMessage.date, nextMessage.date);
  }
}
