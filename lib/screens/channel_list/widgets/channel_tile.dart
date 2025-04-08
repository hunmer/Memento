import 'package:flutter/material.dart';
import '../../../models/channel.dart';
import '../../../utils/date_formatter.dart';

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
                    _buildSubtitle(),
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
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('编辑'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20),
                        SizedBox(width: 8),
                        Text('删除'),
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

  Widget _buildSubtitle() {
    if (channel.draft != null && channel.draft!.isNotEmpty) {
      return RichText(
        text: TextSpan(
          children: [
            const TextSpan(
              text: '[草稿] ',
              style: TextStyle(color: Colors.red, fontSize: 13),
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
      String subtitle = lastMessage != null
          ? '${lastMessage.content}\n${DateFormatter.formatDateTime(lastMessage.date)}'
          : '暂无消息';
      return Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      );
    }
  }
}