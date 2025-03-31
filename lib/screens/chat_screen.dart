import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/channel.dart';
import '../plugins/chat/chat_plugin.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import 'channel_info_screen.dart';
import 'package:audioplayers/audioplayers.dart';

class ChatScreen extends StatefulWidget {
  final Channel channel;

  const ChatScreen({super.key, required this.channel});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late List<Message> messages;
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Message? _messageBeingEdited;
  final TextEditingController _editingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    messages = List.from(widget.channel.messages);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _editingController.dispose();
    super.dispose();
  }

  void _handleMessageSent(String content) async {
    // 如果是编辑模式，则更新消息
    if (_messageBeingEdited != null) {
      setState(() {
        _messageBeingEdited!.edit(content);
        _messageBeingEdited = null;
      });
      return;
    }

    // 创建默认用户，如果members列表为空
    final User currentUser =
        widget.channel.members.isNotEmpty
            ? widget.channel.members.first
            : User(id: 'current_user', username: '我');

    final newMessage = Message(
      id: DateTime.now().toString(),
      content: content,
      date: DateTime.now(),
      type: MessageType.sent,
      user: currentUser,
    );

    setState(() {
      messages.add(newMessage);
      widget.channel.messages.add(newMessage);
      // 保存消息到本地存储
      ChatPlugin.instance.saveMessages(widget.channel.id, messages);
    });

    // 播放发送消息音效
    await _audioPlayer.play(AssetSource('audio/msg_sended.mp3'));

    // 滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleMessageEdit(Message message) {
    setState(() {
      _messageBeingEdited = message;
      _editingController.text = message.content;
    });

    // 显示编辑对话框
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('编辑消息'),
            content: TextField(
              controller: _editingController,
              autofocus: true,
              maxLines: null,
              decoration: const InputDecoration(hintText: '输入新的消息内容...'),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _messageBeingEdited = null;
                  });
                },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  if (_editingController.text.trim().isNotEmpty) {
                    setState(() {
                      _messageBeingEdited!.edit(_editingController.text.trim());
                      _messageBeingEdited = null;
                      // 保存编辑后的消息到本地存储
                      ChatPlugin.instance.saveMessages(
                        widget.channel.id,
                        messages,
                      );
                    });
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('保存'),
              ),
            ],
          ),
    );
  }

  void _handleMessageDelete(Message message) {
    setState(() {
      messages.remove(message);
      widget.channel.messages.remove(message);
      // 保存删除后的消息列表到本地存储
      ChatPlugin.instance.saveMessages(widget.channel.id, messages);
    });
  }

  void _handleMessageCopy(Message message) {
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('消息已复制到剪贴板')));
  }

  void _handleSetFixedSymbol(Message message, String? symbol) {
    setState(() {
      message.setFixedSymbol(symbol);
      // 保存消息到本地存储
      ChatPlugin.instance.saveMessages(widget.channel.id, messages);
    });
  }

  void _showChannelInfo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChannelInfoScreen(channel: widget.channel),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              _formatDate(date),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return '今天';
    } else if (messageDate == yesterday) {
      return '昨天';
    } else if (now.difference(date).inDays < 7) {
      return '${_getWeekday(date)}';
    } else {
      return '${date.year}年${date.month}月${date.day}日';
    }
  }

  String _getWeekday(DateTime date) {
    const weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    return weekdays[date.weekday - 1];
  }

  // 构建消息列表项，包括日期分隔符
  List<dynamic> _buildMessageListItems() {
    if (messages.isEmpty) return [];

    final items = <dynamic>[];
    DateTime? currentDate;

    for (final message in messages) {
      final messageDate = DateTime(
        message.date.year,
        message.date.month,
        message.date.day,
      );

      if (currentDate == null || !_isSameDay(currentDate, messageDate)) {
        currentDate = messageDate;
        items.add(messageDate); // 添加日期分隔符
      }

      items.add(message); // 添加消息
    }

    return items;
  }

  void _showChannelOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('查看频道信息'),
                onTap: () {
                  Navigator.pop(context);
                  _showChannelInfo();
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('频道通知设置'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('频道通知设置功能尚未实现')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('退出频道'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('退出频道功能尚未实现')));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showChannelInfo,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: widget.channel.backgroundColor,
                child: Icon(widget.channel.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              Text(widget.channel.title),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showChannelInfo,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'info') {
                _showChannelInfo();
              } else if (value == 'more') {
                _showChannelOptions();
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'info', child: Text('查看频道信息')),
                  const PopupMenuItem(value: 'more', child: Text('更多选项')),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                messages.isEmpty
                    ? const Center(
                      child: Text('暂无消息', style: TextStyle(color: Colors.grey)),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _buildMessageListItems().length,
                      itemBuilder: (context, index) {
                        final item = _buildMessageListItems()[index];
                        if (item is DateTime) {
                          return _buildDateSeparator(item);
                        } else if (item is Message) {
                          return MessageBubble(
                            key: ValueKey(item.id),
                            message: item,
                            onEdit: _handleMessageEdit,
                            onDelete: _handleMessageDelete,
                            onCopy: _handleMessageCopy,
                            onSetFixedSymbol: _handleSetFixedSymbol,
                            channelColor:
                                widget.channel.backgroundColor, // 传递频道背景颜色
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
          ),
          MessageInput(onMessageSent: _handleMessageSent),
        ],
      ),
    );
  }
}
