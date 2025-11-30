import 'package:flutter/material.dart';
import '../../../models/channel.dart';
import '../../../models/user.dart';
import '../../../models/message.dart';
import '../../../chat_plugin.dart';
import '../../../../../../utils/audio_service.dart';

class ChatScreenController extends ChangeNotifier {
  // 重新加载消息列表
  void reloadMessages() async {
    final channelMessages = await chatPlugin.channelService.getChannelMessages(
      channel.id,
    );
    if (channelMessages != null) {
      messages = List<Message>.from(channelMessages)
        ..sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    }
  }

  final Channel channel;
  final ChatPlugin chatPlugin;
  final ScrollController scrollController = ScrollController();
  final _audioService = AudioService();
  bool _needsScroll = false;

  List<Message> messages = [];
  bool isMultiSelectMode = false;
  final ValueNotifier<Set<String>> selectedMessageIds = ValueNotifier(<String>{});
  DateTime? selectedDate;
  bool isLoading = false;
  static const int pageSize = 50;
  int currentPage = 1;

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

    // 加载第一页消息
    await _loadMessages();

    // 如果需要定位到特定消息
    if (initialMessage != null && autoScroll) {
      // 查找消息在列表中的位置
      final messageIndex = messages.indexWhere(
        (m) => m.id == initialMessage!.id,
      );
      if (messageIndex != -1) {
        // 使用延迟以确保布局完成
        Future.delayed(const Duration(milliseconds: 100), () {
          if (scrollController.hasClients) {
            // 计算消息的位置并滚动
            final itemHeight = 80.0; // 估计每个消息项的高度
            final offset = messageIndex * itemHeight;
            scrollController.jumpTo(offset);
          }
        });
      } else {
        // 如果消息不在当前页，加载更多页直到找到目标消息
        _loadUntilMessageFound();
      }
    }
    // 如果不需要定位到特定消息，则滚动到最新消息
    else if (messages.isNotEmpty) {
      // 使用延迟以确保布局完成
      Future.delayed(const Duration(milliseconds: 100), () {
        requestScrollToLatest();
      });
    }
  }

  void _initializeCurrentUser() {
    currentUser = chatPlugin.userService.currentUser;
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        _loadMoreMessages();
      }
    });
  }

  Future<void> _loadMessages() async {
    if (isLoading) return;
    isLoading = true;
    notifyListeners();

    try {
      // 从ChatPlugin加载最新的消息
      debugPrint('Loading messages for channel: ${channel.id}');

      // 获取频道消息
      final channelMessages = await chatPlugin.channelService
          .getChannelMessages(channel.id);
      if (channelMessages == null) {
        debugPrint('Channel not found in ChatPlugin');
        return;
      }

      // 获取最新的消息列表并按时间倒序排序
      final allMessages = List<Message>.from(channelMessages)
        ..sort((a, b) => b.date.compareTo(a.date));

      // 计算当前页的消息范围
      final totalMessages = allMessages.length;
      final startIndex = (currentPage - 1) * pageSize;
      final endIndex = startIndex + pageSize;

      debugPrint(
        'Loading messages: Page $currentPage, Total: $totalMessages, Range: $startIndex-$endIndex',
      );

      // 确保不会超出范围
      if (startIndex < totalMessages) {
        final pageMessages = allMessages.sublist(
          startIndex,
          endIndex < totalMessages ? endIndex : totalMessages,
        );

        // 如果是第一页，清空现有消息
        if (currentPage == 1) {
          messages.clear();
          messages.addAll(pageMessages);
          // 第一页加载完成后滚动到顶部
          requestScrollToLatest();
        } else {
          // 如果是加载更多消息，添加到现有消息列表末尾
          messages.addAll(pageMessages);
        }

        debugPrint(
          'Loaded ${pageMessages.length} messages for page $currentPage',
        );
      }

      _updateDatesWithMessages();
    } catch (e) {
      // Handle error
      debugPrint('Error loading messages: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadMoreMessages() async {
    if (isLoading) return;

    // 获取频道消息
    final channelMessages = await chatPlugin.channelService.getChannelMessages(
      channel.id,
    );
    if (channelMessages == null) return;

    final totalMessages = channelMessages.length;
    final totalPages = (totalMessages / pageSize).ceil();

    debugPrint('Current page: $currentPage, Total pages: $totalPages');

    // 如果还有更早的消息页可以加载
    if (currentPage < totalPages) {
      currentPage++;
      await _loadMessages();
    } else {
      debugPrint('No more messages to load');
    }
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
  void scrollToMessage(Message message) {
    final index = messages.indexOf(message);
    if (index != -1) {
      // 计算目标位置，考虑日期分隔符
      int targetIndex = index;
      for (int i = 0; i < index; i++) {
        if (messages[i] is DateTime) {
          targetIndex++;
        }
      }

      // 反转列表中的索引
      final reversedIndex = messages.length - 1 - targetIndex;

      // 滚动到目标位置
      scrollController.animateTo(
        reversedIndex * 60.0, // 估计每个消息的高度为60
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
      } else {
        debugPrint('Failed to delete message: ${message.id}');
      }
    } catch (e) {
      // Handle error
      debugPrint('Error deleting message: $e');
    }
  }

  /// 请求滚动到最新消息
  void requestScrollToLatest() {
    _needsScroll = true;
    _tryScrollToLatest();
  }

  /// 尝试滚动到最新消息
  void _tryScrollToLatest() {
    // 如果不需要滚动，直接返回
    if (!_needsScroll) return;

    // 如果ScrollController还没有附加到视图，等待下一帧
    if (!scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryScrollToLatest());
      return;
    }

    // 执行滚动
    try {
      scrollController.jumpTo(0);
      // 滚动成功后重置标志
      _needsScroll = false;
    } catch (e) {
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
        id: DateTime.now().millisecondsSinceEpoch.toString(),
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

      debugPrint('Messages cleared successfully');
    } catch (e) {
      debugPrint('Error clearing messages: $e');
      // 如果清空失败，重新加载消息
      await _loadMessages();
    }
  }

  Future<void> _loadUntilMessageFound() async {
    if (initialMessage == null) return;

    // 获取频道消息
    final channelMessages = await chatPlugin.channelService.getChannelMessages(
      channel.id,
    );
    if (channelMessages == null) return;

    final targetMessageIndex = channelMessages.indexWhere(
      (m) => m.id == initialMessage!.id,
    );

    if (targetMessageIndex == -1) return;

    // 计算目标消息所在的页码
    final targetPage = (targetMessageIndex / pageSize).ceil();

    // 加载直到目标页
    while (currentPage < targetPage) {
      currentPage++;
      await _loadMessages();
    }

    // 等待布局完成后滚动到目标消息
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        final messageIndex = messages.indexWhere(
          (m) => m.id == initialMessage!.id,
        );
        if (messageIndex != -1) {
          final itemHeight = 80.0; // 估计每个消息项的高度
          final offset = messageIndex * itemHeight;
          scrollController.jumpTo(offset);
        }
      }
    });
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
