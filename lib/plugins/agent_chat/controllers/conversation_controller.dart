import 'package:flutter/foundation.dart';
import '../../../core/storage/storage_manager.dart';
import '../services/conversation_service.dart';
import '../services/message_service.dart';
import '../models/conversation.dart';
import '../models/conversation_group.dart';
import '../models/chat_message.dart';

/// 会话控制器
///
/// 统一管理会话和消息服务，提供状态管理
class ConversationController extends ChangeNotifier {
  final StorageManager storage;
  late final ConversationService conversationService;
  late final MessageService messageService;

  /// 是否已初始化
  bool _isInitialized = false;

  /// 当前选中的会话ID
  String? _currentConversationId;

  /// 搜索关键词
  String _searchQuery = '';

  /// 选中的分组过滤器（空列表表示显示所有）
  final List<String> _selectedGroupFilters = [];

  /// 选中的Agent过滤器（null表示显示所有）
  String? _selectedAgentFilter;

  /// 默认上下文消息数量（全局设置）
  int _defaultContextMessageCount = 10;

  ConversationController({required this.storage}) {
    conversationService = ConversationService(storage: storage);
    messageService = MessageService(storage: storage);

    // 监听服务变化
    conversationService.addListener(_onServiceChanged);
    messageService.addListener(_onServiceChanged);
  }

  // ========== Getters ==========

  bool get isInitialized => _isInitialized;
  bool get isLoading => conversationService.isLoading;

  List<Conversation> get conversations => _getFilteredConversations();
  List<ConversationGroup> get groups => conversationService.groups;

  String? get currentConversationId => _currentConversationId;
  Conversation? get currentConversation =>
      _currentConversationId != null
          ? conversationService.getConversation(_currentConversationId!)
          : null;

  List<ChatMessage> get currentMessages => messageService.currentMessages;

  String get searchQuery => _searchQuery;
  List<String> get selectedGroupFilters => _selectedGroupFilters;
  String? get selectedAgentFilter => _selectedAgentFilter;
  int get defaultContextMessageCount => _defaultContextMessageCount;

  // ========== 初始化 ==========

  /// 初始化控制器
  Future<void> initialize() async {
    if (_isInitialized) return;

    await conversationService.initialize();

    // 加载全局配置
    await _loadGlobalConfig();

    _isInitialized = true;
    notifyListeners();
  }

  /// 加载全局配置
  Future<void> _loadGlobalConfig() async {
    try {
      final config = await storage.read('agent_chat/config');
      if (config is Map<String, dynamic>) {
        _defaultContextMessageCount =
            config['defaultContextMessageCount'] as int? ?? 10;
      }
    } catch (e) {
      debugPrint('加载全局配置失败: $e');
      // 使用默认值
      _defaultContextMessageCount = 10;
    }
  }

  /// 保存全局配置
  Future<void> _saveGlobalConfig() async {
    try {
      await storage.write('agent_chat/config', {
        'defaultContextMessageCount': _defaultContextMessageCount,
      });
    } catch (e) {
      debugPrint('保存全局配置失败: $e');
    }
  }

  /// 服务变化回调
  void _onServiceChanged() {
    notifyListeners();
  }

  // ========== 会话操作 ==========

  /// 创建新会话
  Future<Conversation> createConversation({
    required String title,
    String? agentId,
    List<String>? groups,
    int? contextMessageCount,
  }) async {
    return await conversationService.createConversation(
      title: title,
      agentId: agentId,
      groups: groups,
      contextMessageCount: contextMessageCount,
    );
  }

  /// 选择会话
  Future<void> selectConversation(String conversationId) async {
    _currentConversationId = conversationId;
    await messageService.setCurrentConversation(conversationId);

    // 清除未读计数
    await conversationService.clearUnreadCount(conversationId);

    notifyListeners();
  }

  /// 更新会话
  Future<void> updateConversation(Conversation conversation) async {
    await conversationService.updateConversation(conversation);
  }

  /// 删除会话
  Future<void> deleteConversation(String conversationId) async {
    if (_currentConversationId == conversationId) {
      _currentConversationId = null;
    }
    await conversationService.deleteConversation(conversationId);
  }

  /// 切换置顶状态
  Future<void> togglePin(String conversationId) async {
    await conversationService.togglePin(conversationId);
  }

  // ========== 分组操作 ==========

  /// 创建分组
  Future<ConversationGroup> createGroup({
    required String name,
    String? icon,
    String? color,
  }) async {
    return await conversationService.createGroup(
      name: name,
      icon: icon,
      color: color,
    );
  }

  /// 更新分组
  Future<void> updateGroup(ConversationGroup group) async {
    await conversationService.updateGroup(group);
  }

  /// 删除分组
  Future<void> deleteGroup(String groupId) async {
    // 从筛选器中移除
    _selectedGroupFilters.remove(groupId);
    await conversationService.deleteGroup(groupId);
    notifyListeners();
  }

  // ========== 筛选和搜索 ==========

  /// 设置搜索关键词
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// 切换分组过滤器
  void toggleGroupFilter(String groupId) {
    if (_selectedGroupFilters.contains(groupId)) {
      _selectedGroupFilters.remove(groupId);
    } else {
      _selectedGroupFilters.add(groupId);
    }
    notifyListeners();
  }

  /// 清除分组过滤器
  void clearGroupFilters() {
    _selectedGroupFilters.clear();
    notifyListeners();
  }

  /// 设置Agent过滤器
  void setAgentFilter(String? agentId) {
    _selectedAgentFilter = agentId;
    notifyListeners();
  }

  /// 获取过滤后的会话列表
  List<Conversation> _getFilteredConversations() {
    var filtered = conversationService.conversations;

    // 应用搜索
    if (_searchQuery.isNotEmpty) {
      filtered = conversationService.searchConversations(_searchQuery);
    }

    // 应用分组过滤
    if (_selectedGroupFilters.isNotEmpty) {
      filtered = filtered.where((conv) {
        return conv.groups
            .any((group) => _selectedGroupFilters.contains(group));
      }).toList();
    }

    // 应用Agent过滤
    if (_selectedAgentFilter != null) {
      filtered =
          filtered.where((conv) => conv.agentId == _selectedAgentFilter).toList();
    }

    return filtered;
  }

  // ========== 全局设置 ==========

  /// 设置默认上下文消息数量
  Future<void> setDefaultContextMessageCount(int count) async {
    _defaultContextMessageCount = count;
    await _saveGlobalConfig();
    notifyListeners();
  }

  /// 获取会话的上下文消息数量
  int getContextMessageCount(String conversationId) {
    final conversation = conversationService.getConversation(conversationId);
    return conversation?.contextMessageCount ?? _defaultContextMessageCount;
  }

  // ========== 刷新 ==========

  /// 刷新数据
  Future<void> refresh() async {
    await Future.wait([
      conversationService.refresh(),
      if (_currentConversationId != null) messageService.refresh(),
    ]);
  }

  @override
  void dispose() {
    conversationService.removeListener(_onServiceChanged);
    messageService.removeListener(_onServiceChanged);
    conversationService.dispose();
    messageService.dispose();
    super.dispose();
  }
}
