import 'package:flutter/material.dart';
import 'base_controller.dart';

/// 分页控制相关功能的混入类
mixin PaginationControllerMixin on BaseTimelineController {
  // 分页相关
  static const int pageSize = 50; // 每页显示的消息数量
  int currentPage = 1;
  bool hasMoreMessages = true;
  bool isLoadingMore = false;
  DateTime? lastLoadTime;

  /// 加载当前页的消息
  void loadCurrentPage() {
    debugPrint('Timeline: 开始加载第 $currentPage 页...');

    if (filteredMessages.isEmpty) {
      debugPrint('Timeline: 没有可显示的消息');
      displayMessages = [];
      hasMoreMessages = false;
      notifyListeners();
      return;
    }

    final startIndex = (currentPage - 1) * pageSize;
    final endIndex = startIndex + pageSize;

    // 检查是否还有更多消息
    if (startIndex >= filteredMessages.length) {
      hasMoreMessages = false;
      notifyListeners();
      return;
    }

    // 获取当前页的消息
    final actualEndIndex =
        endIndex < filteredMessages.length
            ? endIndex
            : filteredMessages.length;
    final pageMessages = filteredMessages.sublist(startIndex, actualEndIndex);

    if (currentPage == 1) {
      displayMessages = List.from(pageMessages);
    } else {
      displayMessages.addAll(pageMessages);
    }

    // 更新是否还有更多消息
    hasMoreMessages = actualEndIndex < filteredMessages.length;

    // 保存当前状态
    saveTimelineState();
    
    notifyListeners();
  }

  /// 加载更多消息
  void loadMoreMessages() {
    // 检查是否正在加载或没有更多消息
    if (isLoadingMore || !hasMoreMessages) {
      return;
    }

    // 检查距离上次加载的时间间隔（防抖）
    final now = DateTime.now();
    if (lastLoadTime != null &&
        now.difference(lastLoadTime!) < const Duration(seconds: 1)) {
      return;
    }

    isLoadingMore = true;
    lastLoadTime = now;

    try {
      currentPage++;
      loadCurrentPage();
    } finally {
      isLoadingMore = false;
      // 保存加载更多后的状态
      saveTimelineState();
    }
  }

  /// 重置分页状态
  void resetPagination() {
    currentPage = 1;
    hasMoreMessages = true;
    displayMessages = [];
    // 保存重置后的状态
    saveTimelineState();
  }
}