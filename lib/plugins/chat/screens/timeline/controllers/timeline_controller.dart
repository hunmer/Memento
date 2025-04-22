import 'package:flutter/material.dart';
import '../../../models/message.dart';
import '../../../models/channel.dart';
import '../../../chat_plugin.dart';
import '../models/timeline_filter.dart';

/// Timeline 页面的控制器，负责管理消息流数据和搜索功能
class TimelineController extends ChangeNotifier {
  final ChatPlugin _chatPlugin;
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // 消息操作回调
  void Function(Message)? onMessageEdit;
  Future<void> Function(Message)? onMessageDelete;
  void Function(Message)? onMessageCopy;
  void Function(Message, String?)? onSetFixedSymbol;
  void Function(Message, Color?)? onSetBubbleColor;

  // 分页相关 - 增加每页加载的消息数量
  static const int pageSize = 100; // 增加每页显示的消息数量
  int _currentPage = 1;
  bool _hasMoreMessages = true;

  List<Message> _allMessages = [];
  List<Message> _filteredMessages = [];
  List<Message> _displayMessages = []; // 当前显示的消息
  bool _isLoading = false;
  String _searchQuery = '';

  // 高级过滤器
  final TimelineFilter filter = TimelineFilter();
  bool _isFilterActive = false;

