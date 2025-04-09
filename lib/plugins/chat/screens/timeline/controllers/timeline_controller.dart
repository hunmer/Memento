import 'package:flutter/material.dart';
import '../../../models/message.dart';
import '../../../models/channel.dart';
import '../../../chat_plugin.dart';

/// Timeline 页面的控制器，负责管理消息流数据和搜索功能
class TimelineController extends ChangeNotifier {
  final ChatPlugin _chatPlugin;
  final TextEditingController searchController = TextEditingController();
  
  List<Message> _allMessages = [];
  List<Message> _filteredMessages = [];
  bool _isLoading = false;
  String _searchQuery = '';
  
  TimelineController(this._chatPlugin) {
    _loadAllMessages();
    // 监听搜索输入变化
    searchController.addListener(_onSearchChanged);
    // 添加聊天插件监听，当有新消息时刷新
    _chatPlugin.addListener(_onChatDataChanged);
  }
  
  bool get isLoading => _isLoading;
  List<Message> get messages => _filteredMessages;
  String get searchQuery => _searchQuery;
  
  void _onSearchChanged() {
    _searchQuery = searchController.text;
    _filterMessages();
    notifyListeners();
  }
  
  void _onChatDataChanged() {
    _loadAllMessages();
  }
  
  /// 从所有频道加载所有消息
  void _loadAllMessages() {
    _isLoading = true;
    notifyListeners();
    
    try {
      _allMessages = [];
      
      // 从所有频道收集消息
      for (final channel in _chatPlugin.channels) {
        // 为每条消息添加频道信息，以便在时间线中显示来源
        final messagesWithChannel = channel.messages.map((message) {
          // 创建一个带有频道信息的消息副本
          return message.copyWith(
            // 我们可以在元数据中存储频道信息
            metadata: {
              'channelId': channel.id,
              'channelName': channel.title,
              'channelColor': channel.backgroundColor.value.toRadixString(16),
            },
          );
        }).toList();
        
        _allMessages.addAll(messagesWithChannel);
      }
      
      // 按时间排序，最新的消息在前面
      _allMessages.sort((a, b) => b.date.compareTo(a.date));
      
      _filterMessages();
    } catch (e) {
      debugPrint('Error loading timeline messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 根据搜索查询过滤消息
  void _filterMessages() {
    if (_searchQuery.isEmpty) {
      _filteredMessages = List.from(_allMessages);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredMessages = _allMessages.where((message) {
        return message.content.toLowerCase().contains(query) ||
               message.user.username.toLowerCase().contains(query) ||
               (message.metadata?['channelName'] as String?)?.toLowerCase().contains(query) == true;
      }).toList();
    }
    notifyListeners();
  }
  
  /// 刷新时间线数据
  Future<void> refreshTimeline() async {
    _loadAllMessages();
    return Future.value();
  }
  
  /// 获取消息所属的频道
  Channel? getMessageChannel(Message message) {
    final channelId = message.metadata?['channelId'] as String?;
    if (channelId == null) return null;
    
    try {
      return _chatPlugin.channels.firstWhere((c) => c.id == channelId);
    } catch (e) {
      return null;
    }
  }
  
  @override
  void dispose() {
    searchController.dispose();
    _chatPlugin.removeListener(_onChatDataChanged);
    super.dispose();
  }
}