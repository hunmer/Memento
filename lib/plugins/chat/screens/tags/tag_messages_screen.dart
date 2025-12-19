import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:Memento/plugins/chat/models/message.dart';
import 'package:Memento/plugins/chat/screens/chat_screen/chat_screen.dart';

/// 标签消息列表页面
/// 显示某个标签的所有关联消息
class TagMessagesScreen extends StatefulWidget {
  final String tagName;
  final List<Message> messages;
  final ChatPlugin chatPlugin;

  const TagMessagesScreen({
    super.key,
    required this.tagName,
    required this.messages,
    required this.chatPlugin,
  });

  @override
  State<TagMessagesScreen> createState() => _TagMessagesScreenState();
}

class _TagMessagesScreenState extends State<TagMessagesScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 获取过滤后的消息列表
  List<Message> get _filteredMessages {
    if (_searchQuery.isEmpty) return widget.messages;
    return widget.messages.where((m) {
      return m.content.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  /// 切换搜索状态
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  /// 导航到原始消息所在的频道
  void _navigateToOriginalMessage(Message message) {
    if (message.channelId == null) {
      Get.snackbar(
        'chat_error'.tr,
        'chat_messageNoChannel'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // 查找频道
    try {
      final channel = widget.chatPlugin.channelService.channels.firstWhere(
        (c) => c.id == message.channelId,
      );

      // 设置当前活跃频道，这是关键步骤！
      widget.chatPlugin.channelService.setCurrentChannel(channel);

      // 导航到聊天页面并高亮消息
      // 使用 initialMessage 和 autoScroll 来定位到消息
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            channel: channel,
            initialMessage: message,
            highlightMessage: message,
            autoScroll: true,
          ),
        ),
      );
    } catch (e) {
      Get.snackbar(
        'chat_error'.tr,
        'chat_channelNotFound'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// 获取频道名称
  String _getChannelName(String channelId) {
    try {
      final channel = widget.chatPlugin.channelService.channels.firstWhere(
        (c) => c.id == channelId,
      );
      return channel.title;
    } catch (_) {
      return 'chat_unknownChannel'.tr;
    }
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      // 今天：显示时间
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      // 一周内：显示"N天前"
      return 'chat_daysAgo'.trParams({'days': diff.inDays.toString()});
    } else {
      // 更早：显示日期
      return '${date.month}/${date.day}';
    }
  }

  /// 构建消息项
  Widget _buildMessageItem(Message message) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToOriginalMessage(message),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 用户信息和时间
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      message.user.username.isNotEmpty
                          ? message.user.username[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.user.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _formatDate(message.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 频道标识
                  if (message.channelId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getChannelName(message.channelId!),
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // 消息内容
              Text(
                message.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'chat_noMatchingMessages'.tr,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'chat_searchMessages'.tr,
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 16),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              )
            : Text('#${widget.tagName}'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: Column(
        children: [
          // 消息统计
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'chat_totalMessages'.trParams({
                'count': _filteredMessages.length.toString(),
              }),
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),

          // 消息列表
          Expanded(
            child: _filteredMessages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _filteredMessages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageItem(_filteredMessages[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
