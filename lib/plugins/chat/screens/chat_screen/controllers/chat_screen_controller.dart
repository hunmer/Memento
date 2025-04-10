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
    _loadMessages();
    _setupScrollListener();
    _initializeCurrentUser();
    
    // 在初始化完成后请求滚动到最新消息
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (messages.isNotEmpty) {
        requestScrollToLatest();
      }
    });
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
      // 从ChatPlugin加载最新的消息，而不是使用传入的channel.messages
      final channelIndex = chatPlugin.channels.indexWhere((c) => c.id == channel.id);
      if (channelIndex == -1) {
        _logger.warning('Channel not found in ChatPlugin');
        return;
      }
      
      // 获取最新的消息列表
      final latestMessages = chatPlugin.channels[channelIndex].messages;
      
      // 清空现有消息，确保不会重复
      if (currentPage == 1) {
        messages.clear();
      }
      
      // 分页加载消息
      final startIndex = (currentPage - 1) * pageSize;
      final endIndex = startIndex + pageSize;
      
      if (startIndex < latestMessages.length) {
        final newMessages = latestMessages.sublist(
          startIndex,
          endIndex < latestMessages.length ? endIndex : latestMessages.length,
        );
        messages.addAll(newMessages);
      }
      
      _updateDatesWithMessages();
      
      // 在加载完消息后请求滚动到最新位置
      if (currentPage == 1) {
        requestScrollToLatest();
      }
    } catch (e) {
      // Handle error
      _logger.warning('Error loading messages: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadMoreMessages() async {
    currentPage++;
    await _loadMessages();
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

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    
    try {
      final newMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        user: currentUser,
        date: DateTime.now(),
        type: MessageType.sent,
      );
      
      // 添加消息到本地列表
      messages.insert(0, newMessage);
      
      // 获取ChatPlugin中的频道索引
      final channelIndex = chatPlugin.channels.indexWhere((c) => c.id == channel.id);
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