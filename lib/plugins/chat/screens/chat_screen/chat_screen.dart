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
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/plugins/chat/models/channel.dart';
import 'package:Memento/plugins/chat/models/message.dart';
import 'package:Memento/plugins/chat/models/user.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:Memento/plugins/chat/screens/profile_edit_dialog.dart';
import 'package:Memento/plugins/chat/utils/message_operations.dart';
// 移除未使用的导入
import 'controllers/chat_screen_controller.dart';
import 'widgets/message_list.dart';
import 'widgets/message_input/index.dart';
import 'dialogs/clear_messages_dialog.dart';
import 'dialogs/calendar_date_picker_dialog.dart';
import 'utils/message_list_builder.dart';
// SuperCupertino 导航包装器
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper/filter_models.dart';
import 'package:intl/intl.dart';

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

  // 搜索和过滤状态
  String _searchQuery = '';
  final MultiFilterState _filterState = MultiFilterState();
  List<Message> _filteredMessages = [];

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

    // 初始化时设置路由上下文
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateRouteContext();
    });
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
    _filterState.dispose();
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

  void _copySelectedMessages() {
    final selectedMessages =
        _controller.messages
            .where(
              (msg) => _controller.selectedMessageIds.value.contains(msg.id),
            )
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
            .where(
              (msg) => _controller.selectedMessageIds.value.contains(msg.id),
            )
            .toList();

    for (var message in selectedMessages) {
      await _deleteMessage(message);
    }

    if (mounted) {
      _controller.toggleMultiSelectMode();
    }
  }

  /// 更新路由上下文，使"询问当前上下文"功能能获取到当前频道信息
  void _updateRouteContext() {
    RouteHistoryManager.updateCurrentContext(
      pageId: '/chat/channel',
      title: widget.channel.title,
      params: {
        'channelId': widget.channel.id,
        'channelName': widget.channel.title,
      },
    );
  }

  /// 搜索回调
  void _handleSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFiltersAndSearch();
    });
  }

  /// 过滤回调
  void _handleFilterChanged(Map<String, dynamic> filters) {
    debugPrint('Filter changed: $filters');
    // 更新 _filterState 中的值
    filters.forEach((key, value) {
      _filterState.setValue(key, value);
    });
    _applyFiltersAndSearch();
  }

  /// 应用搜索和过滤
  void _applyFiltersAndSearch() {
    List<Message> result = List.from(_controller.messages);

    // 应用搜索
    if (_searchQuery.isNotEmpty) {
      result =
          result.where((msg) {
            return msg.content.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                msg.user.username.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
          }).toList();
    }

    // 应用发送人过滤
    final selectedUser = _filterState.getValue('sender');
    if (selectedUser != null &&
        selectedUser is String &&
        selectedUser.isNotEmpty) {
      result = result.where((msg) => msg.user.id == selectedUser).toList();
    }

    // 应用日期范围过滤
    final dateRange = _filterState.getValue('dateRange');
    if (dateRange != null && dateRange is Map<String, DateTime?>) {
      final startDate = dateRange['start'];
      final endDate = dateRange['end'];

      result =
          result.where((msg) {
            if (startDate != null && msg.date.isBefore(startDate)) return false;
            if (endDate != null) {
              final endOfDay = DateTime(
                endDate.year,
                endDate.month,
                endDate.day,
                23,
                59,
                59,
              );
              if (msg.date.isAfter(endOfDay)) return false;
            }
            return true;
          }).toList();
    }

    // 应用标签过滤
    final selectedTags = _filterState.getValue('tags');
    if (selectedTags != null &&
        selectedTags is List &&
        selectedTags.isNotEmpty) {
      result =
          result.where((msg) {
            final messageTags = msg.metadata?['tags'] as List<String>?;
            if (messageTags == null || messageTags.isEmpty) return false;
            // 检查消息是否包含任意一个选中的标签
            return selectedTags.any((tag) => messageTags.contains(tag));
          }).toList();
    }

    setState(() {
      _filteredMessages = result;
    });
  }

  /// 获取所有唯一用户列表
  List<User> _getAllUsers() {
    final users = <String, User>{};
    for (var message in _controller.messages) {
      users[message.user.id] = message.user;
    }
    return users.values.toList();
  }

  /// 获取所有唯一标签列表
  List<String> _getAllTags() {
    final tags = <String>{};
    for (var message in _controller.messages) {
      final messageTags = message.metadata?['tags'] as List?;
      if (messageTags != null) {
        for (var tag in messageTags) {
          if (tag is String) tags.add(tag);
        }
      }
    }
    return tags.toList()..sort();
  }

  /// 构建过滤器配置
  List<FilterItem> _buildFilterItems() {
    final allUsers = _getAllUsers();
    final allTags = _getAllTags();

    return [
      // 发送人过滤
      FilterItem(
        id: 'sender',
        title: '发送人',
        type: FilterType.custom,
        builder: (context, currentValue, onChanged) {
          return Wrap(
            spacing: 8,
            children:
                allUsers.map((user) {
                  final isSelected = currentValue == user.id;
                  return FilterChip(
                    label: Text(user.username),
                    selected: isSelected,
                    onSelected: (selected) {
                      onChanged(selected ? user.id : null);
                    },
                    showCheckmark: true,
                  );
                }).toList(),
          );
        },
        getBadge: (value) {
          if (value == null) return null;
          final user = allUsers.firstWhere(
            (u) => u.id == value,
            orElse: () => allUsers.first,
          );
          return user.username;
        },
      ),

      // 日期范围过滤
      FilterItem(
        id: 'dateRange',
        title: '日期',
        type: FilterType.dateRange,
        builder: (context, currentValue, onChanged) {
          final Map<String, DateTime?> range =
              currentValue ?? {'start': null, 'end': null};
          final startDate = range['start'];
          final endDate = range['end'];

          return Wrap(
            spacing: 8,
            children: [
              // 开始日期
              ActionChip(
                avatar: Icon(Icons.calendar_today, size: 18),
                label: Text(
                  startDate == null
                      ? '开始日期'
                      : DateFormat('MM/dd').format(startDate),
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    onChanged({'start': picked, 'end': endDate});
                  }
                },
              ),
              // 结束日期
              ActionChip(
                avatar: Icon(Icons.calendar_today, size: 18),
                label: Text(
                  endDate == null
                      ? '结束日期'
                      : DateFormat('MM/dd').format(endDate),
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate ?? DateTime.now(),
                    firstDate: startDate ?? DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    onChanged({'start': startDate, 'end': picked});
                  }
                },
              ),
              // 清除按钮
              if (startDate != null || endDate != null)
                IconButton(
                  icon: Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                ),
            ],
          );
        },
        getBadge: (value) {
          if (value == null) return null;
          final Map<String, DateTime?> range = value;
          final start = range['start'];
          final end = range['end'];
          if (start != null && end != null) {
            return '${DateFormat('MM/dd').format(start)}-${DateFormat('MM/dd').format(end)}';
          } else if (start != null) {
            return '从${DateFormat('MM/dd').format(start)}';
          } else if (end != null) {
            return '至${DateFormat('MM/dd').format(end)}';
          }
          return null;
        },
      ),

      // 标签过滤
      if (allTags.isNotEmpty)
        FilterItem(
          id: 'tags',
          title: '标签',
          type: FilterType.tagsMultiple,
          builder: (context, currentValue, onChanged) {
            final List<String> selectedTags = currentValue ?? [];
            return Wrap(
              spacing: 8,
              children:
                  allTags.map((tag) {
                    final isSelected = selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (selected) {
                        final newTags = List<String>.from(selectedTags);
                        if (selected) {
                          newTags.add(tag);
                        } else {
                          newTags.remove(tag);
                        }
                        onChanged(newTags.isEmpty ? null : newTags);
                      },
                      showCheckmark: true,
                    );
                  }).toList(),
            );
          },
          getBadge: (value) {
            if (value == null || (value as List).isEmpty) return null;
            final tags = value as List<String>;
            return tags.length == 1 ? tags[0] : '${tags.length}个标签';
          },
        ),
    ];
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
          // 使用 SuperCupertinoNavigationWrapper 的主内容
          _buildSuperCupertinoContent(backgroundPath),
        ],
      ),
    );
  }

  /// 构建 SuperCupertinoNavigationWrapper 内容
  Widget _buildSuperCupertinoContent(String? backgroundPath) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        // 获取显示的消息（根据是否有搜索/过滤来决定）
        final displayMessages =
            _searchQuery.isNotEmpty || _filterState.hasAnyFilter
                ? _filteredMessages
                : _controller.messages;

        return FutureBuilder<List<dynamic>>(
          future: MessageListBuilder.buildMessageListWithDateSeparators(
            displayMessages,
            _controller.selectedDate,
          ),
          builder: (context, snapshot) {
            final messageItems = snapshot.data ?? [];
            final messageIndexMap = <String, int>{};
            for (var i = 0; i < displayMessages.length; i++) {
              messageIndexMap[displayMessages[i].id] = i;
            }

            return SuperCupertinoNavigationWrapper(
              title: Text(widget.channel.title),
              largeTitle: widget.channel.title,
              body: _buildChatBody(
                messageItems,
                messageIndexMap,
                displayMessages,
                backgroundPath,
              ),
              enableLargeTitle: true,
              enableSearchBar: true,
              searchPlaceholder: '搜索消息内容、发送人...',
              onSearchChanged: _handleSearchChanged,
              enableMultiFilter: true,
              multiFilterItems: _buildFilterItems(),
              multiFilterBarHeight: 50,
              onMultiFilterChanged: _handleFilterChanged,
              backgroundColor:
                  backgroundPath != null ? Colors.transparent : null,
              actions: _buildActions(),
            );
          },
        );
      },
    );
  }

  /// 构建 Actions 按钮
  List<Widget> _buildActions() {
    if (_controller.isMultiSelectMode) {
      return [
        IconButton(
          icon: const Icon(Icons.copy),
          onPressed: _copySelectedMessages,
          tooltip: '复制选中消息',
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: _deleteSelectedMessages,
          tooltip: '删除选中消息',
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: _controller.toggleMultiSelectMode,
          tooltip: '退出多选模式',
        ),
      ];
    }

    return [
      IconButton(
        icon: const Icon(Icons.select_all),
        onPressed: _controller.toggleMultiSelectMode,
        tooltip: '多选模式',
      ),
      PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'clear') {
            _showClearConfirmationDialog();
          }
        },
        itemBuilder:
            (context) => [
              const PopupMenuItem(value: 'clear', child: Text('清空消息')),
            ],
      ),
    ];
  }

  /// 构建聊天主体内容
  Widget _buildChatBody(
    List<dynamic> messageItems,
    Map<String, int> messageIndexMap,
    List<Message> displayMessages,
    String? backgroundPath,
  ) {
    return Column(
      children: [
        if (_replyToMessage != null)
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withAlpha(51),
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
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _replyToMessage!.content,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            onMessageDelete: _controller.deleteMessage,
            onMessageCopy: (message) => _messageOperations.copyMessage(message),
            onSetFixedSymbol:
                (message, symbol) =>
                    _messageOperations.setFixedSymbol(message, symbol),
            onSetBubbleColor:
                (message, color) =>
                    _messageOperations.setBubbleColor(message, color),
            onReply: _handleReply,
            onToggleFavorite: _handleToggleFavorite,
            onToggleMessageSelection: _controller.toggleMessageSelection,
            onReplyTap: _handleReplyTap,
            scrollController: _controller.scrollController,
            currentUserId: ChatPlugin.instance.userService.currentUser.id,
            highlightedMessage: widget.highlightMessage,
            shouldHighlight: widget.highlightMessage != null,
            messageIndexMap: messageIndexMap,
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
                        PluginManager.instance.getPlugin('openai')
                            as OpenAIPlugin;
                    // 获取agent
                    final agent = await openaiPlugin.controller.getAgent(
                      agentId,
                    );
                    if (agent != null) {
                      NavigationHelper.push(
                        context,
                        AgentEditScreen(agent: agent),
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
                final users = chatPlugin.userService.getAllUsers();
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
                  if (targetUser.id == chatPlugin.userService.currentUser.id) {
                    chatPlugin.userService.setCurrentUser(updatedUser);
                  }
                  // 否则只更新用户列表中的用户信息
                  else {
                    await chatPlugin.userService.updateUser(updatedUser);
                  }
                }
              }
            },
            showAvatar: ChatPlugin.instance.settingsService.showAvatarInChat,
          ),
        ),
        MessageInput(
          controller: _controller.draftController,
          onSendMessage: (content, {metadata, String type = 'text', replyTo}) {
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
    );
  }
}
