import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../models/message.dart';
import '../../models/timeline_filter.dart';
import 'base_controller.dart';

/// 搜索和过滤相关功能的混入类
mixin SearchControllerMixin on BaseTimelineController {
  Timer? _searchDebounce;

  /// 监听搜索输入变化
  void onSearchChanged() {
    // 取消之前的计时器
    _searchDebounce?.cancel();

    // 设置新的计时器，300ms 后执行搜索
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      final newQuery = searchController.text;

      // 检查搜索查询是否发生了变化
      if (searchQuery != newQuery) {
        searchQuery = newQuery;
        filterMessages(saveState: true);
        notifyListeners();
      }
    });
  }

  /// 根据搜索查询和高级过滤器过滤消息
  void filterMessages({bool saveState = true}) {
    debugPrint('Timeline: 开始过滤消息...');

    // 如果没有搜索词且过滤器未激活，直接使用所有消息
    if (searchQuery.isEmpty && !isFilterActive) {
      filteredMessages = List<Message>.from(allMessages);
      debugPrint('Timeline: 无过滤条件，显示所有 ${allMessages.length} 条消息');

      // 重置分页并加载第一页
      resetPagination();
      loadCurrentPage();
      return;
    }

    // 先应用基本的搜索过滤
    List<Message> result = List<Message>.from(allMessages);

    // 应用文本搜索
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((message) {
        bool matches = false;

        // 根据过滤器设置决定搜索范围
        if (filter.includeContent) {
          matches = matches || message.content.toLowerCase().contains(query);
        }

        if (filter.includeUsernames) {
          matches = matches ||
              message.user.username.toLowerCase().contains(query);
        }

        if (filter.includeChannels) {
          final channelInfo =
              message.metadata?['channelInfo'] as Map<String, dynamic>?;
          final channelName = channelInfo?['channelName'] as String?;
          matches = matches || channelName?.toLowerCase().contains(query) == true;
        }

        return matches;
      }).toList();
    }

    // 应用高级过滤器
    if (isFilterActive) {
      // 过滤频道
      if (filter.selectedChannelIds.isNotEmpty) {
        result = result.where((message) {
          final channelInfo =
              message.metadata?['channelInfo'] as Map<String, dynamic>?;
          final channelId = channelInfo?['channelId'] as String?;
          return channelId != null &&
              filter.selectedChannelIds.contains(channelId);
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
              23,
              59,
              59,
              999,
            );
            matchesEndDate = messageDate.isBefore(endDate) ||
                messageDate.isAtSameMomentAs(endDate);
          }

          return matchesStartDate && matchesEndDate;
        }).toList();
      }

      // 过滤 AI 消息
      if (filter.isAI != null) {
        result = result.where((message) {
          final isAI = message.metadata?['isAI'] as bool? ?? false;
          return filter.isAI! ? isAI : !isAI;
        }).toList();
        debugPrint('Timeline: 应用 AI 消息过滤，剩余 ${result.length} 条消息');
      }

      // 过滤收藏消息
      if (filter.isFavorite != null) {
        result = result.where((message) {
          final isFavorite = message.metadata?['isFavorite'] as bool? ?? false;
          return filter.isFavorite! ? isFavorite : !isFavorite;
        }).toList();
        debugPrint('Timeline: 应用收藏消息过滤，剩余 ${result.length} 条消息');
      }
    }

    filteredMessages = result;

    // 重置分页状态
    resetPagination();

    // 使用微任务确保在当前构建周期之后加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadCurrentPage();
    });

    debugPrint('Timeline: 过滤后共有 ${filteredMessages.length} 条消息');
  }

  /// 应用高级过滤器
  void applyFilter(TimelineFilter newFilter) {
    debugPrint('Timeline: 开始应用新的过滤器...');
    
    // 使用微任务确保在当前构建周期之后执行过滤操作
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 更新过滤器设置
      filter.includeChannels = newFilter.includeChannels;
      filter.includeUsernames = newFilter.includeUsernames;
      filter.includeContent = newFilter.includeContent;
      filter.startDate = newFilter.startDate;
      filter.endDate = newFilter.endDate;
      filter.selectedChannelIds = newFilter.selectedChannelIds;
      filter.selectedUserIds = newFilter.selectedUserIds;
      filter.isAI = newFilter.isAI;
      filter.isFavorite = newFilter.isFavorite;

      // 检查过滤器是否有效
      isFilterActive = filter.selectedChannelIds.isNotEmpty ||
          filter.selectedUserIds.isNotEmpty ||
          filter.startDate != null ||
          filter.endDate != null ||
          !filter.includeChannels ||
          !filter.includeUsernames ||
          !filter.includeContent ||
          filter.isAI != null ||
          filter.isFavorite != null;

      // 应用过滤器并保存状态
      filterMessages(saveState: true);
      notifyListeners();
      
      debugPrint('Timeline: 新的过滤器已应用');
    });
  }

  /// 重置过滤器
  void resetFilter() {
    debugPrint('Timeline: 重置过滤器...');
    
    // 使用微任务确保在当前构建周期之后执行过滤操作
    WidgetsBinding.instance.addPostFrameCallback((_) {
      filter.reset();
      isFilterActive = false;
      filterMessages(saveState: true);
      ensureScrollListener(); // 确保滚动监听器已添加
      notifyListeners();
      
      debugPrint('Timeline: 过滤器已重置');
    });
  }

  /// 清空搜索并更新结果
  void clearSearch() {
    // 取消可能正在进行的搜索防抖
    _searchDebounce?.cancel();

    // 清空搜索控制器
    searchController.clear();

    // 立即处理清空搜索的情况
    debugPrint('Timeline: 清空搜索查询');
    searchQuery = '';
    filterMessages(saveState: true);

    // 使用微任务确保UI更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  // 需要实现的方法
  void resetPagination();
  void loadCurrentPage();
  void ensureScrollListener();
}