import 'package:flutter/material.dart';
import '../../../models/message.dart';
import 'message_bubble.dart';
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
  final void Function(Message)? onAvatarTap;
  final bool showAvatar;

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
                onLongPress: () {
                  // 使用弹出对话框代替上下文菜单，避免位置计算问题
                  _showMessageOptions(context, item);
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
                  onTap: isMultiSelectMode
                      ? () => onToggleMessageSelection(item.id)
                      : null,
                  onAvatarTap: onAvatarTap != null ? () => onAvatarTap!(item) : null,
                  showAvatar: showAvatar,
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

  void _showFixedSymbolDialog(BuildContext context, Message message) {
    final TextEditingController symbolController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Fixed Symbol'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: symbolController,
              decoration: const InputDecoration(
                labelText: 'Symbol',
                hintText: 'Enter symbol or leave empty to remove',
              ),
              maxLength: 1, // 限制只能输入一个字符
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['⭐', '📌', '❤️', '🔥', '✨'].map((symbol) => 
                ActionChip(
                  label: Text(symbol),
                  onPressed: () {
                    symbolController.text = symbol;
                  },
                )
              ).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final symbol = symbolController.text.isEmpty ? null : symbolController.text;
              onSetFixedSymbol(message, symbol);
              Navigator.pop(context);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context, Message message) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Message Options'),
        children: [
          // 设置固定字符选项
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showFixedSymbolDialog(context, message);
            },
            child: const Row(
              children: [
                Icon(Icons.push_pin, size: 20),
                SizedBox(width: 8),
                Text('Set Fixed Symbol'),
              ],
            ),
          ),
          const Divider(),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                onMessageEdit(message);
              },
              child: const Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              onMessageCopy(message);
            },
            child: const Row(
              children: [
                Icon(Icons.copy, size: 20),
                SizedBox(width: 8),
                Text('Copy'),
              ],
            ),
          ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                onMessageDelete(message);
              },
              child: const Row(
                children: [
                  Icon(Icons.delete, size: 20),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}