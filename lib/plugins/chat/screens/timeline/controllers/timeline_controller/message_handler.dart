import 'package:flutter/material.dart';
import '../../../../models/message.dart';
import '../../../../models/channel.dart';
import '../../models/timeline_filter.dart';
import 'base_controller.dart';

/// 消息处理相关功能的混入类
mixin MessageHandlerMixin on BaseTimelineController {
  /// 获取消息所属的频道
  Channel? getMessageChannel(Message message) {
    final channelId = message.channelId;
    if (channelId == null) return null;

    try {
      return chatPlugin.channelService.channels.firstWhere(
        (c) => c.id == channelId,
      );
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
    try {
      if (onMessageDelete != null) {
        await onMessageDelete!(message);
      }

      // 从各个列表中移除消息
      removeMessage(message);

      debugPrint('Timeline: 成功删除消息 \${message.id}');
    } catch (e) {
      debugPrint('Timeline: 删除消息失败: \$e');
      // 如果删除失败，刷新时间线以确保显示正确的状态
      await refreshTimeline();
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

  /// 处理消息收藏
  void handleToggleFavorite(Message message) {
    if (onToggleFavorite != null) {
      onToggleFavorite!(message);
    }
  }

  /// 从列表中删除单个消息，不刷新整个时间线
  void removeMessage(Message message) {
    // 从所有消息列表中移除
    allMessages.removeWhere((m) => m.id == message.id);

    // 从过滤后的消息列表中移除
    filteredMessages.removeWhere((m) => m.id == message.id);

    // 从当前显示的消息列表中移除
    displayMessages.removeWhere((m) => m.id == message.id);

    debugPrint('Timeline: 移除了单条消息 \${message.id}');
    notifyListeners();
  }

  /// 更新单个消息，不刷新整个时间线
  void updateMessage(Message message) {
    // 查找并更新所有消息列表中的消息
    final allIndex = allMessages.indexWhere((m) => m.id == message.id);
    if (allIndex != -1) {
      allMessages[allIndex] = message;
    }

    // 查找并更新过滤后消息列表中的消息
    final filteredIndex = filteredMessages.indexWhere(
      (m) => m.id == message.id,
    );
    if (filteredIndex != -1) {
      filteredMessages[filteredIndex] = message;
    }

    // 查找并更新当前显示的消息列表中的消息
    final displayIndex = displayMessages.indexWhere((m) => m.id == message.id);
    if (displayIndex != -1) {
      displayMessages[displayIndex] = message;
    }

    debugPrint('Timeline: 更新了单条消息 \${message.id}');
    notifyListeners();
  }

  /// 刷新时间线数据
  Future<void> refreshTimeline();

  /// 根据当前的搜索和过滤条件过滤消息
  /// 
  /// [saveState] - 是否保存过滤后的状态，默认为 true
  void filterMessages({bool saveState = true}) {
    debugPrint('Timeline: 开始过滤消息...');
    
    // 先应用搜索过滤
    if (searchQuery.isEmpty) {
      filteredMessages = List.from(allMessages);
    } else {
      final query = searchQuery.toLowerCase();
      filteredMessages = allMessages.where((message) {
        return message.content.toLowerCase().contains(query) ||
            message.user.username.toLowerCase().contains(query);
      }).toList();
    }

    // 应用过滤器
    if (isFilterActive) {
      switch (filter.type) {
        case TimelineFilterType.all:
          // 保持所有消息
          break;
        case TimelineFilterType.text:
          filteredMessages = filteredMessages.where((message) {
            return message.type == MessageType.received || message.type == MessageType.sent;
          }).toList();
          break;
        case TimelineFilterType.image:
          filteredMessages = filteredMessages.where((message) {
            return message.type == MessageType.image;
          }).toList();
          break;
        case TimelineFilterType.file:
          filteredMessages = filteredMessages.where((message) {
            return message.type == MessageType.file;
          }).toList();
          break;
        case TimelineFilterType.system:
          // 暂时保持所有消息，因为还没有系统消息类型
          break;
        case TimelineFilterType.dateRange:
          if (filter.startDate != null || filter.endDate != null) {
            filteredMessages = filteredMessages.where((message) {
              if (filter.startDate != null && message.date.isBefore(filter.startDate!)) {
                return false;
              }
              if (filter.endDate != null && message.date.isAfter(filter.endDate!)) {
                return false;
              }
              return true;
            }).toList();
          }
          break;
        case TimelineFilterType.user:
          if (filter.selectedUserIds.isNotEmpty) {
            filteredMessages = filteredMessages.where((message) {
              return filter.selectedUserIds.contains(message.user.id);
            }).toList();
          }
          break;
        case TimelineFilterType.custom:
          // 处理自定义筛选逻辑
          if (filter.isFavorite == true) {
            filteredMessages = filteredMessages.where((message) {
              return message.metadata?['isFavorite'] == true;
            }).toList();
          }
          if (filter.isAI == true) {
            var result = filteredMessages.where((message) {
              return message.metadata?['isAI'] == true;
            }).toList();
            debugPrint('Timeline: 应用 AI 消息过滤，剩余 ${result.length} 条消息');
            filteredMessages = result;
          }
          break;
      }
    }

    // 更新显示的消息列表
    displayMessages = List.from(filteredMessages);
    
    debugPrint('Timeline: 过滤后共有 ${filteredMessages.length} 条消息');
    
    // 根据参数决定是否保存状态
    if (saveState) {
      saveTimelineState();
    }
    
    notifyListeners();
  }
}