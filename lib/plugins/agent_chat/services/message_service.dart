import 'package:flutter/foundation.dart';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/plugins/agent_chat/models/chat_message.dart';
import 'token_counter_service.dart';
import 'widget_service.dart';

/// 消息服务
///
/// 管理聊天消息的CRUD操作
class MessageService extends ChangeNotifier {
  final StorageManager storage;

  /// 会话ID -> 消息列表的缓存
  final Map<String, List<ChatMessage>> _messageCache = {};

  /// 当前正在查看的会话ID
  String? _currentConversationId;

  MessageService({required this.storage});

  /// 获取当前会话的消息列表
  List<ChatMessage> get currentMessages {
    if (_currentConversationId == null) return [];
    return _messageCache[_currentConversationId] ?? [];
  }

  /// 设置当前会话
  Future<void> setCurrentConversation(String conversationId) async {
    _currentConversationId = conversationId;
    if (!_messageCache.containsKey(conversationId)) {
      await _loadMessages(conversationId);
    }
    notifyListeners();
  }

  /// 加载指定会话的消息
  Future<void> _loadMessages(String conversationId) async {
    try {
      final data = await storage.read('agent_chat/messages/$conversationId');
      if (data is List) {
        final messages = data
            .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
            .toList();
        _messageCache[conversationId] = messages;
      } else {
        _messageCache[conversationId] = [];
      }
    } catch (e) {
      debugPrint('加载消息失败: $e');
      _messageCache[conversationId] = [];
    }
  }

  /// 保存指定会话的消息
  Future<void> _saveMessages(String conversationId) async {
    try {
      final messages = _messageCache[conversationId] ?? [];
      final data = messages.map((m) => m.toJson()).toList();
      await storage.write('agent_chat/messages/$conversationId', data);
    } catch (e) {
      debugPrint('保存消息失败: $e');
    }
  }

  // ========== 消息操作 ==========

  /// 添加消息
  Future<void> addMessage(ChatMessage message) async {
    final conversationId = message.conversationId;

    // 确保消息列表已加载
    if (!_messageCache.containsKey(conversationId)) {
      await _loadMessages(conversationId);
    }

    _messageCache[conversationId]!.add(message);
    await _saveMessages(conversationId);
    notifyListeners();

    // 更新桌面小组件
    AgentChatWidgetService.updateWidget();
  }

