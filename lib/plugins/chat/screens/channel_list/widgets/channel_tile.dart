import 'package:flutter/material.dart';
import '../../../models/channel.dart';
import '../../../utils/date_formatter.dart';
import '../../../l10n/chat_localizations.dart';

class ChannelTile extends StatelessWidget {
  final Channel channel;
  final VoidCallback onTap;
  final Function(Channel) onEdit;
  final Function(Channel) onDelete;
  final Key? itemKey;

  const ChannelTile({
    super.key,
    required this.channel,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.itemKey,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Container(
          key: itemKey,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: channel.backgroundColor,
                child: Icon(channel.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      channel.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    _buildSubtitle(context),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit(channel);
                  } else if (value == 'delete') {
                    onDelete(channel);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 20),
                        const SizedBox(width: 8),
                            Text(ChatLocalizations.of(context).edit ?? 'Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, size: 20),
                        const SizedBox(width: 8),
                            Text(
                              ChatLocalizations.of(context).delete ?? 'Delete',
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    if (channel.draft != null && channel.draft!.isNotEmpty) {
      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '[${ChatLocalizations.of(context).draft ?? "Draft"}] ',
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
            TextSpan(
              text: channel.draft,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    } else {
      final lastMessage = channel.lastMessage;
      if (lastMessage != null) {
        // 使用Row和Column组合布局，确保时间始终显示
        return Row(
          children: [
            // 消息内容占用大部分空间
            Expanded(
              child: Text(
                lastMessage.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
            // 时间显示在右侧，固定宽度
            const SizedBox(width: 8),
            Text(
              DateFormatter.formatDateTime(lastMessage.date, context),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        );
      } else {
        return Text(
          ChatLocalizations.of(context).enterMessage ?? 'Type a message...',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        );
      }
    }
  }
}