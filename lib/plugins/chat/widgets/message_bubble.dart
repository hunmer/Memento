import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../utils/date_formatter.dart';
import '../l10n/chat_localizations.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCopy;
  final Function(String?)? onSetFixedSymbol;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  const MessageBubble({
    super.key, 
    required this.message,
    this.isSelected = false,
    this.isMultiSelectMode = false,
    this.onEdit,
    this.onDelete,
    this.onCopy,
    this.onSetFixedSymbol,
    this.onLongPress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSentMessage = message.type == MessageType.sent;
    final backgroundColor =
        isSentMessage
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.shade200;
    final textColor = isSentMessage ? Colors.white : Colors.black87;

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
        mainAxisAlignment:
            isSentMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSentMessage) _buildAvatar(message.user, context),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isSentMessage
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isSentMessage)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0, right: 8.0),
                        child: Text(
                          DateFormatter.formatDateTime(message.date, context),
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          message.content,
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ),
                    if (!isSentMessage)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0, left: 8.0),
                        child: Text(
                          DateFormatter.formatDateTime(message.date, context),
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isSentMessage) _buildAvatar(message.user, context),
        ],
      ),
      ),
    );
  }

  Widget _buildAvatar(User? user, [BuildContext? context]) {
  if (user == null) {
    return const CircleAvatar(
      radius: 16,
      child: Icon(Icons.person),
    );
  }

  if (user.iconPath != null) {
    return CircleAvatar(
      backgroundImage: AssetImage(user.iconPath!),
      radius: 16,
    );
  }

  final String initial = user.username.isNotEmpty ? user.username[0] : '?';
  return CircleAvatar(
    radius: 16, 
    child: Text(
      initial,
      semanticsLabel: context != null && ChatLocalizations.of(context) != null
          ? ChatLocalizations.of(context)!.userInitial(user.username)
          : initial,
    ),
  );
}

  Widget _buildMessageActions() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      itemBuilder: (BuildContext context) {
        final localizations = ChatLocalizations.of(context);
        if (localizations == null) {
          return []; // Return empty menu if localizations are not available
        }

        return [
          if (message.type == MessageType.sent && !isMultiSelectMode)
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 20),
                  const SizedBox(width: 8),
                  Text(localizations.edit),
                ],
              ),
            ),
          if (!isMultiSelectMode) ...[
            PopupMenuItem(
              value: 'copy',
              child: Row(
                children: [
                  const Icon(Icons.copy, size: 20),
                  const SizedBox(width: 8),
                  Text(localizations.copy),
                ],
              ),
            ),
            if (message.type == MessageType.sent)
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, size: 20),
                    const SizedBox(width: 8),
                    Text(localizations.delete),
                  ],
                ),
              ),
          ],
        ];
      },
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
          case 'copy':
            onCopy?.call();
            break;
        }
      },
    );
  }
}