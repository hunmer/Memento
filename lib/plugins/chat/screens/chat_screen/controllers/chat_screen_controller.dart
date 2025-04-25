import 'package:flutter/material.dart';
import '../../../models/channel.dart';
import '../../../models/user.dart';
import '../../../models/message.dart';
import '../../../chat_plugin.dart';
import '../../../../../../utils/audio_service.dart';

class ChatScreenController extends ChangeNotifier {
  final Channel channel;
  final ChatPlugin chatPlugin;
  final ScrollController scrollController = ScrollController();
  final _audioService = AudioService();
  bool _needsScroll = false;

  List<Message> messages = [];
  bool isMultiSelectMode = false;
  Set<String> selectedMessageIds = <String>{};
  DateTime? selectedDate;
  bool isLoading = false;
  static const int pageSize = 50;
  int currentPage = 1;

  Message? messageBeingEdited;
  final TextEditingController editingController = TextEditingController();
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
      'Available channels: ${chatPlugin.channelService.channels.map((c) => '${c.id}').join(', ')}',
    );
    final channelIndex = chatPlugin.channelService.channels.indexWhere(
      (c) => c.id == channel.id,
    );
    print('Found channel at index: $channelIndex');
    if (channelIndex != -1) {
      final totalMessages = chatPlugin.channelService.channels[channelIndex].messages.length;

      // 计算总页数（向上取整）
      final totalPages = (totalMessages / pageSize).ceil();

      // 设置当前页为第一页，显示最新消息
      currentPage = 1;

      debugPrint('Initializing chat screen:');
      debugPrint('- Total messages: $totalMessages');
      debugPrint('- Total pages: $totalPages');
      debugPrint('- Starting at page: $currentPage');

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
  }

  void _initializeCurrentUser() {
    try {
      // 检查 ChatPlugin 是否已初始化
      if (chatPlugin.isInitialized) {
        currentUser = chatPlugin.userService.currentUser;
      } else {
        // 如果 ChatPlugin 尚未初始化，使用一个默认用户并稍后重试
        currentUser = User(id: 'current_user', username: 'Current User');

        // 延迟重试获取当前用户
        Future.delayed(const Duration(milliseconds: 500), () {
          if (chatPlugin.isInitialized) {
        currentUser = chatPlugin.userService.currentUser;
            notifyListeners();
          }
        });
      }
    } catch (e) {
      debugPrint('Error initializing current user: $e');
      // 使用默认用户作为备选
      currentUser = User(id: 'current_user', username: 'Current User');
    }
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
      debugPrint('Loading messages - Searching for channel with id: ${channel.id}');
      debugPrint(
        'Available channels: ${chatPlugin.channelService.channels.map((c) => '${c.id}').join(', ')}',
      );
      final channelIndex = chatPlugin.channelService.channels.indexWhere(
        (c) => c.id == channel.id,
      );
      debugPrint('Found channel at index: $channelIndex');
      if (channelIndex == -1) {
        debugPrint('Channel not found in ChatPlugin');
        return;
      }

      // 获取最新的消息列表并按时间倒序排序
      final allMessages = List<Message>.from(
        chatPlugin.channelService.channels[channelIndex].messages,
      )..sort((a, b) => b.date.compareTo(a.date));

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

        debugPrint('Loaded ${pageMessages.length} messages for page $currentPage');
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

    // 获取总消息数
    final channelIndex = chatPlugin.channelService.channels.indexWhere(
      (c) => c.id == channel.id,
    );
    if (channelIndex == -1) return;

    final totalMessages = chatPlugin.channelService.channels[channelIndex].messages.length;
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
      selectedMessageIds.clear();
    }
    notifyListeners();
  }

  void toggleMessageSelection(String messageId) {
    if (selectedMessageIds.contains(messageId)) {
      selectedMessageIds.remove(messageId);
    } else {
      selectedMessageIds.add(messageId);
    }
    notifyListeners();
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

  Future<void> saveEditedMessage() async {
    if (messageBeingEdited == null) return;

    final editedMessage = await Message.create(
      id: messageBeingEdited!.id,
      content: editingController.text,
      user: messageBeingEdited!.user,
      date: messageBeingEdited!.date,
      type: messageBeingEdited!.type,
      editedAt: DateTime.now(),
    );

    try {
      final index = messages.indexWhere((m) => m.id == editedMessage.id);
      if (index != -1) {
        messages[index] = editedMessage;
        await chatPlugin.channelService.saveMessages(channel.id, messages);
      }
    } catch (e) {
      // Handle error
      debugPrint('Error updating message: $e');
    } finally {
      messageBeingEdited = null;
      editingController.clear();
      notifyListeners();
    }
  }

  Future<void> deleteMessage(Message message) async {
    try {
      messages.removeWhere((m) => m.id == message.id);
      await chatPlugin.channelService.saveMessages(channel.id, messages);
      notifyListeners();
    } catch (e) {
      // Handle error
      debugPrint('Error deleting message: $e');
    }
  }

  Future<void> setFixedSymbol(Message message, String? symbol) async {
    try {
      final index = messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        message.setFixedSymbol(symbol);
        await chatPlugin.channelService.saveMessages(channel.id, messages);
        notifyListeners();
      }
    } catch (e) {
      // Handle error
      debugPrint('Error setting fixed symbol: $e');
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
    MessageType? type,
  }) async {
    if (content.trim().isEmpty) return;

    try {
      final newMessage = await Message.create(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        user: currentUser,
        date: DateTime.now(),
        type: type ?? MessageType.sent,
        metadata: metadata,
      );

      // 获取ChatPlugin中的频道索引
      debugPrint('Sending message - Searching for channel with id: ${channel.id}');
      debugPrint(
        'Available channels: ${chatPlugin.channelService.channels.map((c) => '${c.id}').join(', ')}',
      );
      final channelIndex = chatPlugin.channelService.channels.indexWhere(
        (c) => c.id == channel.id,
      );
      debugPrint('Found channel at index: $channelIndex');
      if (channelIndex != -1) {
        // 直接使用ChatPlugin的addMessage方法，它会同时更新内存和存储
        await chatPlugin.channelService.addMessage(channel.id, Future.value(newMessage));
        
        // 更新本地消息列表，与服务中的保持一致
        messages = List<Message>.from(chatPlugin.channelService.channels[channelIndex].messages)
          ..sort((a, b) => b.date.compareTo(a.date));
      } else {
        // 如果找不到频道，则先添加到本地列表，再使用旧方法保存
        messages.insert(0, newMessage);
        await chatPlugin.channelService.saveMessages(channel.id, messages);
      }

      // 清除草稿
      draftController.clear();
      await chatPlugin.channelService.saveDraft(channel.id, '');

      // 请求滚动到最新消息
      requestScrollToLatest();

      // 通知UI更新
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

      // 通知UI更新
      notifyListeners();

      debugPrint('Messages cleared successfully');
    } catch (e) {
      debugPrint('Error clearing messages: $e');
      // 如果清空失败，重新加载消息
      await _loadMessages();
    }
  }

  Future<void> setBubbleColor(Message message, Color? color) async {
    try {
      final index = messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        // 创建消息的新副本并更新颜色
        messages[index] = await messages[index].copyWith(bubbleColor: color);

        // 获取ChatPlugin中的频道索引
        debugPrint(
          'Setting bubble color - Searching for channel with id: ${channel.id}',
        );
        debugPrint(
          'Available channels: ${chatPlugin.channelService.channels.map((c) => '${c.id}').join(', ')}',
        );
        final channelIndex = chatPlugin.channelService.channels.indexWhere(
          (c) => c.id == channel.id,
        );
        print('Found channel at index: $channelIndex');

        if (channelIndex != -1) {
          // 保存到存储
          await chatPlugin.channelService.saveMessages(channel.id, messages);
          debugPrint('Successfully updated bubble color for message ${message.id}');
        } else {
          debugPrint('Channel not found in ChatPlugin');
        }

        // 通知监听器更新UI
        notifyListeners();
      } else {
        debugPrint('Message not found in the list');
      }
    } catch (e) {
      debugPrint('Error setting bubble color: $e');
      // 可以在这里添加错误处理，比如显示一个提示
    }
  }

  Future<void> _loadUntilMessageFound() async {
    if (initialMessage == null) return;

    final channelIndex = chatPlugin.channelService.channels.indexWhere(
      (c) => c.id == channel.id,
    );
    if (channelIndex == -1) return;

    final allMessages = chatPlugin.channelService.channels[channelIndex].messages;
    final targetMessageIndex = allMessages.indexWhere(
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
    scrollController.dispose();
    editingController.dispose();
    draftController.dispose();
    _audioService.dispose();
    super.dispose();
  }
}
