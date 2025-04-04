import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/image_service.dart';
import '../models/channel.dart';
import '../plugins/chat/chat_plugin.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import 'channel_info_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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
  final TextEditingController _draftController = TextEditingController();
  final ImageService _imageService = ImageService();

  // 多选模式相关状态
  bool _isMultiSelectMode = false;
  final Set<String> _selectedMessageIds = <String>{};
  DateTime? _selectedDate; // 添加选中日期变量

  // 懒加载相关
  bool _isLoading = false;
  static const int _pageSize = 50;
  int _currentPage = 1;

  // 更新消息日期列表
  void _updateDatesWithMessages() {
    if (messages.isEmpty) {
      setState(() {
        _selectedDate = null;
      });
      return;
    }

    final DateTime currentDate = DateTime.now();
    setState(() {
      // 如果没有选中日期或者选中日期不在消息日期范围内，则选择最新消息的日期
      if (_selectedDate == null ||
          _selectedDate!.isBefore(messages.last.date) ||
          _selectedDate!.isAfter(messages.first.date)) {
        _selectedDate = messages.first.date;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadDraft();
    _scrollController.addListener(_scrollListener);
    // 在初始化完成后滚动到顶部（因为消息列表是倒序的）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _loadMessages() {
    final allMessages = List<Message>.from(widget.channel.messages);
    List<Message> filteredMessages;

    if (_selectedDate != null) {
      filteredMessages =
          allMessages
              .where((message) => _isSameDay(message.date, _selectedDate!))
              .toList();
    } else {
      filteredMessages = allMessages;
    }

    final start = (filteredMessages.length - _pageSize * _currentPage).clamp(
      0,
      filteredMessages.length,
    );
    final end = filteredMessages.length;
    messages = filteredMessages.sublist(start, end).reversed.toList();
    setState(() {});
  }

  void _loadDraft() {
    final draft = widget.channel.draft;
    if (draft != null && draft.isNotEmpty) {
      _draftController.text = draft;
    }
  }

  void _scrollListener() {
    if (_scrollController.offset <=
            _scrollController.position.minScrollExtent &&
        !_scrollController.position.outOfRange) {
      _loadMoreMessages();
    }
  }

  void _loadMoreMessages() {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });

      final allMessages = List<Message>.from(widget.channel.messages);
      final start = (allMessages.length - _pageSize * (_currentPage + 1)).clamp(
        0,
        allMessages.length,
      );
      final end = allMessages.length - _pageSize * _currentPage;

      if (start < end) {
        setState(() {
          messages.insertAll(
            0,
            allMessages.sublist(start, end).reversed.toList(),
          );
          _currentPage++;
        });
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  // 滚动到底部的通用方法
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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
      messages.insert(0, newMessage);
      widget.channel.messages.add(newMessage);
      // 更新频道的最后一条消息
      widget.channel.lastMessage = newMessage;
      // 保存消息到本地存储
      ChatPlugin.instance.addMessage(widget.channel.id, newMessage);
      // 清除草稿
      widget.channel.draft = '';
      _draftController.clear();
      ChatPlugin.instance.saveDraft(widget.channel.id, '');

      // 更新有消息的日期集合
      _updateDatesWithMessages();

      // 如果当前正在查看特定日期的消息，并且新消息的日期与当前选择的日期相同，则更新消息列表
      if (_selectedDate != null &&
          _isSameDay(newMessage.date, _selectedDate!)) {
        _loadMessages();
      } else if (_selectedDate != null) {
        // 如果当前正在查看特定日期的消息，但新消息不属于该日期，提示用户
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('新消息已发送，但不在当前显示的日期范围内'),
            action: SnackBarAction(
              label: '查看全部',
              onPressed: () {
                setState(() {
                  _selectedDate = null;
                });
                _loadMessages();
              },
            ),
          ),
        );
      }
    });

    // 播放发送消息音效
    await _audioPlayer.play(AssetSource('audio/msg_sended.mp3'));

    // 滚动到顶部（因为消息列表是倒序的）
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _saveDraft(String draft) {
    setState(() {
      widget.channel.draft = draft;
    });
    // 保存草稿并通知监听器更新
    ChatPlugin.instance.saveDraft(widget.channel.id, draft);
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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _editingController,
                  autofocus: true,
                  maxLines: null,
                  decoration: const InputDecoration(hintText: '输入新的消息内容...'),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.format_bold),
                      onPressed: () => _insertMarkdownStyle('**'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_italic),
                      onPressed: () => _insertMarkdownStyle('*'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_strikethrough),
                      onPressed: () => _insertMarkdownStyle('~~'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_underline),
                      onPressed: () => _insertMarkdownStyle('__'),
                    ),
                  ],
                ),
              ],
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

  void _insertMarkdownStyle(String style) {
    final text = _editingController.text;
    final selection = _editingController.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '$style${selection.textInside(text)}$style',
    );
    _editingController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset:
            selection.baseOffset +
            style.length * 2 +
            selection.textInside(text).length,
      ),
    );
  }

  void _handleMessageDelete(Message message) {
    setState(() {
      messages.remove(message);
      widget.channel.messages.remove(message);
      // 保存删除后的消息列表到本地存储
      ChatPlugin.instance.saveMessages(widget.channel.id, messages);
      // 更新有消息的日期集合
      _updateDatesWithMessages();
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

  bool _isDatePickerShowing = false;

  void _showDatePicker() async {
    if (_isDatePickerShowing) return;

    // 使用完整的消息列表
    final allMessages = widget.channel.messages;
    if (allMessages.isEmpty) return;

    setState(() {
      _isDatePickerShowing = true;
    });

    // 获取最早和最晚的消息日期，并确保 firstDate 不晚于 lastDate
    DateTime firstDate = allMessages.last.date;
    DateTime lastDate = allMessages.first.date;

    // 确保 firstDate 在 lastDate 之前或相等
    if (firstDate.isAfter(lastDate)) {
      // 如果顺序颠倒，则交换它们
      final DateTime temp = firstDate;
      firstDate = lastDate;
      lastDate = temp;
    }

    // 创建一个包含所有有消息的日期的集合
    final Set<DateTime> messageDates =
        allMessages
            .map((m) => DateTime(m.date.year, m.date.month, m.date.day))
            .toSet();

    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate ?? lastDate,
        firstDate: firstDate,
        lastDate: lastDate,
        selectableDayPredicate: (DateTime day) {
          // 只有在messageDates中的日期才可选
          return messageDates.contains(DateTime(day.year, day.month, day.day));
        },
        helpText: '选择日期', // 日期选择器的标题
        cancelText: '取消',
        confirmText: '确定',
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.blue, // 主色调
                onPrimary: Colors.white, // 主色调上的文字颜色
                onSurface: Colors.black, // 表面上的文字颜色
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Expanded(child: child ?? Container()),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(null);
                    setState(() {
                      _selectedDate = null;
                    });
                    _loadMessages();
                  },
                  child: const Text(
                    '清除日期',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (picked != null) {
        setState(() {
          _selectedDate = picked;
        });
        _loadMessages();
      }
    } finally {
      setState(() {
        _isDatePickerShowing = false;
      });
    }
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

    // 由于ListView是reverse: true，我们需要反向思考日期分隔符的位置
    final items = <dynamic>[];
    DateTime? lastDate;

    // 由于messages已经是按日期倒序排列的，我们可以直接遍历
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final messageDate = DateTime(
        message.date.year,
        message.date.month,
        message.date.day,
      );

      // 添加消息
      items.add(message);

      // 检查是否需要添加日期分隔符
      // 如果是最后一条消息，或者下一条消息的日期与当前不同，则添加日期分隔符
      bool isLastMessage = i == messages.length - 1;
      bool nextMessageDifferentDay =
          !isLastMessage &&
          !_isSameDay(
            messageDate,
            DateTime(
              messages[i + 1].date.year,
              messages[i + 1].date.month,
              messages[i + 1].date.day,
            ),
          );

      if (isLastMessage || nextMessageDifferentDay) {
        items.add(messageDate); // 添加日期分隔符
      }
    }

    return items;
  }

  // 处理多选消息的复制
  void _handleMultiMessagesCopy() {
    if (_selectedMessageIds.isEmpty) return;

    final selectedMessages =
        messages.where((msg) => _selectedMessageIds.contains(msg.id)).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    final copiedText = selectedMessages.map((msg) => msg.content).join('\n\n');

    Clipboard.setData(ClipboardData(text: copiedText));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已复制选中的消息')));

    // 退出多选模式
    setState(() {
      _isMultiSelectMode = false;
      _selectedMessageIds.clear();
    });
  }

  // 处理多选消息的删除
  void _handleMultiMessagesDelete() {
    if (_selectedMessageIds.isEmpty) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('删除消息'),
            content: Text('确定要删除${_selectedMessageIds.length}条选中的消息吗？此操作不可撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    messages.removeWhere(
                      (msg) => _selectedMessageIds.contains(msg.id),
                    );
                    widget.channel.messages.removeWhere(
                      (msg) => _selectedMessageIds.contains(msg.id),
                    );
                    // 保存更改到本地存储
                    ChatPlugin.instance.saveMessages(
                      widget.channel.id,
                      messages,
                    );

                    // 更新有消息的日期集合
                    _updateDatesWithMessages();

                    // 如果当前正在查看特定日期，重新加载消息
                    if (_selectedDate != null) {
                      _loadMessages();
                    }

                    // 退出多选模式
                    _isMultiSelectMode = false;
                    _selectedMessageIds.clear();
                  });
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('删除'),
              ),
            ],
          ),
    );
  }

  // 切换消息的选中状态
  void _toggleMessageSelection(String messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
        if (_selectedMessageIds.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _selectedMessageIds.add(messageId);
      }
    });
  }

  // 显示清空所有消息的确认对话框
  void _showClearMessagesConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('清空所有消息'),
            content: const Text('确定要清空此频道的所有消息吗？此操作不可撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    messages.clear();
                    widget.channel.messages.clear();
                    // 保存更改到本地存储
                    ChatPlugin.instance.saveMessages(
                      widget.channel.id,
                      messages,
                    );

                    // 更新有消息的日期集合
                    _updateDatesWithMessages();

                    // 如果当前正在查看特定日期，清除选择
                    if (_selectedDate != null) {
                      _selectedDate = null;
                    }
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('已清空所有消息')));
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('清空'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading:
            _isMultiSelectMode
                ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isMultiSelectMode = false;
                      _selectedMessageIds.clear();
                    });
                  },
                )
                : null,
        title:
            _isMultiSelectMode
                ? Text('已选择 ${_selectedMessageIds.length} 项')
                : GestureDetector(
                  onTap: _showChannelInfo,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: widget.channel.backgroundColor,
                        child: Icon(
                          widget.channel.icon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(widget.channel.title),
                    ],
                  ),
                ),
        actions: [
          if (!_isMultiSelectMode) ...[
            IconButton(
              icon: const Icon(Icons.check_box_outlined),
              onPressed: () {
                setState(() {
                  _isMultiSelectMode = true;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _showDatePicker,
            ),
            // 移除了单独的信息图标按钮
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'info':
                    _showChannelInfo();
                    break;
                  case 'notifications':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('频道通知设置功能尚未实现')),
                    );
                    break;
                  case 'clear':
                    _showClearMessagesConfirmation();
                    break;
                  case 'exit':
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('退出频道功能尚未实现')));
                    break;
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'info',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline),
                          SizedBox(width: 8),
                          Text('查看频道信息'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'notifications',
                      child: Row(
                        children: [
                          Icon(Icons.notifications),
                          SizedBox(width: 8),
                          Text('频道通知设置'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep, color: Colors.red),
                          SizedBox(width: 8),
                          Text('清空所有消息', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'exit',
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app),
                          SizedBox(width: 8),
                          Text('退出频道'),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
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
                      reverse: true,
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _buildMessageListItems().length + 1,
                      itemBuilder: (context, index) {
                        if (index == _buildMessageListItems().length) {
                          return _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : const SizedBox.shrink();
                        }
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
                            channelColor: widget.channel.backgroundColor,
                            isMultiSelectMode: _isMultiSelectMode,
                            isSelected: _selectedMessageIds.contains(item.id),
                            onSelect: () => _toggleMessageSelection(item.id),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
          ),
          if (_isMultiSelectMode)
            SafeArea(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      offset: const Offset(0, -1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _handleMultiMessagesCopy,
                      icon: const Icon(Icons.copy),
                      label: const Text('复制'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _handleMultiMessagesDelete,
                      icon: const Icon(Icons.delete),
                      label: const Text('删除'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            MessageInput(
              onMessageSent: _handleMessageSent,
              controller: _draftController,
              onChanged: _saveDraft,
            ),
        ],
      ),
    );
  }
}
