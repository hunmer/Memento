import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/plugins/chat/models/message.dart';
import 'package:Memento/plugins/chat/models/file_message.dart';
import 'package:Memento/plugins/chat/utils/message_options_handler.dart';
import 'message_bubble.dart';
import 'package:Memento/plugins/chat/screens/chat_screen/widgets/date_separator.dart';
import 'package:Memento/plugins/chat/utils/date_formatter.dart';
import 'package:Memento/widgets/file_preview/index.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class MessageList extends StatefulWidget {
  final List<dynamic> items;
  final bool isMultiSelectMode;
  final ValueNotifier<Set<String>> selectedMessageIds;
  final void Function(Message) onMessageEdit;
  final Future<void> Function(Message) onMessageDelete;
  final void Function(Message) onMessageCopy;
  final void Function(Message, String?) onSetFixedSymbol;
  final void Function(Message, Color?) onSetBubbleColor;
  final void Function(Message) onReply; // 添加回复消息回调
  final void Function(Message) onToggleFavorite; // 添加收藏消息回调
  final void Function(String) onToggleMessageSelection;
  final void Function(String) onReplyTap; // 添加回复消息点击回调
  final AutoScrollController scrollController;
  final void Function(Message)? onAvatarTap;
  final bool showAvatar;
  final String? currentUserId;
  final Message? highlightedMessage;
  final bool shouldHighlight;
  final Map<String, int>? messageIndexMap;

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
    this.messageIndexMap,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.scrollController,
      reverse: true,
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        var item = widget.items[index];
        final nextItem = index > 0 ? widget.items[index - 1] : null;

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
          // 确保消息的 metadata 中包含 channelId
          if (item.metadata == null ||
              !item.metadata!.containsKey('channelId')) {
            final metadata = Map<String, dynamic>.from(item.metadata ?? {});
            metadata['channelId'] = item.channelId; // 使用消息对象中的 channelId
            // 创建一个临时消息对象，等待异步操作完成
            Message tempMessage = item;
            // 使用 Future.microtask 来确保状态更新是安全的
            Future.microtask(() async {
              final updatedMessage = await item.copyWith(metadata: metadata);
              if (mounted) {
                setState(() {
                  // 更新items中的消息
                  final index = widget.items.indexOf(tempMessage);
                  if (index != -1 && widget.items[index] is Message) {
                    widget.items[index] = updatedMessage;
                  }
                });
              }
            });
          }

          // 为消息项添加 AutoScrollTag
          final tagIndex = widget.messageIndexMap?[item.id] ?? index;
          return AutoScrollTag(
            key: ValueKey(item.id),
            controller: widget.scrollController,
            index: tagIndex,
            child: Column(
              children: [
                if (dateSeparator != null) dateSeparator,
                GestureDetector(
                  onLongPress: () {
                    // 使用统一的消息选项处理器
                    MessageOptionsHandler.showOptionsDialog(
                      context: context,
                      message: item,
                      onMessageEdit: widget.onMessageEdit,
                      onMessageDelete: widget.onMessageDelete,
                      onMessageCopy: widget.onMessageCopy,
                      onSetFixedSymbol: widget.onSetFixedSymbol,
                      onSetBubbleColor: widget.onSetBubbleColor,
                      onReply: widget.onReply,
                      onToggleFavorite: widget.onToggleFavorite,
                    );
                  },
                  onDoubleTap: () {
                    // 使用统一的消息选项处理器，直接显示固态符号编辑对话框
                    MessageOptionsHandler.showOptionsDialog(
                      context: context,
                      message: item,
                      onMessageEdit: widget.onMessageEdit,
                      onMessageDelete: widget.onMessageDelete,
                      onMessageCopy: widget.onMessageCopy,
                      onSetFixedSymbol: widget.onSetFixedSymbol,
                      onSetBubbleColor: widget.onSetBubbleColor,
                      onReply: widget.onReply,
                      onToggleFavorite: widget.onToggleFavorite,
                      initiallyShowFixedSymbolDialog: true, // 直接显示固态符号编辑对话框
                    );
                  },
                  child: ValueListenableBuilder<Set<String>>(
                    valueListenable: widget.selectedMessageIds,
                    builder: (context, selectedIds, _) {
                      return MessageBubble(
                        message: item,
                        isSelected: selectedIds.contains(item.id),
                        isMultiSelectMode: widget.isMultiSelectMode,
                        onEdit: () => widget.onMessageEdit(item),
                        onDelete: () => widget.onMessageDelete(item),
                        onCopy: () => widget.onMessageCopy(item),
                        onSetFixedSymbol:
                            (symbol) => widget.onSetFixedSymbol(item, symbol),
                        onLongPress: null, // 移除重复的长按处理
                        onTap:
                            widget.isMultiSelectMode
                                ? () => widget.onToggleMessageSelection(item.id)
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
                                      NavigationHelper.push(context, FilePreviewScreen(
                                                filePath: fileInfo.filePath,
                                                fileName: fileInfo.fileName,
                                                mimeType:
                                                    fileInfo.mimeType ??
                                                    'application/octet-stream',
                                                fileSize: fileInfo.fileSize,),
                                      );
                                    } catch (e) {
                                      Toast.error('chat_errorFilePreviewFailed'.tr);
                                    }
                                  }
                                },
                        onAvatarTap:
                            widget.onAvatarTap != null
                                ? () => widget.onAvatarTap!(item)
                                : null,
                        showAvatar: widget.showAvatar,
                        currentUserId: widget.currentUserId ?? '',
                        isHighlighted:
                            widget.shouldHighlight &&
                            widget.highlightedMessage != null &&
                            item.id == widget.highlightedMessage?.id,
                        onToggleFavorite: () => widget.onToggleFavorite(item),
                        onReplyTap: widget.onReplyTap,
                      );
                    },
                  ),
                ),
              ],
            ),
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
