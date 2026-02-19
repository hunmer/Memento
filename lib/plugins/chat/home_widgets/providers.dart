/// 聊天插件 - 主页小组件数据提供者
///
/// 提供公共小组件、统计数据、实时数据等功能
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';
import 'data.dart';

/// 公共小组件提供者函数
///
/// 为频道数据提供公共小组件的配置
Future<Map<String, Map<String, dynamic>>> provideCommonWidgets(
  Map<String, dynamic> data,
) async {
  // data 包含：id, title, lastMessage, lastMessageTime, messageCount
  final messageCount = (data['messageCount'] as int?) ?? 0;
  final title = (data['title'] as String?) ?? '频道';

  return {
    // 圆形进度卡片：显示消息完成度（假设 100 条消息为满）
    'circularProgressCard': {
      'title': title,
      'subtitle': '$messageCount 条消息',
      'percentage': (messageCount / 100 * 100).clamp(0, 100).toDouble(),
      'progress': (messageCount / 100).clamp(0.0, 1.0),
    },

    // 活动进度卡片：显示消息统计
    'activityProgressCard': {
      'title': title,
      'subtitle': '今日消息',
      'value': messageCount.toDouble(),
      'unit': '条',
      'activities': 1,
      'totalProgress': 10,
      'completedProgress': messageCount % 10,
    },

    // 任务进度卡片：显示最近消息预览
    'taskProgressCard': {
      'title': title,
      'subtitle': '最近消息',
      'completedTasks': messageCount % 20,
      'totalTasks': 20,
      'pendingTasks': _getPendingTasks(data),
    },
  };
}

/// 获取待办任务列表
List<String> _getPendingTasks(Map<String, dynamic> data) {
  final lastMessage = data['lastMessage'] as String?;
  if (lastMessage != null && lastMessage.isNotEmpty) {
    return [lastMessage];
  }
  return [];
}

/// 获取可用的统计项
///
/// 返回聊天插件的统计信息，如频道数、消息数等
List<StatItemData> getAvailableStats(BuildContext context) {
  try {
    final plugin = PluginManager.instance.getPlugin('chat') as ChatPlugin?;
    if (plugin == null) return [];

    final channels = plugin.channelService.channels;
    final totalMessages = plugin.channelService.getTotalMessageCount();
    final todayMessages = plugin.channelService.getTodayMessageCount();

    return [
      StatItemData(
        id: 'channel_count',
        label: 'chat_channelCount'.tr,
        value: '${channels.length}',
        highlight: false,
      ),
      StatItemData(
        id: 'total_messages',
        label: 'chat_totalMessages'.tr,
        value: '$totalMessages',
        highlight: false,
      ),
      StatItemData(
        id: 'today_messages',
        label: 'chat_todayMessages'.tr,
        value: '$todayMessages',
        highlight: todayMessages > 0,
        color: Colors.indigoAccent,
      ),
    ];
  } catch (e) {
    return [];
  }
}

/// 从插件获取实时的频道数据
Map<String, dynamic>? getLiveChannelData(String channelId) {
  try {
    final plugin = PluginManager.instance.getPlugin('chat') as ChatPlugin?;
    if (plugin == null) return null;

    final channel = plugin.channelService.channels.firstWhere(
      (c) => c.id == channelId,
      orElse: () => throw Exception('频道不存在'),
    );

    return {
      'id': channel.id,
      'title': channel.title,
      'lastMessage': channel.lastMessage?.content ?? '',
      'lastMessageTime': channel.lastMessage?.date.toIso8601String() ?? '',
      'messageCount': channel.messages.length,
      'icon': channel.icon.codePoint,
      'backgroundColor': channel.backgroundColor.value,
    };
  } catch (e) {
    debugPrint('[ChatHomeWidgets] 获取频道数据失败: $e');
    return null;
  }
}

/// 获取公共小组件的实时 Props
Map<String, dynamic> getLiveCommonWidgetProps(
  String commonWidgetId,
  Map<String, dynamic> liveData,
  Map<String, dynamic> savedProps,
) {
  final messageCount = liveData['messageCount'] as int? ?? 0;
  final title = liveData['title'] as String? ?? '频道';
  final lastMessage = liveData['lastMessage'] as String? ?? '';

  // 根据 commonWidgetId 返回对应的实时数据
  switch (commonWidgetId) {
    case 'circularProgressCard':
      return {
        'title': title,
        'subtitle': '$messageCount 条消息',
        'percentage': (messageCount / 100 * 100).clamp(0, 100).toDouble(),
        'progress': (messageCount / 100).clamp(0.0, 1.0),
      };

    case 'activityProgressCard':
      return {
        'title': title,
        'subtitle': '今日消息',
        'value': messageCount.toDouble(),
        'unit': '条',
        'activities': 1,
        'totalProgress': 10,
        'completedProgress': messageCount % 10,
      };

    case 'taskProgressCard':
      return {
        'title': title,
        'subtitle': '最近消息',
        'completedTasks': messageCount % 20,
        'totalTasks': 20,
        'pendingTasks': lastMessage.isNotEmpty ? [lastMessage] : [],
      };

    default:
      // 对于其他小组件，合并保存的 props 和实时数据
      return {
        ...savedProps,
        'title': title,
        'messageCount': messageCount,
        'lastMessage': lastMessage,
      };
  }
}

/// 从选择器数据数组中提取小组件需要的数据
Map<String, dynamic> extractChannelData(List<dynamic> dataArray) {
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
  result['lastMessage'] = itemData['lastMessage'] as String?;
  result['lastMessageTime'] = itemData['lastMessageTime'] as String?;
  result['messageCount'] = itemData['messageCount'] as int?;
  result['icon'] = itemData['icon'] as int?;
  // result['backgroundColor'] = itemData['backgroundColor'] as int?;
  return result;
}
