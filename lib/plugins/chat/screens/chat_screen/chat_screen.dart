import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/channel.dart';
import '../../models/message.dart';
import '../../chat_plugin.dart';
import '../../../../services/image_service.dart';
import '../channel_info_screen.dart';
import 'package:audioplayers/audioplayers.dart';

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

  const ChatScreen({super.key, required this.channel});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatScreenController _controller;
  final ImageService _imageService = ImageService();

  @override
  void initState() {
    super.initState();
    _controller = ChatScreenController(
      channel: widget.channel,
      chatPlugin: ChatPlugin.instance,
      audioPlayer: AudioPlayer(),
    );
    
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
        if (draft != null && 
            draft.isNotEmpty && 
            mounted) {
          setState(() {
            // 增加额外的空值检查
            if (_controller.draftController.hasListeners) {
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
    super.dispose();
  }

  void _showEditDialog(Message message) {
    _controller.editMessage(message);
    showDialog(
      context: context,
      builder: (context) => EditMessageDialog(
        message: message,
        controller: _controller.editingController,
        onCancel: () {
          _controller.cancelEdit();
          Navigator.of(context).pop();
        },
        onSave: () {
          _controller.saveEditedMessage();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showClearConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => ClearMessagesDialog(
        onConfirm: () {
          _controller.clearMessages();
          Navigator.of(context).pop();
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showDatePickerDialog() {
    // 从消息中提取唯一的日期
    final dates = _controller.messages.map((msg) {
      return DateTime(msg.date.year, msg.date.month, msg.date.day);
    }).toSet().toList();
    
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
      builder: (context) => CalendarDatePickerDialog(
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
    final selectedMessages = _controller.messages
        .where((msg) => _controller.selectedMessageIds.contains(msg.id))
        .toList();
    
    if (selectedMessages.isEmpty) return;

    final textToCopy = selectedMessages
        .map((msg) => '${msg.user.username}: ${msg.content}')
        .join('\n\n');
    
    Clipboard.setData(ClipboardData(text: textToCopy));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制所选消息')),
    );
    
    _controller.toggleMultiSelectMode();
  }

  void _deleteSelectedMessages() async {
    final selectedMessages = _controller.messages
        .where((msg) => _controller.selectedMessageIds.contains(msg.id))
        .toList();
    
    for (var message in selectedMessages) {
      await _controller.deleteMessage(message);
    }
    
    _controller.toggleMultiSelectMode();
  }

  void _copyMessageToClipboard(Message message) {
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制消息内容')),
    );
  }

  void _setFixedSymbol(Message message, String? symbol) async {
    await _controller.setFixedSymbol(message, symbol);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final messageItems = MessageListBuilder.buildMessageListWithDateSeparators(
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
                  builder: (context) => ChannelInfoScreen(channel: widget.channel),
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
                  onMessageDelete: (message) => _controller.deleteMessage(message),
                  onMessageCopy: _copyMessageToClipboard,
                  onSetFixedSymbol: _setFixedSymbol,
                  onToggleMessageSelection: _controller.toggleMessageSelection,
                  scrollController: _controller.scrollController,
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