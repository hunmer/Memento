import 'package:flutter/material.dart';
import '../../../models/message.dart';
import '../../../widgets/message_bubble.dart';
import '../widgets/date_separator.dart';
import '../../../utils/date_formatter.dart';

class MessageList extends StatelessWidget {
  final List<dynamic> items;
  final bool isMultiSelectMode;
  final Set<String> selectedMessageIds;
  final void Function(Message) onMessageEdit;
  final Future<void> Function(Message) onMessageDelete;
  final void Function(Message) onMessageCopy;
  final void Function(Message, String?) onSetFixedSymbol;
  final void Function(String) onToggleMessageSelection;
  final ScrollController scrollController;

  const MessageList({
    super.key,
    required this.items,
    required this.isMultiSelectMode,
    required this.selectedMessageIds,
    required this.onMessageEdit,
    required this.onMessageDelete,
    required this.onMessageCopy,
    required this.onSetFixedSymbol,
    required this.onToggleMessageSelection,
    required this.scrollController,
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
        } else if (item is Message && nextItem is Message && _shouldShowDateSeparator(item, nextItem)) {
          // 如果当前消息和下一条消息不是同一天，显示日期分隔符
          dateSeparator = DateSeparator(date: item.date);
        }

        if (item is Message) {
          return Column(
            children: [
              if (dateSeparator != null) dateSeparator,
              GestureDetector(
                onLongPressStart: (LongPressStartDetails details) {
                  final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                  final RelativeRect position = RelativeRect.fromRect(
                    Rect.fromPoints(
                      details.globalPosition,
                      details.globalPosition,
                    ),
                    Offset.zero & overlay.size,
                  );
                  _showContextMenu(context, item, position);
                },
                child: MessageBubble(
                  message: item,
                  isSelected: selectedMessageIds.contains(item.id),
                  isMultiSelectMode: isMultiSelectMode,
                  onEdit: () => onMessageEdit(item),
                  onDelete: () => onMessageDelete(item),
                  onCopy: () => onMessageCopy(item),
                  onSetFixedSymbol: (symbol) => onSetFixedSymbol(item, symbol),
                  onTap: isMultiSelectMode
                      ? () => onToggleMessageSelection(item.id)
                      : null,
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

  void _showContextMenu(BuildContext context, Message message, RelativeRect position) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    showMenu<String>(
      color: Theme.of(context).cardColor,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      constraints: const BoxConstraints(
        minWidth: 124,
        maxWidth: 280,
      ),
      useRootNavigator: true,
      context: context,
      position: position,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      items: [
        if (message.type == MessageType.sent)
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: const [
                Icon(Icons.edit, size: 20),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'copy',
          child: Row(
            children: const [
              Icon(Icons.copy, size: 20),
              SizedBox(width: 8),
              Text('Copy'),
            ],
          ),
        ),
        if (message.type == MessageType.sent)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: const [
                Icon(Icons.delete, size: 20),
                SizedBox(width: 8),
                Text('Delete'),
              ],
            ),
          ),
      ],
    ).then((String? value) {
      if (value != null) {
        switch (value) {
          case 'edit':
            onMessageEdit(message);
            break;
          case 'delete':
            onMessageDelete(message);
            break;
          case 'copy':
            onMessageCopy(message);
            break;
        }
      }
    });
  }
}