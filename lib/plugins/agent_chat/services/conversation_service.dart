import 'package:Memento/plugins/agent_chat/data/sample_data.dart';
import 'package:flutter/foundation.dart';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/core/services/plugin_widget_sync_helper.dart';
import 'package:Memento/plugins/agent_chat/models/conversation.dart';

/// 会话服务
///
/// 管理会话的CRUD操作
class ConversationService extends ChangeNotifier {
  final StorageManager storage;

  /// 所有会话列表
  List<Conversation> _conversations = [];

  /// 是否正在加载
  bool _isLoading = false;

  /// 持久化会话列表时的串行任务链，避免并发写导致文件损坏
  Future<void> _conversationsSaveChain = Future.value();

  ConversationService({required this.storage});

  // Getters
  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;

  /// 初始化服务
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await _loadConversations();

    _isLoading = false;
    notifyListeners();
  }

  /// 加载所有会话
  Future<void> _loadConversations() async {
    try {
      final data = await storage.read('agent_chat/conversations');
      if (data is List && data.isNotEmpty) {
        // 有数据，正常加载
        _conversations =
            data
                .map(
                  (json) => Conversation.fromJson(json as Map<String, dynamic>),
                )
                .toList();
        _conversations.sort(Conversation.compare);
      } else {
        // 没有数据，首次使用，加载示例数据
        debugPrint('AgentChat插件: 首次初始化，正在加载示例数据...');
        await _loadSampleData();
      }
    } catch (e) {
      debugPrint('加载会话失败: $e');
      // 加载失败时，加载示例数据
      await _loadSampleData();
    }
  }

  /// 加载示例数据
  Future<void> _loadSampleData() async {
    try {
      // 获取示例数据
      final sampleData = AgentChatSampleData.getFullSampleData();

      // 保存会话数据
      final conversationsJson = sampleData['conversations'] as List;
      await storage.write('agent_chat/conversations', conversationsJson);

      // 保存消息数据
      final messagesJson = sampleData['messages'] as Map<String, dynamic>;
      for (var entry in messagesJson.entries) {
        final conversationId = entry.key;
        final messages = entry.value as List;
        await storage.write('agent_chat/messages/$conversationId', messages);
      }

      // 提取唯一分组数量
      final uniqueGroups = <String>{};
      for (final convJson in conversationsJson) {
        final conv = Conversation.fromJson(convJson as Map<String, dynamic>);
        uniqueGroups.addAll(conv.groups);
      }

      debugPrint(
        'AgentChat插件: 示例数据加载完成！共加载 ${uniqueGroups.length} 个分组，${conversationsJson.length} 个会话',
      );

      // 直接加载数据到内存，避免递归调用
      _conversations =
          conversationsJson
              .map(
                (json) => Conversation.fromJson(json as Map<String, dynamic>),
              )
              .toList();
      _conversations.sort(Conversation.compare);

      notifyListeners();
    } catch (e) {
      debugPrint('AgentChat插件: 加载示例数据失败: $e');
      // 如果加载示例数据失败，创建空数据
      _conversations = [];
      await storage.write('agent_chat/conversations', []);
      notifyListeners();
    }
  }

  /// 保存所有会话
  Future<void> _saveConversations() {
    // 通过串行化写入，防止多个写操作并发执行造成JSON尾部出现多余字符
    final saveTask = _conversationsSaveChain
        .catchError((_, __) {})
        .then((_) async {
          try {
            final data = _conversations.map((c) => c.toJson()).toList();
            await storage.write('agent_chat/conversations', data);
          } catch (e) {
            debugPrint('保存会话失败: $e');
            rethrow; // 重新抛出异常，让调用者知道保存失败
          }
        });

    _conversationsSaveChain = saveTask;
    return saveTask;
  }

  // ========== 会话操作 ==========

  /// 创建新会话
  Future<Conversation> createConversation({
    required String title,
    String? agentId,
    List<String>? groups,
    int? contextMessageCount,
  }) async {
    final conversation = Conversation.create(
      title: title,
      agentId: agentId,
      groups: groups,
      contextMessageCount: contextMessageCount,
    );

    _conversations.add(conversation);
    _conversations.sort(Conversation.compare);
    await _saveConversations();
    notifyListeners();

    // 同步小组件数据
    await PluginWidgetSyncHelper.instance.syncAgentChat();

    return conversation;
  }

  /// 获取会话
  Conversation? getConversation(String id) {
    try {
      return _conversations.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 更新会话
  Future<void> updateConversation(Conversation conversation) async {
    final index = _conversations.indexWhere((c) => c.id == conversation.id);
    if (index != -1) {
      _conversations[index] = conversation;
      _conversations.sort(Conversation.compare);
      await _saveConversations();
      notifyListeners();
    }
  }

  /// 删除会话
  Future<void> deleteConversation(String id) async {
    _conversations.removeWhere((c) => c.id == id);
    await _saveConversations();
    notifyListeners();

    // 同时删除会话的所有消息
    try {
      await storage.delete('agent_chat/messages/$id');
    } catch (e) {
      debugPrint('删除会话失败: $e');
    }

    // 同步小组件数据
    await PluginWidgetSyncHelper.instance.syncAgentChat();
  }

  /// 更新会话的最后消息信息
  Future<void> updateLastMessage(
    String conversationId,
    String messagePreview,
  ) async {
    final conversation = getConversation(conversationId);
    if (conversation != null) {
      final updated = conversation.copyWith(
        lastMessageAt: DateTime.now(),
        lastMessagePreview: messagePreview,
      );
      await updateConversation(updated);
    }
  }

  /// 切换会话置顶状态
  Future<void> togglePin(String conversationId) async {
    final conversation = getConversation(conversationId);
    if (conversation != null) {
      final updated = conversation.copyWith(isPinned: !conversation.isPinned);
      await updateConversation(updated);
    }
  }

  /// 更新未读计数
  Future<void> updateUnreadCount(String conversationId, int count) async {
    final conversation = getConversation(conversationId);
    if (conversation != null) {
      final updated = conversation.copyWith(unreadCount: count);
      await updateConversation(updated);
    }
  }

  /// 清除未读计数
  Future<void> clearUnreadCount(String conversationId) async {
    await updateUnreadCount(conversationId, 0);
  }

  // ========== 查询操作 ==========

  /// 按分组筛选会话
  List<Conversation> getConversationsByGroup(String groupName) {
    return _conversations.where((c) => c.groups.contains(groupName)).toList();
  }

  /// 按Agent筛选会话
  List<Conversation> getConversationsByAgent(String agentId) {
    return _conversations.where((c) => c.agentId == agentId).toList();
  }

  /// 搜索会话
  List<Conversation> searchConversations(String query) {
    if (query.isEmpty) return _conversations;

    final lowerQuery = query.toLowerCase();
    return _conversations.where((c) {
      // 搜索会话标题
      final titleMatch = c.title.toLowerCase().contains(lowerQuery);

      // 搜索最后消息预览
      final messagePreviewMatch =
          c.lastMessagePreview?.toLowerCase().contains(lowerQuery) ?? false;

      // 搜索所属分组的名称
      final groupMatch = c.groups.any((groupName) {
        return groupName.toLowerCase().contains(lowerQuery);
      });

      return titleMatch || messagePreviewMatch || groupMatch;
    }).toList();
  }

  /// 获取置顶的会话
  List<Conversation> getPinnedConversations() {
    return _conversations.where((c) => c.isPinned).toList();
  }

  /// 刷新会话列表
  Future<void> refresh() async {
    // 插件已在 initialize() 中完成初始化
    // 这里可以添加额外的应用级注册逻辑
  }
}
