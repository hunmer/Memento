import 'package:flutter/material.dart';
import '../../../models/message.dart';
import '../../../models/channel.dart';
import '../../../chat_plugin.dart';
import '../models/timeline_filter.dart';

/// Timeline 页面的控制器，负责管理消息流数据和搜索功能
class TimelineController extends ChangeNotifier {
  final ChatPlugin _chatPlugin;
  final TextEditingController searchController = TextEditingController();
  
  List<Message> _allMessages = [];
  List<Message> _filteredMessages = [];
  bool _isLoading = false;
  String _searchQuery = '';
  
  // 高级过滤器
  final TimelineFilter filter = TimelineFilter();
  bool _isFilterActive = false;
  
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
  bool get isFilterActive => _isFilterActive;
  
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
  
  /// 根据搜索查询和高级过滤器过滤消息
  void _filterMessages() {
    // 先应用基本的搜索过滤
    List<Message> result = _allMessages;
    
    // 应用文本搜索
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((message) {
        bool matches = false;
        
        // 根据过滤器设置决定搜索范围
        if (filter.includeContent) {
          matches = matches || message.content.toLowerCase().contains(query);
        }
        
        if (filter.includeUsernames) {
          matches = matches || message.user.username.toLowerCase().contains(query);
        }
        
        if (filter.includeChannels) {
          matches = matches || (message.metadata?['channelName'] as String?)?.toLowerCase().contains(query) == true;
        }
        
        return matches;
      }).toList();
    }
    
    // 应用高级过滤器
    if (_isFilterActive) {
      // 过滤频道
      if (filter.selectedChannelIds.isNotEmpty) {
        result = result.where((message) {
          final channelId = message.metadata?['channelId'] as String?;
          return channelId != null && filter.selectedChannelIds.contains(channelId);
        }).toList();
      }
      
      // 过滤用户
      if (filter.selectedUserIds.isNotEmpty) {
        result = result.where((message) {
          return filter.selectedUserIds.contains(message.user.id);
        }).toList();
      }
      
      // 过滤日期范围
      if (filter.startDate != null || filter.endDate != null) {
        result = result.where((message) {
          final messageDate = message.date;
          
          bool matchesStartDate = true;
          if (filter.startDate != null) {
            final startDate = DateTime(
              filter.startDate!.year,
              filter.startDate!.month,
              filter.startDate!.day,
            );
            matchesStartDate = messageDate.isAfter(startDate) || 
                              messageDate.isAtSameMomentAs(startDate);
          }
          
          bool matchesEndDate = true;
          if (filter.endDate != null) {
            final endDate = DateTime(
              filter.endDate!.year,
              filter.endDate!.month,
              filter.endDate!.day,
              23, 59, 59, 999,
            );
            matchesEndDate = messageDate.isBefore(endDate) || 
                            messageDate.isAtSameMomentAs(endDate);
          }
          
          return matchesStartDate && matchesEndDate;
        }).toList();
      }
    }
    
    _filteredMessages = result;
    notifyListeners();
  }
  
  /// 刷新时间线数据
  Future<void> refreshTimeline() async {
    _loadAllMessages();
    return Future.value();
  }
  
  /// 应用高级过滤器
  void applyFilter(TimelineFilter newFilter) {
    filter.includeChannels = newFilter.includeChannels;
    filter.includeUsernames = newFilter.includeUsernames;
    filter.includeContent = newFilter.includeContent;
    filter.startDate = newFilter.startDate;
    filter.endDate = newFilter.endDate;
    filter.selectedChannelIds = newFilter.selectedChannelIds;
    filter.selectedUserIds = newFilter.selectedUserIds;
    
    // 检查过滤器是否有效
    _isFilterActive = filter.selectedChannelIds.isNotEmpty || 
                      filter.selectedUserIds.isNotEmpty || 
                      filter.startDate != null || 
                      filter.endDate != null ||
                      !filter.includeChannels ||
                      !filter.includeUsernames ||
                      !filter.includeContent;
    
    _filterMessages();
  }
  
  /// 重置过滤器
  void resetFilter() {
    filter.reset();
    _isFilterActive = false;
    _filterMessages();
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