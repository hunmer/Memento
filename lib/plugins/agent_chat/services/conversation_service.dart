import 'package:flutter/foundation.dart';
import '../../../core/storage/storage_manager.dart';
import '../../../core/services/plugin_widget_sync_helper.dart';
import '../models/conversation.dart';
import '../models/conversation_group.dart';

/// 会话服务
///
/// 管理会话的CRUD操作
class ConversationService extends ChangeNotifier {
  final StorageManager storage;

  /// 所有会话列表
  List<Conversation> _conversations = [];

  /// 所有分组列表
  List<ConversationGroup> _groups = [];

  /// 是否正在加载
  bool _isLoading = false;

  ConversationService({required this.storage});

  // Getters
  List<Conversation> get conversations => _conversations;
  List<ConversationGroup> get groups => _groups;
  bool get isLoading => _isLoading;

  /// 初始化服务
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      _loadConversations(),
      _loadGroups(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  /// 加载所有会话
  Future<void> _loadConversations() async {
    try {
      final data = await storage.read('agent_chat/conversations');
      if (data is List) {
        _conversations = data
            .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
            .toList();
        _conversations.sort(Conversation.compare);
      }
    } catch (e) {
      debugPrint('加载会话失败: $e');
      _conversations = [];
    }
  }

  /// 加载所有分组
  Future<void> _loadGroups() async {
    try {
      final data = await storage.read('agent_chat/groups');
      if (data is List) {
        _groups = data
            .map((json) =>
                ConversationGroup.fromJson(json as Map<String, dynamic>))
            .toList();
        _groups.sort(ConversationGroup.compare);
      } else {
        _groups = [];
      }
    } catch (e) {
      debugPrint('加载分组失败: $e');
      _groups = [];
    }
  }

  /// 保存所有会话
  Future<void> _saveConversations() async {
    try {
      final data = _conversations.map((c) => c.toJson()).toList();
      await storage.write('agent_chat/conversations', data);
    } catch (e) {
      debugPrint('保存会话失败: $e');
      rethrow; // 重新抛出异常，让调用者知道保存失败
    }
  }

  /// 保存所有分组
  Future<void> _saveGroups() async {
    try {
      final data = _groups.map((g) => g.toJson()).toList();
      await storage.write('agent_chat/groups', data);
    } catch (e) {
      debugPrint('保存分组失败: $e');
      rethrow; // 重新抛出异常，让调用者知道保存失败
    }
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

  // ========== 分组操作 ==========

  /// 创建新分组
  Future<ConversationGroup> createGroup({
    required String name,
    String? icon,
    String? color,
  }) async {
    final group = ConversationGroup.create(
      name: name,
      icon: icon,
      color: color,
      order: _groups.length,
    );

    _groups.add(group);
    _groups.sort(ConversationGroup.compare);

    await _saveGroups();
    notifyListeners();

    return group;
  }

  /// 获取分组
  ConversationGroup? getGroup(String id) {
    try {
      return _groups.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 更新分组
  Future<void> updateGroup(ConversationGroup group) async {
    final index = _groups.indexWhere((g) => g.id == group.id);
    if (index != -1) {
      _groups[index] = group;
      await _saveGroups();
      notifyListeners();
    }
  }

  /// 删除分组
  Future<void> deleteGroup(String id) async {
    _groups.removeWhere((g) => g.id == id);
    await _saveGroups();

    // 从所有会话中移除该分组
    for (var conversation in _conversations) {
      if (conversation.groups.contains(id)) {
        final updated = conversation.copyWith(
          groups: conversation.groups.where((g) => g != id).toList(),
        );
        await updateConversation(updated);
      }
    }

    notifyListeners();
  }

  // ========== 查询操作 ==========

  /// 按分组筛选会话
  List<Conversation> getConversationsByGroup(String groupId) {
    return _conversations.where((c) => c.groups.contains(groupId)).toList();
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
      final groupMatch = c.groups.any((groupId) {
        try {
          final group = _groups.firstWhere((g) => g.id == groupId);
          return group.name.toLowerCase().contains(lowerQuery);
        } catch (e) {
          // 如果分组不存在，跳过
          return false;
        }
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
    await initialize();
  }
}
