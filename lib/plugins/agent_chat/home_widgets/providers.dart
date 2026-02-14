/// Agent Chat 插件主页小组件数据提供者
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import '../agent_chat_plugin.dart';
import '../controllers/conversation_controller.dart';
import 'data.dart';

/// 获取可用的统计项
List<StatItemData> getAvailableStats(BuildContext context) {
  try {
    final plugin =
        PluginManager.instance.getPlugin('agent_chat') as AgentChatPlugin?;
    if (plugin == null || !plugin.isInitialized) {
      return [];
    }

    final controller = plugin.conversationController;
    final conversations = controller!.conversations;

    // 计算未读消息总数
    int totalUnread = 0;
    for (var conv in conversations) {
      totalUnread += conv.unreadCount;
    }

    return [
      StatItemData(
        id: 'total_conversations',
        label: 'agent_chat_totalConversations'.tr,
        value: '${conversations.length}',
        highlight: conversations.isNotEmpty,
        color: const Color(0xFF2196F3),
      ),
      StatItemData(
        id: 'unread_messages',
        label: 'agent_chat_unreadMessages'.tr,
        value: '$totalUnread',
        highlight: totalUnread > 0,
        color: Colors.orange,
      ),
      StatItemData(
        id: 'total_groups',
        label: 'agent_chat_totalGroups'.tr,
        value: '${_getUniqueGroupsCount(controller)}',
        highlight: _getUniqueGroupsCount(controller) > 0,
        color: Colors.purple,
      ),
    ];
  } catch (e) {
    return [];
  }
}

/// 获取唯一分组的数量
int _getUniqueGroupsCount(ConversationController controller) {
  final allGroupNames = <String>{};
  // 重要：使用 allConversations 而不是 conversations，以确保分组计数准确
  for (final conv in controller.allConversations) {
    allGroupNames.addAll(conv.groups);
  }
  return allGroupNames.length;
}

/// 从选择器数据数组中提取小组件需要的数据
Map<String, dynamic> extractConversationData(List<dynamic> dataArray) {
  Map<String, dynamic> itemData = {};
  final rawData = dataArray[0];

  if (rawData is Map<String, dynamic>) {
    itemData = rawData;
  } else if (rawData is dynamic && rawData.toJson != null) {
    final jsonResult = rawData.toJson();
    if (jsonResult is Map<String, dynamic>) {
      itemData = jsonResult;
    }
  }

  final result = <String, dynamic>{};
  result['id'] = itemData['id'] as String?;
  result['title'] = itemData['title'] as String?;
  result['lastMessagePreview'] = itemData['lastMessagePreview'] as String?;
  result['lastMessageAt'] = itemData['lastMessageAt'] as String?;
  result['agentId'] = itemData['agentId'] as String?;
  return result;
}
