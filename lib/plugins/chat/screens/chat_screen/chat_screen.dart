import 'package:Memento/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io'; // 添加File类支持
import '../../models/channel.dart';
import '../../models/message.dart';
import '../../chat_plugin.dart';
import '../channel_info_screen.dart';
import '../user_profile_screen.dart';
import '../../utils/message_operations.dart'; // 添加消息操作工具类
// 移除未使用的导入
import 'controllers/chat_screen_controller.dart';
import 'widgets/chat_app_bar.dart';
import 'widgets/message_list.dart';
import 'widgets/message_input.dart';
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
  Message? _replyToMessage; // 添加回复消息引用
  String? _backgroundPath; // 存储背景图片的绝对路径
  bool _isLoadingBackground = true; // 标记背景图片是否正在加载

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
    _loadBackgroundPath();
    _loadChannelDraft();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 初始化消息操作工具类，在didChangeDependencies中初始化以安全地使用context
    _messageOperations = MessageOperations(context);
  }

  Future<void> _loadChannelDraft() async {
    final chatPlugin = ChatPlugin.instance;

    if (!mounted) return;

    // 检查插件是否已初始化
    if (chatPlugin.isInitialized) {
      try {
        final draft = await chatPlugin.channelService.loadDraft(
          widget.channel.id,
        );
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
      _controller.messages =
          ChatPlugin.instance.channelService.channels
              .firstWhere((c) => c.id == widget.channel.id)
              .messages;
    });
  }

  // 处理回复消息
  void _handleReply(Message message) {
    setState(() {
      _replyToMessage = message;
    });
    // 聚焦输入框
    _controller.focusNode.requestFocus();
  }

  // 清除回复
  void _clearReply() {
    setState(() {
      _replyToMessage = null;
    });
  }

  // 处理回复消息点击
  void _handleReplyTap(String messageId) {
    final message = widget.channel.messages.firstWhere(
      (m) => m.id == messageId,
      orElse: () => widget.channel.messages.first,
    );
    _controller.scrollToMessage(message);
  }

  void _showEditDialog(Message message) async {
    if (!mounted) return;
    await _messageOperations.editMessage(message);
    if (mounted) {
      _updateMessages(); // 更新消息列表
    }
  }

  void _showClearConfirmationDialog() {
    showDialog(
      context: context,
      builder:
          (context) => ClearMessagesDialog(
            onConfirm: () async {
              await _controller.clearMessages();
              if (mounted) {
                _updateMessages(); // 更新消息列表
                Navigator.of(context).pop();
              }
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

  /// 删除单条消息并更新状态
  Future<void> _deleteMessage(Message message) async {
    await _messageOperations.deleteMessage(message);
    if (mounted) {
      _updateMessages(); // 更新消息列表
    }
  }

  /// 删除多条选中的消息
  Future<void> _deleteSelectedMessages() async {
    final selectedMessages =
        _controller.messages
            .where((msg) => _controller.selectedMessageIds.contains(msg.id))
            .toList();

    for (var message in selectedMessages) {
      await _deleteMessage(message);
    }

    if (mounted) {
      _controller.toggleMultiSelectMode();
    }
  }

  void _copyMessageToClipboard(Message message) {
    // 使用MessageOperations处理消息复制
    _messageOperations.copyMessage(message);
  }

  Future<void> _setFixedSymbol(Message message, String? symbol) async {
    // 使用MessageOperations设置固定符号
    await _messageOperations.setFixedSymbol(message, symbol);
    if (mounted) {
      _updateMessages(); // 更新消息列表
    }
  }

  Future<void> _setBubbleColor(Message message, Color? color) async {
    // 使用MessageOperations设置气泡颜色
    await _messageOperations.setBubbleColor(message, color);
    if (mounted) {
      _updateMessages(); // 更新消息列表
    }
  }

  void _navigateToUserProfile(Message message) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(user: message.user),
      ),
    );
  }

  // 加载背景图片路径
  Future<void> _loadBackgroundPath() async {
    if (widget.channel.backgroundPath == null) {
      setState(() {
        _backgroundPath = null;
        _isLoadingBackground = false;
      });
      return;
    }

    try {
      final absolutePath = await PathUtils.toAbsolutePath(
        widget.channel.backgroundPath!,
      );

      if (mounted) {
        final file = File(absolutePath);
        final exists = await file.exists();
        setState(() {
          _backgroundPath = absolutePath;
          _isLoadingBackground = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _backgroundPath = null;
          _isLoadingBackground = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用已加载的背景路径构建UI
    return _buildMainUI(_backgroundPath);
  }

  // 构建主UI，接收可选的背景路径参数
  Widget _buildMainUI(String? backgroundPath) {
    // 调试输出当前UI构建状态
    debugPrint(
      'Building UI with background: $backgroundPath, isLoading: $_isLoadingBackground',
    );

    return Scaffold(
      // 根据是否有背景图片决定背景颜色
      backgroundColor:
          backgroundPath != null ? Colors.transparent : Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 默认白色背景 - 当没有背景图片时显示
          if (backgroundPath == null && !_isLoadingBackground)
            Container(
              color: Colors.white,
              width: double.infinity,
              height: double.infinity,
            ),
          // 背景层 - 确保这是Stack中的底层元素
          if (backgroundPath != null && !_isLoadingBackground)
            Builder(
              builder: (context) {
                final file = File(backgroundPath);
                if (!file.existsSync()) {
                  debugPrint(
                    'Background image file does not exist: $backgroundPath',
                  );
                  return const SizedBox.shrink();
                }
                // 使用Container包装图片，确保它占满整个屏幕
                return Container(
                  color: Colors.transparent, // 确保容器背景透明
                  child: Image.file(
                    file,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    // 添加key以强制重建
                    key: ValueKey(backgroundPath),
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Error loading background image: $error');
                      debugPrint('Stack trace: $stackTrace');
                      return Container(
                        color: Colors.red.withOpacity(0.3),
                      ); // 错误时显示红色背景以便调试
                    },
                  ),
                );
              },
            ),
          // 半透明遮罩层
          if (backgroundPath != null && !_isLoadingBackground)
            Container(color: Colors.black.withOpacity(0.5)),
          // 加载指示器
          if (_isLoadingBackground)
            const Center(child: CircularProgressIndicator()),
          // 内容层
          FutureBuilder<List<dynamic>>(
            future: MessageListBuilder.buildMessageListWithDateSeparators(
              _controller.messages,
              _controller.selectedDate,
            ),
            builder: (context, snapshot) {
              final messageItems = snapshot.data ?? [];

              // 根据是否有背景图片决定内容层Scaffold的背景颜色
              return Scaffold(
                backgroundColor:
                    backgroundPath != null
                        ? Colors.transparent
                        : null, // 有背景时透明，无背景时使用默认颜色
                appBar: ChatAppBar(
                  channel: widget.channel,
                  isMultiSelectMode: _controller.isMultiSelectMode,
                  selectedCount: _controller.selectedMessageIds.length,
                  onShowDatePicker: _showDatePickerDialog,
                  onShowChannelInfo: () {
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  ChannelInfoScreen(channel: widget.channel),
                        ),
                      );
                    }
                  },
                  onCopySelected: _copySelectedMessages,
                  onDeleteSelected: _deleteSelectedMessages,
                  onShowClearConfirmation: _showClearConfirmationDialog,
                  onExitMultiSelect: _controller.toggleMultiSelectMode,
                  onEnterMultiSelect: _controller.toggleMultiSelectMode,
                ),
                body: Column(
                  children: [
                    if (_replyToMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withAlpha(51),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '回复 ${_replyToMessage!.user.username}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _replyToMessage!.content,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _clearReply,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: MessageList(
                        items: messageItems,
                        isMultiSelectMode: _controller.isMultiSelectMode,
                        selectedMessageIds: _controller.selectedMessageIds,
                        onMessageEdit: _showEditDialog,
                        onMessageDelete: _deleteMessage,
                        onMessageCopy: _copyMessageToClipboard,
                        onSetFixedSymbol: _setFixedSymbol,
                        onSetBubbleColor: _setBubbleColor,
                        onToggleMessageSelection:
                            _controller.toggleMessageSelection,
                        scrollController: _controller.scrollController,
                        onAvatarTap: _navigateToUserProfile,
                        showAvatar:
                            ChatPlugin
                                .instance
                                .settingsService
                                .showAvatarInChat,
                        currentUserId:
                            ChatPlugin.instance.isInitialized
                                ? ChatPlugin.instance.userService.currentUser.id
                                : '',
                        highlightedMessage: _controller.highlightMessage,
                        shouldHighlight: _controller.highlightMessage != null,
                        onReply: _handleReply,
                        onReplyTap: _handleReplyTap,
                      ),
                    ),
                    MessageInput(
                      controller: _controller.draftController,
                      onSendMessage: (content, {metadata, type, replyTo}) {
                        _controller.sendMessage(
                          content,
                          metadata: metadata,
                          type: type,
                          replyTo: _replyToMessage,
                        );
                        // 发送后清除回复状态
                        if (_replyToMessage != null) {
                          setState(() {
                            _replyToMessage = null;
                          });
                        }
                      },
                      onSaveDraft: _controller.saveDraft,
                      replyTo: _replyToMessage,
                      focusNode: _controller.focusNode,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
