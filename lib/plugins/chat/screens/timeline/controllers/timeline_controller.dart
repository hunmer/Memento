import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:Memento/plugins/chat/screens/timeline/models/timeline_filter.dart';
import 'timeline_controller/base_controller.dart';
import 'timeline_controller/message_handler.dart';
import 'timeline_controller/pagination_controller.dart';
import 'timeline_controller/search_controller.dart';
import 'timeline_controller/scroll_controller.dart';
import 'timeline_controller/channel_controller.dart';

/// 时间线显示模式
enum TimelineDisplayMode {
  /// 标准显示模式
  standard,

  /// 紧凑显示模式
  compact,

  /// 详细显示模式
  detailed,
}

/// 时间线排序方式
enum TimelineSortOrder {
  /// 最新消息在前
  newestFirst,

  /// 最旧消息在前
  oldestFirst,
}

/// Timeline 页面的控制器，负责管理消息流数据和搜索功能
class TimelineController extends BaseTimelineController
    with
        MessageHandlerMixin,
        PaginationControllerMixin,
        SearchControllerMixin,
        ScrollControllerMixin,
        ChannelControllerMixin {
  // 存储路径
  static const String _storagePath = 'chat/timeline';

  /// 时间线显示模式
  TimelineDisplayMode? _displayMode;
  TimelineDisplayMode get displayMode =>
      _displayMode ?? TimelineDisplayMode.standard;
  set displayMode(TimelineDisplayMode value) {
    _displayMode = value;
    saveTimelineState();
  }

  // 排序方式
  TimelineSortOrder? _currentSortOrder;
  TimelineSortOrder get currentSortOrder =>
      _currentSortOrder ?? TimelineSortOrder.newestFirst;
  set currentSortOrder(TimelineSortOrder value) {
    _currentSortOrder = value;
    saveTimelineState();
  }

  TimelineController(
    ChatPlugin chatPlugin, {
    super.onMessageEdit,
    super.onMessageDelete,
    super.onMessageCopy,
    super.onSetFixedSymbol,
    super.onSetBubbleColor,
    super.onToggleFavorite,
  }) : super(
         chatPlugin: chatPlugin,
         searchController: TextEditingController(),
         scrollController: ScrollController(),
         filter: TimelineFilter(
           type: TimelineFilterType.all,
           title: 'All Messages',
           icon: Icons.all_inbox,
         ),
       ) {
    // 初始化默认值会通过getter处理
    _currentSortOrder = null;
    _displayMode = null;

    // 监听搜索输入变化
    searchController.addListener(onSearchChanged);

    // 添加聊天插件监听，当有新消息时刷新
    chatPlugin.addListener(_onChatDataChanged);

    // 先恢复状态，再初始化时间线
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ensureScrollListener();
      // 先恢复上次的时间线状态
      await _restoreTimelineState();
      // 然后再初始化时间线
      _initializeTimeline();
    });
  }

  /// 初始化时间线数据
  void _initializeTimeline() {
    debugPrint('Timeline: 开始初始化时间线...');
    _loadAllMessages();
  }

  /// 从所有频道加载所有消息
  Future<void> _loadAllMessages() async {
    if (!isLoading) {
      isLoading = true;
      notifyListeners();

      try {
        debugPrint('Timeline: 开始加载所有消息...');

        // 从聊天插件获取所有消息
        final messages = await chatPlugin.messageService.getAllMessages();
        debugPrint('Timeline: 获取到 ${messages.length} 条消息');

        // 按日期降序排序消息
        messages.sort((a, b) => b.date.compareTo(a.date));

        // 更新消息列表
        allMessages = messages;

        // 应用当前的搜索和过滤器，但不保存状态
        // 首次加载时不应该保存过滤器状态
        filterMessages(saveState: false);
      } catch (e) {
        debugPrint('Timeline: 加载消息时出错: $e');
        allMessages = [];
        filteredMessages = [];
        displayMessages = [];
      } finally {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  /// 聊天数据变化时的回调
  void _onChatDataChanged() {
    _loadAllMessages();
    // 不在这里保存状态，因为 _loadAllMessages 会调用 filterMessages
    // 并且 filterMessages 会在需要时保存状态
  }

  /// 刷新时间线数据
  @override
  Future<void> refreshTimeline() async {
    debugPrint('Timeline: 开始刷新时间线...');

    // 重置分页状态
    resetPagination();

    // 重新加载所有消息
    await _loadAllMessages();

    debugPrint('Timeline: 时间线刷新完成');
  }

  /// 保存时间线视图和筛选状态
  @override
  Future<void> saveTimelineState() async {
    try {
      // 准备要保存的数据，只保存必要的过滤器数据
      final timelineState = {
        'filterData': {
          'type': filter.type.index,
          'selectedChannelIds': filter.selectedChannelIds.toList(),
          'selectedUserIds': filter.selectedUserIds.toList(),
          'isAI': filter.isAI,
          'isFavorite': filter.isFavorite,
        },
        'viewState': {
          'isFilterActive': isFilterActive,
          'searchQuery': searchQuery,
        },
        'lastUpdate': DateTime.now().toIso8601String(),
      };

      // 保存到存储
      await chatPlugin.storage.write(_storagePath, timelineState);
      debugPrint('Timeline: 已保存时间线状态');
    } catch (e) {
      debugPrint('Timeline: 保存时间线状态时出错: $e');
    }
  }

  /// 更新过滤器并触发相关更新
  void updateFilter(TimelineFilter newFilter) {
    filter.updateFrom(newFilter);
    filterMessages();
    notifyListeners();
  }

  /// 恢复上次保存的时间线状态
  Future<void> _restoreTimelineState() async {
    try {
      // 从存储中读取状态
      final timelineState = await chatPlugin.storage.read(_storagePath);
      if (timelineState == null) return;

      // 恢复过滤器设置
      final filterData = timelineState['filterData'] as Map<String, dynamic>?;
      if (filterData != null) {
        // 只恢复必要的过滤器属性
        filter.selectedChannelIds = Set<String>.from(
          filterData['selectedChannelIds'] as List? ?? [],
        );
        filter.selectedUserIds = Set<String>.from(
          filterData['selectedUserIds'] as List? ?? [],
        );
        filter.isAI = filterData['isAI'] as bool?;
        filter.isFavorite = filterData['isFavorite'] as bool?;
      }

      // 恢复视图状态
      final viewState = timelineState['viewState'] as Map<String, dynamic>?;
      if (viewState != null) {
        isFilterActive = viewState['isFilterActive'] as bool? ?? false;

        final lastSearchQuery = viewState['searchQuery'] as String?;
        if (lastSearchQuery != null && lastSearchQuery.isNotEmpty) {
          searchQuery = lastSearchQuery;
          searchController.text = lastSearchQuery;
        }
      }

      // 应用恢复的设置
      if (isFilterActive || searchQuery.isNotEmpty) {
        filterMessages();
      }
    } catch (e) {
      debugPrint('Timeline: 恢复时间线状态时出错: $e');
    }
  }

  /// 设置搜索查询
  void setSearchQuery(String query) {
    searchQuery = query;
    filterMessages();
    notifyListeners();
  }

  /// 切换筛选器激活状态
  void toggleFilterActive() {
    isFilterActive = !isFilterActive;
    filterMessages();
    notifyListeners();
  }

  @override
  void dispose() {
    // 移除监听器
    chatPlugin.removeListener(_onChatDataChanged);
    searchController.removeListener(onSearchChanged);

    // 释放控制器已在父类中处理
    super.dispose();
  }
}