  /// 更新消息
  Future<void> updateMessage(ChatMessage message) async {
    final conversationId = message.conversationId;
    final messages = _messageCache[conversationId];

    if (messages != null) {
      final index = messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        messages[index] = message;
        await _saveMessages(conversationId);
        notifyListeners();
      }
    }
  }

  /// 删除消息
  Future<void> deleteMessage(String conversationId, String messageId) async {
    final messages = _messageCache[conversationId];

    if (messages != null) {
      messages.removeWhere((m) => m.id == messageId);
      await _saveMessages(conversationId);
      notifyListeners();
    }
  }

  /// 清空指定会话的所有消息
  Future<void> clearAllMessages(String conversationId) async {
    _messageCache[conversationId] = [];
    await _saveMessages(conversationId);
    notifyListeners();
  }

  /// 获取指定会话的消息列表
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    if (!_messageCache.containsKey(conversationId)) {
      await _loadMessages(conversationId);
    }
    return _messageCache[conversationId] ?? [];
  }

  /// 获取单条消息
  ChatMessage? getMessage(String conversationId, String messageId) {
    final messages = _messageCache[conversationId];
    if (messages == null) return null;

    try {
      return messages.firstWhere((m) => m.id == messageId);
    } catch (e) {
      return null;
    }
  }

  /// 获取指定消息的子消息列表
  List<ChatMessage> getChildMessages(String conversationId, String parentId) {
    final messages = _messageCache[conversationId];
    if (messages == null) return [];

    return messages.where((m) => m.parentId == parentId).toList();
  }

  /// 获取所有顶级消息（没有父消息的消息）
  List<ChatMessage> getTopLevelMessages(String conversationId) {
    final messages = _messageCache[conversationId];
    if (messages == null) return [];

    return messages.where((m) => m.parentId == null).toList();
  }

  /// 获取最后N条消息（用于上下文）
  List<ChatMessage> getLastMessages(String conversationId, int count) {
    final messages = _messageCache[conversationId] ?? [];
    if (messages.isEmpty) return [];

    final startIndex = messages.length - count;
    if (startIndex <= 0) return messages;

    return messages.sublist(startIndex);
  }

  /// 清空会话的所有消息
  Future<void> clearMessages(String conversationId) async {
    _messageCache[conversationId] = [];
    await _saveMessages(conversationId);
    notifyListeners();
  }

  // ========== 高级操作 ==========

  /// 编辑消息
  Future<void> editMessage(
    String conversationId,
    String messageId,
    String newContent,
  ) async {
    final message = getMessage(conversationId, messageId);
    if (message != null && message.isUser) {
      // 只能编辑用户消息
      final tokenCount = TokenCounterService.estimateTokenCount(newContent);
      final updated = message.markAsEdited(newContent).copyWith(
            tokenCount: tokenCount,
          );
      await updateMessage(updated);
    }
  }

  /// 重新生成AI回复（删除指定用户消息后的所有AI回复）
  Future<void> prepareRegenerate(
    String conversationId,
    String userMessageId,
  ) async {
    final messages = _messageCache[conversationId];
    if (messages == null) return;

    // 找到用户消息的索引
    final userMsgIndex = messages.indexWhere((m) => m.id == userMessageId);
    if (userMsgIndex == -1) return;

    // 删除该消息之后的所有AI回复
    final messagesToKeep = <ChatMessage>[];
    for (var i = 0; i <= userMsgIndex; i++) {
      messagesToKeep.add(messages[i]);
    }

    _messageCache[conversationId] = messagesToKeep;
    await _saveMessages(conversationId);
    notifyListeners();
  }

  /// 更新AI消息的生成状态
  Future<void> updateAIMessageContent(
    String conversationId,
    String messageId,
    String content,
    int tokenCount,
  ) async {
    final message = getMessage(conversationId, messageId);
    if (message != null && !message.isUser) {
      final updated = message.copyWith(
        content: content,
        tokenCount: tokenCount,
      );
      await updateMessage(updated);
    }
  }

  /// 完成AI消息生成
  Future<void> completeAIMessage(
    String conversationId,
    String messageId,
  ) async {
    final message = getMessage(conversationId, messageId);
    if (message != null && !message.isUser) {
      final finalTokenCount =
          TokenCounterService.estimateTokenCount(message.content);
      final updated = message.completeGeneration(finalTokenCount);
      await updateMessage(updated);
    }
  }

  /// 获取会话的总token数（所有消息）
  int getTotalTokens(String conversationId) {
    final messages = _messageCache[conversationId] ?? [];
    return messages.fold<int>(0, (sum, msg) => sum + msg.tokenCount);
  }

  /// 获取上下文的token数（最后N条消息）
  int getContextTokens(String conversationId, int messageCount) {
    final messages = getLastMessages(conversationId, messageCount);
    return messages.fold<int>(0, (sum, msg) => sum + msg.tokenCount);
  }

  /// 刷新当前会话的消息
  Future<void> refresh() async {
    if (_currentConversationId != null) {
      await _loadMessages(_currentConversationId!);
      notifyListeners();
    }
  }

  /// 清理缓存（保留当前会话）
  void clearCache({bool keepCurrent = true}) {
    if (keepCurrent && _currentConversationId != null) {
      final currentMessages = _messageCache[_currentConversationId];
      _messageCache.clear();
      if (currentMessages != null) {
        _messageCache[_currentConversationId!] = currentMessages;
      }
    } else {
      _messageCache.clear();
    }
  }
}
