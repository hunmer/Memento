part of 'chat_plugin.dart';

/// 注册数据选择器
void _registerDataSelectors() {
  // 1. 频道选择器（单级）
  pluginDataSelectorService.registerSelector(SelectorDefinition(
    id: 'chat.channel',
    pluginId: id,
    name: 'chat_channelSelectorName'.tr,
    description: 'chat_channelSelectorDesc'.tr,
    icon: Icons.chat_bubble_outline,
    color: color,
    steps: [
      SelectorStep(
        id: 'channel',
        title: 'chat_selectChannel'.tr,
        viewType: SelectorViewType.list,
        isFinalStep: true,
        emptyText: 'chat_noChannels'.tr,
        dataLoader: (_) async {
          return dataService.channels.map((channel) {
            // 准备 rawData - 包含完整的频道信息
            final lastMessage = channel.messages.isNotEmpty
                ? channel.messages.last.content
                : null;
            final lastMessageTime = channel.messages.isNotEmpty
                ? channel.messages.last.date.toIso8601String()
                : DateTime.now().toIso8601String();

            return SelectableItem(
              id: channel.id,
              title: channel.title,
              icon: channel.icon,
              color: channel.backgroundColor,
              subtitle: lastMessage,
              rawData: {
                'id': channel.id,
                'title': channel.title,
                'icon': channel.icon.codePoint,
                'backgroundColor': channel.backgroundColor.value,
                'lastMessage': lastMessage,
                'lastMessageTime': lastMessageTime,
                'messageCount': channel.messages.length,
              },
            );
          }).toList();
        },
        searchFilter: (items, query) {
          final lowerQuery = query.toLowerCase();
          return items.where((item) =>
            item.title.toLowerCase().contains(lowerQuery)
          ).toList();
        },
      ),
    ],
  ));

  // 2. 消息选择器（两级：频道 -> 消息）
  pluginDataSelectorService.registerSelector(SelectorDefinition(
    id: 'chat.message',
    pluginId: id,
    name: '选择消息',
    description: '选择一条聊天消息',
    icon: Icons.message,
    color: color,
    steps: [
      // 第一级：选择频道
      SelectorStep(
        id: 'channel',
        title: '选择频道',
        viewType: SelectorViewType.list,
        isFinalStep: false,
        emptyText: '暂无频道',
        dataLoader: (_) async {
          return dataService.channels.map((channel) => SelectableItem(
            id: channel.id,
            title: channel.title,
            icon: channel.icon,
            color: channel.backgroundColor,
            subtitle: '${channel.messages.length} 条消息',
            rawData: channel,
          )).toList();
        },
      ),
      // 第二级：选择消息
      SelectorStep(
        id: 'message',
        title: '选择消息',
        viewType: SelectorViewType.list,
        isFinalStep: true,
        emptyText: '该频道暂无消息',
        dataLoader: (previousSelections) async {
          final channel = previousSelections['channel'] as Channel;
          // 加载频道消息
          final messages = await dataService.getChannelMessages(channel.id);
          if (messages == null) return [];

          return messages.map((message) => SelectableItem(
            id: message.id,
            title: message.content.length > 50
                ? '${message.content.substring(0, 50)}...'
                : message.content,
            subtitle: _formatMessageDate(message.date),
            icon: _getMessageIcon(message.type),
            rawData: message,
            metadata: {'channelId': channel.id},
          )).toList();
        },
        searchFilter: (items, query) {
          final lowerQuery = query.toLowerCase();
          return items.where((item) =>
            item.title.toLowerCase().contains(lowerQuery)
          ).toList();
        },
      ),
    ],
  ));
}

IconData _getMessageIcon(MessageType type) {
  switch (type) {
    case MessageType.image:
      return Icons.image;
    case MessageType.video:
      return Icons.videocam;
    case MessageType.audio:
      return Icons.audiotrack;
    case MessageType.file:
      return Icons.attach_file;
    default:
      return Icons.text_fields;
  }
}

String _formatMessageDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inMinutes < 1) {
    return '刚刚';
  } else if (diff.inHours < 1) {
    return '${diff.inMinutes} 分钟前';
  } else if (diff.inDays < 1) {
    return '${diff.inHours} 小时前';
  } else if (diff.inDays < 7) {
    return '${diff.inDays} 天前';
  } else {
    return '${date.month}/${date.day}';
  }
}
