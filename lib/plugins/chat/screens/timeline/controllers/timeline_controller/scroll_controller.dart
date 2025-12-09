import 'package:flutter/material.dart';
import 'base_controller.dart';

/// 滚动控制相关功能的混入类
mixin ScrollControllerMixin on BaseTimelineController {
  /// 滚动监听
  void onScroll() {
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
        loadMoreMessages();
      }
    } catch (e) {
      debugPrint('Timeline: 滚动监听器错误: \$e');
    }
  }

  /// 确保滚动监听器已添加
  void ensureScrollListener() {
    if (!scrollController.hasListeners) {
      scrollController.addListener(onScroll);
    }
  }

  /// 手动检查并重新添加滚动监听器（可从UI层调用）
  void ensureScrollListenerActive() {
    ensureScrollListener();

    // 立即检查是否需要加载更多
    if (scrollController.hasClients && hasMoreMessages && !isLoadingMore) {
      try {
        final maxScroll = scrollController.position.maxScrollExtent;
        final currentScroll = scrollController.position.pixels;
        final distanceToBottom = maxScroll - currentScroll;
        final viewportHeight = scrollController.position.viewportDimension;

        debugPrint(
          'Timeline: 主动检查滚动位置 - 距底部: \$distanceToBottom, 视口高度: \$viewportHeight',
        );

        // 减小触发阈值，使加载更多更容易触发
        if (distanceToBottom < viewportHeight * 1.0) {
          debugPrint('Timeline: 主动触发加载更多');
          loadMoreMessages();
        }
      } catch (e) {
        debugPrint('Timeline: 主动检查滚动位置错误: \$e');
      }
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(onScroll);
    super.dispose();
  }

  // 需要实现的方法
  void loadMoreMessages();
  bool get hasMoreMessages;
  bool get isLoadingMore;
}