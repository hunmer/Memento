import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/channel.dart';
import '../../models/message.dart';
import '../../chat_plugin.dart';
import '../../../../services/image_service.dart';
import '../channel_info_screen.dart';
import '../user_profile_screen.dart';
import '../../utils/message_operations.dart'; // 添加消息操作工具类
// 移除未使用的导入
import 'controllers/chat_screen_controller.dart';
import 'widgets/chat_app_bar.dart';
import 'widgets/message_list.dart';
import 'widgets/message_input.dart';
import 'dialogs/edit_message_dialog.dart';
import 'dialogs/clear_messages_dialog.dart';
import 'dialogs/calendar_date_picker_dialog.dart';
import 'utils/message_list_builder.dart';

class ChatScreen extends StatefulWidget {
  final Channel channel;
  final Message? initialMessage;
  final Message? highlightMessage;
  final bool autoScroll;

  const ChatScreen({
    super.key, 
    required this.channel,
    this.initialMessage,
    this.highlightMessage,
    this.autoScroll = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatScreenController _controller;
  late MessageOperations _messageOperations;
  // 移除未使用的字段

  @override
  void initState() {
    super.initState();
    _controller = ChatScreenController(
      channel: widget.channel,
      chatPlugin: ChatPlugin.instance,
      initialMessage: widget.initialMessage,
      highlightMessage: widget.highlightMessage,
      autoScroll: widget.autoScroll,
    );
    
    // 初始化消息操作工具类
    _messageOperations = MessageOperations(context);

    // 加载频道草稿
    _loadChannelDraft();
  }

  Future<void> _loadChannelDraft() async {
    final chatPlugin = ChatPlugin.instance;

    if (!mounted) return;

    // 检查插件是否已初始化
    if (chatPlugin.isInitialized) {
      try {
        final draft = await chatPlugin.loadDraft(widget.channel.id);
        if (draft != null && draft.isNotEmpty && mounted) {
          setState(() {
            // 检查控制器是否可用
            if (_controller.draftController.text != draft) {
              _controller.draftController.text = draft;
            }
          });
        }
      } catch (e) {
        debugPrint('Error loading draft: $e');
        // 可以在这里添加用户提示
      }
    } else {
      // 如果插件尚未初始化，则延迟加载草稿
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _loadChannelDraft();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    // MessageOperations不需要dispose
    super.dispose();
  }

  // 更新消息列表
  void _updateMessages() {
    setState(() {
      // 重新加载消息
      _controller.messages = ChatPlugin.instance.channels
          .firstWhere((c) => c.id == widget.channel.id)
          .messages;
    });
  }

  void _showEditDialog(Message message) {
    // 使用MessageOperations处理消息编辑
    _messageOperations.editMessage(message);
    // 注意：由于我们使用了统一的消息操作处理器，不再需要自定义对话框
    // 如果需要保留自定义对话框，可以在MessageOperations中添加支持自定义UI的方法
  }

  void _showClearConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => ClearMessagesDialog(
        onConfirm: () async {
          await _controller.clearMessages();
          _updateMessages(); // 更新消息列表
          Navigator.of(context).pop();
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
  void _showDatePickerDialog() {
    // 从消息中提取唯一的日期
    final dates =
        _controller.messages
            .map((msg) {
              return DateTime(msg.date.year, msg.date.month, msg.date.day);
            })
            .toSet()
            .toList();

    // 计算每个日期的消息数量
    final dateCountMap = <DateTime, int>{};
    for (final msg in _controller.messages) {
      final date = DateTime(msg.date.year, msg.date.month, msg.date.day);
      dateCountMap[date] = (dateCountMap[date] ?? 0) + 1;
    }

    // 按日期降序排序
    dates.sort((a, b) => b.compareTo(a));

    showDialog(
      context: context,
      builder:
          (context) => CalendarDatePickerDialog(
            availableDates: dates,
            selectedDate: _controller.selectedDate,
            dateCountMap: dateCountMap,
            onDateSelected: (date) {
              setState(() {
                _controller.selectedDate = date;
              });
            },
          ),
    );
  }

  void _copySelectedMessages() {
    final selectedMessages =
        _controller.messages
            .where((msg) => _controller.selectedMessageIds.contains(msg.id))
            .toList();

    if (selectedMessages.isEmpty) return;

    final textToCopy = selectedMessages
        .map((msg) => '${msg.user.username}: ${msg.content}')
        .join('\n\n');

    Clipboard.setData(ClipboardData(text: textToCopy));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已复制所选消息')));

    _controller.toggleMultiSelectMode();
  }

  void _deleteSelectedMessages() async {
    final selectedMessages =
        _controller.messages
            .where((msg) => _controller.selectedMessageIds.contains(msg.id))
            .toList();

    for (var message in selectedMessages) {
      await _messageOperations.deleteMessage(message);
    }

    _controller.toggleMultiSelectMode();
  }

  void _copyMessageToClipboard(Message message) {
    // 使用MessageOperations处理消息复制
    _messageOperations.copyMessage(message);
  }

  void _setFixedSymbol(Message message, String? symbol) async {
    // 使用MessageOperations设置固定符号
    await _messageOperations.setFixedSymbol(message, symbol);
  }

  void _setBubbleColor(Message message, Color? color) {
    // 使用MessageOperations设置气泡颜色
    _messageOperations.setBubbleColor(message, color);
  }

  void _navigateToUserProfile(Message message) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(user: message.user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final messageItems =
            MessageListBuilder.buildMessageListWithDateSeparators(
              _controller.messages,
              _controller.selectedDate,
            );

        return Scaffold(
          appBar: ChatAppBar(
            channel: widget.channel,
            isMultiSelectMode: _controller.isMultiSelectMode,
            selectedCount: _controller.selectedMessageIds.length,
            onShowDatePicker: _showDatePickerDialog,
            onShowChannelInfo: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ChannelInfoScreen(channel: widget.channel),
                ),
              );
            },
            onCopySelected: _copySelectedMessages,
            onDeleteSelected: _deleteSelectedMessages,
            onShowClearConfirmation: _showClearConfirmationDialog,
            onExitMultiSelect: _controller.toggleMultiSelectMode,
            onEnterMultiSelect: _controller.toggleMultiSelectMode,
          ),
          body: Column(
            children: [
              Expanded(
                child: MessageList(
                  items: messageItems,
                  isMultiSelectMode: _controller.isMultiSelectMode,
                  selectedMessageIds: _controller.selectedMessageIds,
                  onMessageEdit: _showEditDialog,
                  onMessageDelete:
                      (message) => _messageOperations.deleteMessage(message),
                  onMessageCopy: _copyMessageToClipboard,
                  onSetFixedSymbol: _setFixedSymbol,
                  onSetBubbleColor: _setBubbleColor,
                  onToggleMessageSelection: _controller.toggleMessageSelection,
                  scrollController: _controller.scrollController,
                  onAvatarTap: _navigateToUserProfile,
                  showAvatar: ChatPlugin.instance.showAvatarInChat,
                  currentUserId:
                      ChatPlugin.instance.isInitialized
                          ? ChatPlugin.instance.currentUser.id
                          : '',
                  highlightedMessage: _controller.highlightMessage,
                  shouldHighlight: _controller.highlightMessage != null,
                ),
              ),
              MessageInput(
                controller: _controller.draftController,
                onSendMessage: _controller.sendMessage,
                onSaveDraft: _controller.saveDraft,
              ),
            ],
          ),
        );
      },
    );
  }
}
