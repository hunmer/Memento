import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/chat/models/channel.dart';
import 'package:Memento/plugins/chat/screens/chat_screen/chat_screen.dart';
import 'package:Memento/plugins/chat/utils/date_formatter.dart';

class ChannelTile extends StatelessWidget {
  final Channel channel;
  final VoidCallback? onTap; // 改为可选，因为 OpenContainer 会处理导航
  final VoidCallback? onBeforeOpen; // 在打开页面之前的回调（如设置当前频道）
  final Function(Channel) onEdit;
  final Function(Channel) onDelete;
  final Key? itemKey;

  const ChannelTile({
    super.key,
    required this.channel,
    this.onTap, // 改为可选
    this.onBeforeOpen, // 新增回调
    required this.onEdit,
    required this.onDelete,
    this.itemKey,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () {
          // 在打开之前执行回调（如设置当前频道）
          onBeforeOpen?.call();
          // 打开聊天页面
          NavigationHelper.openContainer(
            context,
            (context) => ChatScreen(channel: channel),
            transitionDuration: const Duration(milliseconds: 400),
          );
        },
        child: _buildTileContent(context),
      ),
    );
  }

  /// 构建列表项内容
  Widget _buildTileContent(BuildContext context) {
    return Container(
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
                    Text('chat_edit'.tr),
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
                      'chat_delete'.tr,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    if (channel.draft != null && channel.draft!.isNotEmpty) {
      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '[${'chat_draft'.tr}] ',
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
          'chat_enterMessage'.tr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        );
      }
    }
  }
}