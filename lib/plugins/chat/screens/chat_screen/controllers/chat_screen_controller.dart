import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/plugins/chat/models/channel.dart';
import 'package:Memento/plugins/chat/models/user.dart';
import 'package:Memento/plugins/chat/models/message.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';
import '../../../../../../utils/audio_service.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class ChatScreenController extends ChangeNotifier {
  // 重新加载消息列表
  void reloadMessages() async {
    final channelMessages = await chatPlugin.channelService.getChannelMessages(
      channel.id,
    );
    if (channelMessages != null) {
      // 更新完整消息列表
      allMessages = List<Message>.from(channelMessages)
        ..sort((a, b) => b.date.compareTo(a.date));

      // 重新加载当前显示范围内的消息
      _loadMessagesInRange();
      notifyListeners();
    }
  }

  final Channel channel;
  final ChatPlugin chatPlugin;
  final AutoScrollController scrollController = AutoScrollController();
  final _audioService = AudioService();
  bool _needsScroll = false;
  bool _isNavigatingToMessage = false; // 标记是否正在跳转到消息
  bool _isLocatingMessage = false; // 标记是否正在定位消息

  List<Message> messages = [];
  List<Message> allMessages = []; // 完整消息列表
  bool isMultiSelectMode = false;
  final ValueNotifier<Set<String>> selectedMessageIds = ValueNotifier(
    <String>{},
  );
  DateTime? selectedDate;
  bool isLoading = false;
  static const int pageSize = 50;
  int currentStartIndex = 0; // 当前显示的消息起始索引
  int currentEndIndex = 0; // 当前显示的消息结束索引

  Message? messageBeingEdited;
  final TextEditingController editingController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final TextEditingController draftController = TextEditingController();
  Message? initialMessage;
  Message? highlightMessage;
  bool autoScroll = false;

  late User currentUser;

  ChatScreenController({
    required this.channel,
    required this.chatPlugin,
    this.initialMessage,
    this.highlightMessage,
    this.autoScroll = false,
  }) {
    // 初始化时计算并加载最后一页
    _initializeAndLoadLastPage();
    _setupScrollListener();
    _initializeCurrentUser();
  }

  void _initializeAndLoadLastPage() async {
    // 获取最新的消息总数
    debugPrint('Searching for channel with id: ${channel.id}');
    debugPrint(
      'Available channels: ${chatPlugin.channelService.channels.map((c) => c.id).join(', ')}',
    );
    // 查找当前频道
    if (!chatPlugin.channelService.channels.any((c) => c.id == channel.id)) {
      debugPrint('Channel not found: ${channel.id}');
      return;
    }

    // 获取完整消息列表
    final channelMessages = await chatPlugin.channelService.getChannelMessages(
      channel.id,
    );
    if (channelMessages == null) {
      debugPrint('Channel messages not found');
      return;
    }

    // 按时间倒序排序
    allMessages = List<Message>.from(channelMessages)
      ..sort((a, b) => b.date.compareTo(a.date));

    debugPrint('Total messages: ${allMessages.length}');

    // 如果需要定位到特定消息
    if (initialMessage != null && autoScroll) {
      _isLocatingMessage = true; // 设置定位标志
      final targetIndex = allMessages.indexWhere(
        (m) => m.id == initialMessage!.id,
      );
      if (targetIndex != -1) {
        // 计算显示范围：目标消息前后各 pageSize/2 条消息
        final halfPageSize = (pageSize / 2).floor();
        currentStartIndex = (targetIndex - halfPageSize).clamp(
          0,
          allMessages.length,
        );
        currentEndIndex = (targetIndex + halfPageSize).clamp(
          0,
          allMessages.length,
        );

        // 如果目标消息接近列表末尾，调整显示范围
        if (targetIndex > allMessages.length - halfPageSize) {
          currentStartIndex = (allMessages.length - pageSize).clamp(
            0,
            allMessages.length,
          );
          currentEndIndex = allMessages.length;
        }

        debugPrint(
          'Target message index: $targetIndex, display range: $currentStartIndex-$currentEndIndex',
        );

        // 加载显示范围内的消息
        _loadMessagesInRange();

        // 延迟滚动到目标消息，等待markdown渲染完成
        // 初始延迟100ms用于布局，然后额外延迟500ms用于markdown渲染
        Future.delayed(const Duration(milliseconds: 600), () {
          final displayIndex = targetIndex - currentStartIndex;
          if (displayIndex >= 0 && displayIndex < messages.length) {
            _isNavigatingToMessage = true; // 设置导航标志防止滚动监听干扰
            scrollToMessageAtDisplayIndex(
              displayIndex,
              preferBeforePosition: false,
            );

            // 延迟重置标志，等待滚动动画完成
            Future.delayed(const Duration(milliseconds: 500), () {
              _isNavigatingToMessage = false;
              _isLocatingMessage = false; // 重置定位标志
            });
          }
        });
      } else {
        debugPrint('Target message not found in all messages');
        // 如果没找到目标消息，显示最新消息
        _loadLatestMessages();
      }
    }
    // 如果不需要定位到特定消息，则加载最新消息
    else {
      _loadLatestMessages();
    }
  }

  void _initializeCurrentUser() {
    currentUser = chatPlugin.userService.currentUser;
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      // 如果正在跳转到消息或定位消息，不处理滚动事件
      if (_isNavigatingToMessage || _isLocatingMessage) return;

      // 向上滚动（查看更早的消息）
      if (scrollController.position.pixels <=
          scrollController.position.minScrollExtent + 100) {
        _loadMoreMessagesAtBeginning();
      }
      // 向下滚动（查看更新的消息）
      else if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 100) {
        _loadMoreMessagesAtEnd();
      }
    });
  }

  /// 加载指定范围的消息
  void _loadMessagesInRange() {
    if (isLoading) return;
    isLoading = true;
    notifyListeners();

    try {
      messages.clear();
      final endIndex = currentEndIndex.clamp(0, allMessages.length);
      final startIndex = currentStartIndex.clamp(0, endIndex);

      if (startIndex < endIndex) {
        messages.addAll(allMessages.sublist(startIndex, endIndex));
        debugPrint(
          'Loaded messages range: $startIndex-$endIndex (${messages.length} messages)',
        );
      }

      _updateDatesWithMessages();
    } catch (e) {
      debugPrint('Error loading messages in range: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 加载最新消息
  void _loadLatestMessages() {
    currentStartIndex = 0;
    currentEndIndex = (pageSize).clamp(0, allMessages.length);
    _loadMessagesInRange();

    // 滚动到最新消息
    Future.delayed(const Duration(milliseconds: 100), () {
      requestScrollToLatest();
    });
  }

  /// 在显示列表中滚动到指定索引（使用scroll_to_index）
  Future<void> scrollToMessageAtDisplayIndex(
    int displayIndex, {
    bool preferBeforePosition = false,
  }) async {
    if (displayIndex >= 0 && displayIndex < messages.length) {
      try {
        await scrollController.scrollToIndex(
          displayIndex,
          duration: const Duration(milliseconds: 300),
          preferPosition:
              preferBeforePosition
                  ? AutoScrollPosition.begin
                  : AutoScrollPosition.end,
        );
      } catch (e) {
        debugPrint('滚动到消息索引时发生错误: $e');
        // 备用方法：使用固定位置计算
        scrollController.animateTo(
          displayIndex * 60.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  /// 在开头加载更多消息（向上滚动时）
  void _loadMoreMessagesAtBeginning() {
    if (isLoading) return;

    // 如果已经到达列表开头，不加载更多
    if (currentStartIndex <= 0) {
      return;
    }

    // 计算新的起始索引
    final newStartIndex = (currentStartIndex - pageSize).clamp(
      0,
      allMessages.length,
    );
    currentStartIndex = newStartIndex;

    _loadMessagesInRange();
  }

  /// 在末尾加载更多消息（向下滚动时）
  void _loadMoreMessagesAtEnd() {
    if (isLoading) return;

    // 如果已经到达列表末尾，不加载更多
    if (currentEndIndex >= allMessages.length) {
      debugPrint('Already at the end of messages');
      return;
    }

    // 计算新的结束索引
    final newEndIndex = (currentEndIndex + pageSize).clamp(
      0,
      allMessages.length,
    );
    currentEndIndex = newEndIndex;

    debugPrint('Loading more messages at end, new end index: $currentEndIndex');

    _loadMessagesInRange();
  }

  void _updateDatesWithMessages() {
    if (messages.isEmpty) {
      selectedDate = null;
      notifyListeners();
      return;
    }

    // 默认不选中日期，显示全部消息
    // selectedDate 保持为 null
    notifyListeners();
  }

  void toggleMultiSelectMode() {
    isMultiSelectMode = !isMultiSelectMode;
    if (!isMultiSelectMode) {
      selectedMessageIds.value = {};
    }
    notifyListeners();
  }

  void toggleMessageSelection(String messageId) {
    final newSet = Set<String>.from(selectedMessageIds.value);
    if (newSet.contains(messageId)) {
      newSet.remove(messageId);
    } else {
      newSet.add(messageId);
    }
    selectedMessageIds.value = newSet;
    // 不调用 notifyListeners()，只更新 selectedMessageIds
  }

  // 滚动到指定消息
  Future<void> scrollToMessage(
    Message message, {
    bool preferBeforePosition = false,
  }) async {
    // 在完整消息列表中查找消息
    final targetIndex = allMessages.indexWhere((m) => m.id == message.id);
    if (targetIndex == -1) {
      return;
    }

    _isNavigatingToMessage = true; // 设置标志

    try {
      // 检查消息是否在当前显示范围内
      final displayIndex = targetIndex - currentStartIndex;

      if (displayIndex >= 0 && displayIndex < messages.length) {
        // 消息在当前显示范围内，直接滚动
        scrollToMessageAtDisplayIndex(
          displayIndex,
          preferBeforePosition: preferBeforePosition,
        );
      } else {
        // 消息不在当前显示范围内，调整显示范围
        final halfPageSize = (pageSize / 2).floor();
        currentStartIndex = (targetIndex - halfPageSize).clamp(
          0,
          allMessages.length,
        );
        currentEndIndex = (targetIndex + halfPageSize).clamp(
          0,
          allMessages.length,
        );

        // 如果目标消息接近列表末尾，调整显示范围
        if (targetIndex > allMessages.length - halfPageSize) {
          currentStartIndex = (allMessages.length - pageSize).clamp(
            0,
            allMessages.length,
          );
          currentEndIndex = allMessages.length;
        }

        // 重新加载消息
        _loadMessagesInRange();

        // 等待布局完成后滚动
        Future.delayed(const Duration(milliseconds: 100), () {
          final newDisplayIndex = targetIndex - currentStartIndex;
          scrollToMessageAtDisplayIndex(
            newDisplayIndex,
            preferBeforePosition: preferBeforePosition,
          );
        });
      }
    } catch (e) {
      debugPrint('滚动到消息时发生错误: $e');
    } finally {
      // 延迟重置标志，等待滚动动画完成
      Future.delayed(const Duration(milliseconds: 500), () {
        _isNavigatingToMessage = false;
      });
    }
  }

  void editMessage(Message message) {
    messageBeingEdited = message;
    editingController.text = message.content;
    notifyListeners();
  }

  void cancelEdit() {
    messageBeingEdited = null;
    editingController.clear();
    notifyListeners();
  }

  Future<void> deleteMessage(Message message) async {
    try {
      // 使用 ChannelService 的 deleteMessage 方法正确删除消息
      // 这会从频道的完整消息列表中删除消息并持久化
      final success = await chatPlugin.channelService.deleteMessage(message);

      if (success) {
        // 同步更新控制器中的消息列表
        messages.removeWhere((m) => m.id == message.id);
        notifyListeners();
      }
    } catch (e) {
      // Handle error
      debugPrint('Error deleting message: $e');
    }
  }

  /// 请求滚动到最新消息
  void requestScrollToLatest() {
    // 如果正在定位消息，不执行自动滚动
    if (_isLocatingMessage) {
      return;
    }

    _needsScroll = true;
    _tryScrollToLatest();
  }

  /// 尝试滚动到最新消息（使用scroll_to_index）
  Future<void> _tryScrollToLatest() async {
    // 如果不需要滚动，直接返回
    if (!_needsScroll) return;

    // 如果正在定位消息，取消滚动
    if (_isLocatingMessage) {
      _needsScroll = false;
      return;
    }

    // 如果ScrollController还没有附加到视图，等待下一帧
    if (!scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryScrollToLatest());
      return;
    }

    // 执行滚动到最新消息（索引0）
    try {
      await scrollController.scrollToIndex(
        0,
        duration: const Duration(milliseconds: 300),
        preferPosition: AutoScrollPosition.begin,
      );
      // 滚动成功后重置标志
      _needsScroll = false;
    } catch (e) {
      debugPrint('滚动到最新消息时发生错误: $e');
      // 如果滚动失败，在下一帧重试
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryScrollToLatest());
    }
  }

  Future<void> sendMessage(
    String content, {
    Map<String, dynamic>? metadata,
    String type = 'text',
    Message? replyTo,
  }) async {
    MessageType messageType;
    switch (type) {
      case 'sent':
        messageType = MessageType.sent;
        break;
      case 'received':
        messageType = MessageType.received;
        break;
      case 'file':
        messageType = MessageType.file;
        break;
      case 'image':
        messageType = MessageType.image;
        break;
      case 'video':
        messageType = MessageType.video;
        break;
      case 'audio':
        messageType = MessageType.audio;
        break;
      default:
        messageType = MessageType.sent;
    }
    if (content.trim().isEmpty) return;

    try {
      final newMessage = await Message.create(
        id: const Uuid().v4(),
        content: content,
        channelId: channel.id,
        user: currentUser,
        date: DateTime.now(),
        type: messageType,
        metadata: metadata,
        replyTo: replyTo,
      );

      // 将新消息添加到本地消息列表
      messages.insert(0, newMessage);

      // 确保消息被添加到频道
      await chatPlugin.channelService.addMessage(channel.id, newMessage);

      // 清除草稿
      draftController.clear();
      await chatPlugin.channelService.saveDraft(channel.id, '');

      // 请求滚动到最新消息
      // 如果之前在定位消息，发送新消息后应该恢复正常的自动滚动
      _isLocatingMessage = false;
      requestScrollToLatest();

      // 确保在主线程中更新UI
      notifyListeners();

      // 根据设置决定是否播放提示音
      if (chatPlugin.settingsService.shouldPlayMessageSound()) {
        // 在主线程上播放声音
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            await _audioService.playMessageSentSound();
          } catch (e) {
            debugPrint('Error playing audio: $e');
          }
        });
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  void saveDraft(String draft) {
    chatPlugin.channelService.saveDraft(channel.id, draft);
  }

  Future<void> clearMessages() async {
    try {
      // 清空内存中的消息
      messages.clear();

      // 删除存储中的消息
      await chatPlugin.channelService.deleteChannelMessages(channel.id);

      // 保存空消息列表到存储
      await chatPlugin.channelService.saveMessages(channel.id, messages);

      // 消息发送完成后，确保在主线程中更新UI
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error clearing messages: $e');
      // 如果清空失败，重新加载最新消息
      _loadLatestMessages();
    }
  }

  @override
  void dispose() {
    draftController.dispose();
    scrollController.dispose();
    focusNode.dispose();
    selectedMessageIds.dispose();
    super.dispose();
  }
}