  TimelineController(
    this._chatPlugin, {
    this.onMessageEdit,
    this.onMessageDelete,
    this.onMessageCopy,
    this.onSetFixedSymbol,
    this.onSetBubbleColor,
  }) {
    // 监听搜索输入变化
    searchController.addListener(_onSearchChanged);

    // 添加聊天插件监听，当有新消息时刷新
    _chatPlugin.addListener(_onChatDataChanged);

    // 设置滚动监听（延迟添加以确保 ScrollController 已准备就绪）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasListeners) {
        scrollController.addListener(_onScroll);
      }
    });

    // 确保初始化时加载最新消息
    _initializeTimeline();
  }

  bool get isLoading => _isLoading;
  List<Message> get messages => _displayMessages;
  String get searchQuery => _searchQuery;
  bool get isFilterActive => _isFilterActive;
  bool get hasMoreMessages => _hasMoreMessages;

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
        final messagesWithChannel =
            channel.messages.map((message) {
              // 创建一个带有频道信息的消息副本
              return message.copyWith(
                // 我们可以在元数据中存储频道信息
                metadata: {
                  'channelId': channel.id,
                  'channelName': channel.title,
                  'channelColor': channel.backgroundColor.value.toRadixString(
                    16,
                  ),
                },
              );
            }).toList();

        _allMessages.addAll(messagesWithChannel);
      }

      // 按时间排序，最新的消息在前面
      _allMessages.sort((a, b) => b.date.compareTo(a.date));

      // 重置分页状态并过滤消息
      _resetPagination();
      _filterMessages();

      debugPrint('Timeline: 加载了 ${_allMessages.length} 条消息');
    } catch (e) {
      debugPrint('Error loading timeline messages: $e');
    } finally {
      _isLoading = false;

      // 确保在 _isLoading = false 之后加载第一页
      if (_filteredMessages.isNotEmpty) {
        _loadCurrentPage();
      }

      notifyListeners();
      debugPrint('Timeline: 加载完成，显示 ${_displayMessages.length} 条消息');
    }
  }

  /// 根据搜索查询和高级过滤器过滤消息
  void _filterMessages() {

    // 先应用基本的搜索过滤
    List<Message> result = List<Message>.from(_allMessages);

    // 应用文本搜索
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result =
          result.where((message) {
            bool matches = false;

            // 根据过滤器设置决定搜索范围
            if (filter.includeContent) {
              matches =
                  matches || message.content.toLowerCase().contains(query);
            }

            if (filter.includeUsernames) {
              matches =
                  matches ||
                  message.user.username.toLowerCase().contains(query);
            }

            if (filter.includeChannels) {
              matches =
                  matches ||
                  (message.metadata?['channelName'] as String?)
                          ?.toLowerCase()
                          .contains(query) ==
                      true;
            }

            return matches;
          }).toList();
    }

    // 应用高级过滤器
    if (_isFilterActive) {
      // 过滤频道
      if (filter.selectedChannelIds.isNotEmpty) {
        result =
            result.where((message) {
              final channelId = message.metadata?['channelId'] as String?;
              return channelId != null &&
                  filter.selectedChannelIds.contains(channelId);
            }).toList();
      }

      // 过滤用户
      if (filter.selectedUserIds.isNotEmpty) {
        result =
            result.where((message) {
              return filter.selectedUserIds.contains(message.user.id);
            }).toList();
      }

      // 过滤日期范围
      if (filter.startDate != null || filter.endDate != null) {
        result =
            result.where((message) {
              final messageDate = message.date;

              bool matchesStartDate = true;
              if (filter.startDate != null) {
                final startDate = DateTime(
                  filter.startDate!.year,
                  filter.startDate!.month,
                  filter.startDate!.day,
                );
                matchesStartDate =
                    messageDate.isAfter(startDate) ||
                    messageDate.isAtSameMomentAs(startDate);
              }

              bool matchesEndDate = true;
              if (filter.endDate != null) {
                final endDate = DateTime(
                  filter.endDate!.year,
                  filter.endDate!.month,
                  filter.endDate!.day,
                  23,
                  59,
                  59,
                  999,
                );
                matchesEndDate =
                    messageDate.isBefore(endDate) ||
                    messageDate.isAtSameMomentAs(endDate);
              }

              return matchesStartDate && matchesEndDate;
            }).toList();
      }
    }

    _filteredMessages = result;

    // 确保加载第一页数据
    _currentPage = 1;
    _hasMoreMessages = true;

    // 不要在这里调用 _loadCurrentPage()，因为此时可能仍处于 _isLoading 状态
    // 改为在 _loadAllMessages 的 finally 块中调用

    debugPrint('Timeline: 过滤后共有 ${_filteredMessages.length} 条消息');
  }

  /// 刷新时间线数据
  Future<void> refreshTimeline() async {
    _resetPagination();
    _loadAllMessages();
    _ensureScrollListener(); // 确保滚动监听器已添加
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
    _isFilterActive =
        filter.selectedChannelIds.isNotEmpty ||
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
    _ensureScrollListener(); // 确保滚动监听器已添加
  }

  /// 手动检查并重新添加滚动监听器（可从UI层调用）
  void ensureScrollListenerActive() {
    _ensureScrollListener();

    // 立即检查是否需要加载更多
    if (scrollController.hasClients && _hasMoreMessages && !_isLoadingMore) {
      try {
        final maxScroll = scrollController.position.maxScrollExtent;
        final currentScroll = scrollController.position.pixels;
        final distanceToBottom = maxScroll - currentScroll;
        final viewportHeight = scrollController.position.viewportDimension;

        debugPrint(
          'Timeline: 主动检查滚动位置 - 距底部: $distanceToBottom, 视口高度: $viewportHeight',
        );

        // 减小触发阈值，使加载更多更容易触发
        if (distanceToBottom < viewportHeight * 1.0) {
          debugPrint('Timeline: 主动触发加载更多');
          _loadMoreMessages();
        }
      } catch (e) {
        debugPrint('Timeline: 主动检查滚动位置错误: $e');
      }
    }
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

  /// 处理消息编辑
  void handleMessageEdit(Message message) {
    if (onMessageEdit != null) {
      onMessageEdit!(message);
    }
  }

  /// 处理消息删除
  Future<void> handleMessageDelete(Message message) async {
    if (onMessageDelete != null) {
      await onMessageDelete!(message);
    }
  }

  /// 处理消息复制
  void handleMessageCopy(Message message) {
    if (onMessageCopy != null) {
      onMessageCopy!(message);
    }
  }

  /// 处理设置固定标记
  void handleSetFixedSymbol(Message message, String? symbol) {
    if (onSetFixedSymbol != null) {
      onSetFixedSymbol!(message, symbol);
    }
  }

  /// 处理设置气泡颜色
  void handleSetBubbleColor(Message message, Color? color) {
    if (onSetBubbleColor != null) {
      onSetBubbleColor!(message, color);
    }
  }

  /// 加载当前页的消息
  void _loadCurrentPage() {
    debugPrint('Timeline: 开始加载第 $_currentPage 页...');

    // 移除对 _isLoading 的检查，因为我们需要在 _loadAllMessages 完成后加载页面
    // 如果需要防止重复加载，可以添加其他标志

    if (_filteredMessages.isEmpty) {
      debugPrint('Timeline: 没有可显示的消息');
      _displayMessages = [];
      _hasMoreMessages = false;
      notifyListeners();
      return;
    }

    final startIndex = (_currentPage - 1) * pageSize;
    final endIndex = startIndex + pageSize;

    // 检查是否还有更多消息
    if (startIndex >= _filteredMessages.length) {
      debugPrint('Timeline: 起始索引 $startIndex 超出范围 ${_filteredMessages.length}');
      _hasMoreMessages = false;
      notifyListeners();
      return;
    }

    // 获取当前页的消息
    final actualEndIndex =
        endIndex < _filteredMessages.length
            ? endIndex
            : _filteredMessages.length;
    final pageMessages = _filteredMessages.sublist(startIndex, actualEndIndex);

    if (_currentPage == 1) {
      _displayMessages = List<Message>.from(pageMessages);
      debugPrint('Timeline: 重置显示消息列表，加载第一页 ${pageMessages.length} 条消息');
    } else {
      _displayMessages.addAll(pageMessages);
      debugPrint('Timeline: 添加第 $_currentPage 页，新增 ${pageMessages.length} 条消息');
    }

    // 更新是否还有更多消息
    _hasMoreMessages = actualEndIndex < _filteredMessages.length;

    debugPrint(
      'Timeline: 当前页 $_currentPage，本页加载 ${pageMessages.length} 条消息，'
      '已显示 ${_displayMessages.length} 条，总共 ${_filteredMessages.length} 条，'
      '是否还有更多: $_hasMoreMessages',
    );

    notifyListeners();
  }

  // 用于防止重复加载的标志
  bool _isLoadingMore = false;
  DateTime? _lastLoadTime;

  /// 加载更多消息
  void _loadMoreMessages() {
    // 检查是否正在加载或没有更多消息
    if (_isLoadingMore || !_hasMoreMessages) {
      debugPrint(
        'Timeline: 跳过加载更多 - 正在加载: $_isLoadingMore, 是否有更多: $_hasMoreMessages',
      );
      return;
    }

    // 检查距离上次加载的时间间隔（防抖）
    final now = DateTime.now();
    if (_lastLoadTime != null &&
        now.difference(_lastLoadTime!) < const Duration(seconds: 1)) {
      debugPrint('Timeline: 跳过加载更多 - 加载过于频繁');
      return;
    }

    debugPrint('Timeline: 开始加载更多消息...');
    _isLoadingMore = true;
    _lastLoadTime = now;

    try {
      _currentPage++;
      _loadCurrentPage();
    } finally {
      _isLoadingMore = false;
    }
  }

  /// 滚动监听
  void _onScroll() {
    // 检查是否接近底部
    if (!scrollController.hasClients) {
      return;
    }

    try {
      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.position.pixels;

      // 计算距离底部的距离
      final distanceToBottom = maxScroll - currentScroll;
      final viewportHeight = scrollController.position.viewportDimension;

      // 当滚动到距离底部不足一个屏幕高度时触发加载（增大阈值）
      final threshold = viewportHeight * 1.0;

      if (distanceToBottom < threshold) {
        _loadMoreMessages();
      }
    } catch (e) {
      debugPrint('Timeline: 滚动监听器错误: $e');
    }
  }

  /// 确保滚动监听器已添加
  void _ensureScrollListener() {
    if (!scrollController.hasListeners) {
      scrollController.addListener(_onScroll);
    }
  }

  /// 初始化时间线
  void _initializeTimeline() {
    debugPrint('Timeline: 初始化时间线...');
    _resetPagination();
    _loadAllMessages();
    
    // 确保初始加载足够的消息以填满瀑布流视图
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_displayMessages.length < pageSize && _hasMoreMessages) {
        _loadMoreMessages();
      }
      _ensureScrollListener();
    });
  }

  /// 重置分页状态
  void _resetPagination() {
    _currentPage = 1;
    _hasMoreMessages = true;
    _displayMessages = [];
    debugPrint('Timeline: 重置分页状态');
  }

  @override
  void dispose() {
    searchController.dispose();
    scrollController.removeListener(_onScroll); // 先移除监听器
    scrollController.dispose();
    _chatPlugin.removeListener(_onChatDataChanged);
    _isLoadingMore = false; // 重置加载状态
    super.dispose();
  }
}
