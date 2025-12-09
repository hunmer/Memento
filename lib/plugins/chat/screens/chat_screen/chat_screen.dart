import 'package:Memento/core/plugin_manager.dart';
import 'package:get/get.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/event/event.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';
import 'package:Memento/plugins/openai/screens/agent_edit_screen.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/plugins/openai/handlers/chat_event_handler.dart'; // 导入ValuesEventArgs
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:flutter/services.dart';
import 'dart:io'; // 添加File类支持
import 'package:Memento/plugins/chat/models/channel.dart';
import 'package:Memento/plugins/chat/models/message.dart';
import 'package:Memento/plugins/chat/models/user.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:Memento/plugins/chat/screens/profile_edit_dialog.dart';
import 'package:Memento/plugins/chat/utils/message_operations.dart';
// 移除未使用的导入
import 'controllers/chat_screen_controller.dart';
import 'widgets/chat_app_bar.dart';
import 'widgets/message_list.dart';
import 'widgets/message_input/index.dart';
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
  final eventManager = EventManager.instance; // 获取事件管理器实例

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
    // 添加监听器，当 ChatPlugin 发生变化时重新加载背景
    ChatPlugin.instance.addListener(_handleChatPluginUpdate);
    // 订阅消息更新事件
    eventManager.subscribe('onMessageUpdated', _handleMessageUpdated);
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
  }

  @override
  void dispose() {
    // 移除监听器
    ChatPlugin.instance.removeListener(_handleChatPluginUpdate);
    // 取消订阅消息更新事件
    eventManager.unsubscribe('onMessageUpdated', _handleMessageUpdated);
    _controller.dispose();
    // MessageOperations不需要dispose
    super.dispose();
  }

  // 处理消息更新事件
  void _handleMessageUpdated(EventArgs args) {
    if (args is! ValuesEventArgs<Message, String>) return;

    // 检查更新的消息是否属于当前频道
    final message = args.value1;
    if (message.channelId != widget.channel.id) return;

    // 重新加载消息列表
    _controller.reloadMessages();
  }

  // 处理 ChatPlugin 更新
  void _handleChatPluginUpdate() {
    // 检查当前频道是否更新
    final updatedChannel = ChatPlugin.instance.channelService.channels
        .firstWhere(
          (c) => c.id == widget.channel.id,
          orElse: () => widget.channel,
        );

    // 如果背景路径发生变化，重新加载背景
    if (updatedChannel.backgroundPath != widget.channel.backgroundPath) {
      debugPrint('背景图片已更新，重新加载: ${updatedChannel.backgroundPath}');
      setState(() {
        _isLoadingBackground = true;
      });
      _loadBackgroundPath();

      // 强制重建背景图片
      if (_backgroundPath != null) {
        setState(() {
          // 添加一个随机参数，确保Image.file重新加载
          _backgroundPath =
              "$_backgroundPath?t=${DateTime.now().millisecondsSinceEpoch}";
        });
      }
    }
  }

  // 更新消息列表
  void _updateMessages() {
    _controller.reloadMessages();
  }

  // 处理回复消息
  void _handleReply(Message message) {
    setState(() {
      _replyToMessage = message;
    });
    // 聚焦输入框
    _controller.focusNode.requestFocus();
  }

  // 处理消息收藏
  void _handleToggleFavorite(Message message) async {
    await _messageOperations.toggleFavorite(message);
    if (mounted) {
      _updateMessages(); // 更新消息列表
    }
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
    final BuildContext currentContext = context;
    showDialog(
      context: currentContext,
      builder:
          (BuildContext dialogContext) => ClearMessagesDialog(
            onConfirm: () async {
              await _controller.clearMessages();
              if (!mounted) return;
              _updateMessages(); // 更新消息列表
              if (currentContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            onCancel: () {
              Navigator.of(dialogContext).pop();
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
            .where((msg) => _controller.selectedMessageIds.value.contains(msg.id))
            .toList();

    if (selectedMessages.isEmpty) return;

    final textToCopy = selectedMessages
        .map((msg) => '${msg.user.username}: ${msg.content}')
        .join('\n\n');

    Clipboard.setData(ClipboardData(text: textToCopy));
    Toast.success('chat_copiedSelectedMessages'.tr);

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
            .where((msg) => _controller.selectedMessageIds.value.contains(msg.id))
            .toList();

    for (var message in selectedMessages) {
      await _deleteMessage(message);
    }

    if (mounted) {
      _controller.toggleMultiSelectMode();
    }
  }

  // 加载背景图片路径
  Future<void> _loadBackgroundPath() async {
    // 获取最新的频道数据
    final currentChannel = ChatPlugin.instance.channelService.channels
        .firstWhere(
          (c) => c.id == widget.channel.id,
          orElse: () => widget.channel,
        );

    if (currentChannel.backgroundPath == null) {
      setState(() {
        _backgroundPath = null;
        _isLoadingBackground = false;
      });
      return;
    }

    try {
      final absolutePath = await ImageUtils.getAbsolutePath(
        currentChannel.backgroundPath!,
      );

      if (mounted) {
        final file = File(absolutePath);
        final exists = await file.exists(); // 检查文件是否存在

        if (exists) {
          setState(() {
            _backgroundPath = absolutePath;
            _isLoadingBackground = false;
          });
          debugPrint('背景图片加载成功: $_backgroundPath');
        } else {
          debugPrint('背景图片文件不存在: $absolutePath');
          setState(() {
            _backgroundPath = null;
            _isLoadingBackground = false;
          });
        }
      }
    } catch (e) {
      debugPrint('加载背景图片路径出错: $e');
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
                        color: Colors.red.withAlpha(77),
                      ); // 错误时显示红色背景以便调试
                    },
                  ),
                );
              },
            ),
          // 半透明遮罩层
          if (backgroundPath != null && !_isLoadingBackground)
            Container(color: Colors.black.withAlpha(128)),
          // 加载指示器
          if (_isLoadingBackground)
            const Center(child: CircularProgressIndicator()),
          // 内容层
          ListenableBuilder(
            listenable: _controller,
            builder:
                (context, _) => FutureBuilder<List<dynamic>>(
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
                        selectedCount: _controller.selectedMessageIds.value.length,
                        onShowDatePicker: _showDatePickerDialog,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '回复 ${_replyToMessage!.user.username}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
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
                              selectedMessageIds:
                                  _controller.selectedMessageIds,
                              onMessageEdit: _showEditDialog,
                              onMessageDelete: _controller.deleteMessage,
                              onMessageCopy:
                                  (message) =>
                                      _messageOperations.copyMessage(message),
                              onSetFixedSymbol:
                                  (message, symbol) => _messageOperations
                                      .setFixedSymbol(message, symbol),
                              onSetBubbleColor:
                                  (message, color) => _messageOperations
                                      .setBubbleColor(message, color),
                              onReply: _handleReply,
                              onToggleFavorite: _handleToggleFavorite,
                              onToggleMessageSelection:
                                  _controller.toggleMessageSelection,
                              onReplyTap: _handleReplyTap,
                              scrollController: _controller.scrollController,
                              currentUserId:
                                  ChatPlugin
                                      .instance
                                      .userService
                                      .currentUser
                                      .id,
                              highlightedMessage: widget.highlightMessage,
                              shouldHighlight: widget.highlightMessage != null,
                              onAvatarTap: (message) async {
                                // 检查是否为AI消息
                                final metadata = message.metadata;
                                if (metadata != null &&
                                    metadata.containsKey('isAI') &&
                                    metadata['isAI'] == true &&
                                    metadata.containsKey('agentId')) {
                                  final agentId = metadata['agentId'] as String;

                                  if (mounted) {
                                    try {
                                      // 获取OpenAI插件并转换类型
                                      final openaiPlugin =
                                          PluginManager.instance.getPlugin(
                                                'openai',
                                              )
                                              as OpenAIPlugin;
                                      // 获取agent
                                      final agent = await openaiPlugin
                                          .controller
                                          .getAgent(agentId);
                                      if (agent != null) {
                                        NavigationHelper.push(context, AgentEditScreen(
                                                  agent: agent,),
                                        );
                                      } else {
                                        Toast.error('chat_aiAssistantNotFound'.tr);
                                      }
                                    } catch (e) {
                                      // 插件不可用或类型转换失败时显示提示
                                      Toast.error('无法访问AI编辑界面，OpenAI插件可能未加载');
                                    }
                                  }
                                } else {
                                  // 如果不是AI消息，显示用户资料编辑对话框
                                  final chatPlugin = ChatPlugin.instance;
                                  final users =
                                      chatPlugin.userService.getAllUsers();
                                  final targetUser = users.firstWhere(
                                    (user) => user.id == message.user.id,
                                    orElse: () => message.user,
                                  );

                                  final updatedUser = await showDialog<User>(
                                    context: context,
                                    builder:
                                        (context) => ProfileEditDialog(
                                          user: targetUser,
                                          chatPlugin: chatPlugin,
                                        ),
                                  );

                                  if (updatedUser != null && mounted) {
                                    // 如果是当前用户，则更新当前用户信息
                                    if (targetUser.id ==
                                        chatPlugin.userService.currentUser.id) {
                                      chatPlugin.userService.setCurrentUser(
                                        updatedUser,
                                      );
                                    }
                                    // 否则只更新用户列表中的用户信息
                                    else {
                                      await chatPlugin.userService.updateUser(
                                        updatedUser,
                                      );
                                    }
                                  }
                                }
                              },
                              showAvatar:
                                  ChatPlugin
                                      .instance
                                      .settingsService
                                      .showAvatarInChat,
                            ),
                          ),
                          MessageInput(
                            controller: _controller.draftController,
                            onSendMessage: (
                              content, {
                              metadata,
                              String type = 'text',
                              replyTo,
                            }) {
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
          ),
        ],
      ),
    );
  }
}
