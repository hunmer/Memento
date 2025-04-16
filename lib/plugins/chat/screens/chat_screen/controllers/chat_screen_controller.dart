import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../../models/channel.dart';
import '../../../models/user.dart';
import '../../../models/message.dart';
import '../../../chat_plugin.dart';
import 'package:audioplayers/audioplayers.dart';

final _logger = Logger('ChatScreenController');

class ChatScreenController extends ChangeNotifier {
  final Channel channel;
  final ChatPlugin chatPlugin;
  final AudioPlayer audioPlayer;
  final ScrollController scrollController = ScrollController();
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

  late User currentUser;

  ChatScreenController({
    required this.channel,
    required this.chatPlugin,
    required this.audioPlayer,
  }) {
    // 初始化时计算并加载最后一页
    _initializeAndLoadLastPage();
    _setupScrollListener();
    _initializeCurrentUser();
  }

  void _initializeAndLoadLastPage() async {
    // 获取最新的消息总数
    final channelIndex = chatPlugin.channels.indexWhere(
      (c) => c.id == channel.id,
    );
    if (channelIndex != -1) {
      final totalMessages = chatPlugin.channels[channelIndex].messages.length;

      // 计算总页数（向上取整）
      final totalPages = (totalMessages / pageSize).ceil();

      // 设置当前页为第一页，显示最新消息
      currentPage = 1;

      _logger.info('Initializing chat screen:');
      _logger.info('- Total messages: $totalMessages');
      _logger.info('- Total pages: $totalPages');
      _logger.info('- Starting at page: $currentPage');

      // 加载第一页消息
      await _loadMessages();

      // 确保滚动到最新消息
      if (messages.isNotEmpty) {
        // 使用延迟以确保布局完成
        Future.delayed(const Duration(milliseconds: 100), () {
          requestScrollToLatest();
        });
      }
    }
  }

  void _initializeCurrentUser() {
    // 这里应该从某个地方获取当前用户信息
    // 暂时使用一个默认用户，你需要根据实际情况修改这里
    currentUser = User(id: 'current_user', username: 'Current User');
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
      final channelIndex = chatPlugin.channels.indexWhere(
        (c) => c.id == channel.id,
      );
      if (channelIndex == -1) {
        _logger.warning('Channel not found in ChatPlugin');
        return;
      }

      // 获取最新的消息列表并按时间倒序排序
      final allMessages = List<Message>.from(
        chatPlugin.channels[channelIndex].messages,
      )..sort((a, b) => b.date.compareTo(a.date));

      // 计算当前页的消息范围
      final totalMessages = allMessages.length;
      final startIndex = (currentPage - 1) * pageSize;
      final endIndex = startIndex + pageSize;

      _logger.info(
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

        _logger.info(
          'Loaded ${pageMessages.length} messages for page $currentPage',
        );
      }

      _updateDatesWithMessages();
    } catch (e) {
      // Handle error
      _logger.warning('Error loading messages: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadMoreMessages() async {
    if (isLoading) return;

    // 获取总消息数
    final channelIndex = chatPlugin.channels.indexWhere(
      (c) => c.id == channel.id,
    );
    if (channelIndex == -1) return;

    final totalMessages = chatPlugin.channels[channelIndex].messages.length;
    final totalPages = (totalMessages / pageSize).ceil();

    _logger.info('Current page: $currentPage, Total pages: $totalPages');

    // 如果还有更早的消息页可以加载
    if (currentPage < totalPages) {
      currentPage++;
      await _loadMessages();
    } else {
      _logger.info('No more messages to load');
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

    final editedMessage = Message(
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
        await chatPlugin.saveMessages(channel.id, messages);
      }
    } catch (e) {
      // Handle error
      _logger.warning('Error updating message: $e');
    } finally {
      messageBeingEdited = null;
      editingController.clear();
      notifyListeners();
    }
  }

  Future<void> deleteMessage(Message message) async {
    try {
      messages.removeWhere((m) => m.id == message.id);
      await chatPlugin.saveMessages(channel.id, messages);
      notifyListeners();
    } catch (e) {
      // Handle error
      _logger.warning('Error deleting message: $e');
    }
  }

  Future<void> setFixedSymbol(Message message, String? symbol) async {
    try {
      final index = messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        message.setFixedSymbol(symbol);
        await chatPlugin.saveMessages(channel.id, messages);
        notifyListeners();
      }
    } catch (e) {
      // Handle error
      _logger.warning('Error setting fixed symbol: $e');
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
      final newMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        user: currentUser,
        date: DateTime.now(),
        type: type ?? MessageType.sent,
        metadata: metadata,
      );

      // 添加消息到本地列表
      messages.insert(0, newMessage);

      // 获取ChatPlugin中的频道索引
      final channelIndex = chatPlugin.channels.indexWhere(
        (c) => c.id == channel.id,
      );
      if (channelIndex != -1) {
        // 直接使用ChatPlugin的addMessage方法，它会同时更新内存和存储
        await chatPlugin.addMessage(channel.id, newMessage);
      } else {
        // 如果找不到频道，则使用旧方法保存
        await chatPlugin.saveMessages(channel.id, messages);
      }

      // 清除草稿
      draftController.clear();
      await chatPlugin.saveDraft(channel.id, '');

      // 请求滚动到最新消息
      requestScrollToLatest();

      // 通知UI更新
      notifyListeners();

      // 在主线程上播放声音
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await audioPlayer.play(AssetSource('audio/msg_sended.mp3'));
        } catch (e) {
          _logger.warning('Error playing audio: $e');
        }
      });
    } catch (e) {
      _logger.warning('Error sending message: $e');
    }
  }

  void saveDraft(String draft) {
    chatPlugin.saveDraft(channel.id, draft);
  }

  Future<void> clearMessages() async {
    try {
      messages.clear();
      await chatPlugin.saveMessages(channel.id, messages);
      notifyListeners();
    } catch (e) {
      // Handle error
      _logger.warning('Error clearing messages: $e');
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    editingController.dispose();
    draftController.dispose();
    super.dispose();
  }
}
