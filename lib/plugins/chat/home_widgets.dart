import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/selector_widget_types.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';
import 'chat_plugin.dart';

/// 聊天插件的主页小组件注册
class ChatHomeWidgets {
  /// 注册所有聊天插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(
      HomeWidget(
        id: 'chat_icon',
        pluginId: 'chat',
        name: 'chat_widgetName'.tr,
        description: 'chat_widgetDescription'.tr,
        icon: Icons.chat_bubble,
        color: Colors.indigoAccent,
        defaultSize: const SmallSize(),
        supportedSizes: [const SmallSize()],
        category: 'home_categoryCommunication'.tr,
        builder:
            (context, config) => GenericIconWidget(
              icon: Icons.chat_bubble,
              color: Colors.indigoAccent,
              name: 'chat_widgetName'.tr,
            ),
      ),
    );

    // 2x2 详细卡片 - 显示统计信息
    registry.register(
      HomeWidget(
        id: 'chat_overview',
        pluginId: 'chat',
        name: 'chat_overviewName'.tr,
        description: 'chat_overviewDescription'.tr,
        icon: Icons.chat_bubble_outline,
        color: Colors.indigoAccent,
        defaultSize: const LargeSize(),
        supportedSizes: [const LargeSize()],
        category: 'home_categoryCommunication'.tr,
        builder: (context, config) => _buildOverviewWidget(context, config),
        availableStatsProvider: _getAvailableStats,
      ),
    );

    // 选择器小组件 - 快速进入指定频道
    registry.register(
      HomeWidget(
        id: 'chat_channel_selector',
        pluginId: 'chat',
        name: 'chat_channelQuickAccess'.tr,
        description: 'chat_channelQuickAccessDesc'.tr,
        icon: Icons.chat,
        color: Colors.indigoAccent,
        defaultSize: const LargeSize(),
        category: 'home_categoryCommunication'.tr,

        selectorId: 'chat.channel',
        dataRenderer: _renderChannelData,
        navigationHandler: _navigateToChannel,
        dataSelector: _extractChannelData,

        // 公共小组件提供者
        commonWidgetsProvider: _provideCommonWidgets,

        builder: (context, config) {
          // 解析选择器配置
          SelectorWidgetConfig? selectorConfig;
          try {
            if (config.containsKey('selectorWidgetConfig')) {
              selectorConfig = SelectorWidgetConfig.fromJson(
                config['selectorWidgetConfig'] as Map<String, dynamic>,
              );
            }
          } catch (e) {
            debugPrint('[ChatHomeWidgets] 解析配置失败: $e');
          }

          // 未配置状态
          if (selectorConfig == null || !selectorConfig.isConfigured) {
            return _buildUnconfiguredWidget(context);
          }

          // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
          return StatefulBuilder(
            builder: (context, setState) {
              return EventListenerContainer(
                events: const [
                  'chat_message_sent',
                  'chat_message_updated',
                ],
                onEvent: () => setState(() {}),
                child: _buildSelectorContent(context, config, selectorConfig!),
              );
            },
          );
        },
      ),
    );
  }

  /// 构建未配置状态的占位小组件
  static Widget _buildUnconfiguredWidget(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.expand(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat, size: 32, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              '点击配置频道',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建选择器内容（实时获取最新数据）
  static Widget _buildSelectorContent(
    BuildContext context,
    Map<String, dynamic> config,
    SelectorWidgetConfig selectorConfig,
  ) {
    // 从配置中获取频道ID
    final selectedData = selectorConfig.selectedData;
    if (selectedData == null) {
      return HomeWidget.buildErrorWidget(context, '配置数据无效');
    }

    // 获取频道ID
    final data = selectedData['data'];
    String? channelId;
    if (data is Map<String, dynamic>) {
      channelId = data['id'] as String?;
    } else if (data is List && data.isNotEmpty) {
      final firstItem = data[0];
      if (firstItem is Map<String, dynamic>) {
        channelId = firstItem['id'] as String?;
      }
    }

    if (channelId == null) {
      return HomeWidget.buildErrorWidget(context, 'chat_channelNotFound'.tr);
    }

    // 检查是否使用公共小组件
    if (selectorConfig.usesCommonWidget) {
      return _buildCommonWidgetWithLiveData(
        context,
        config,
        channelId,
        selectorConfig.commonWidgetId!,
        selectorConfig.commonWidgetProps ?? {},
      );
    }

    // 使用自定义渲染器
    final widgetDef = HomeWidgetRegistry().getWidget('chat_channel_selector');
    if (widgetDef?.dataRenderer != null) {
      // 构建一个包含最新数据的 SelectorResult
      final liveData = _getLiveChannelData(channelId);
      if (liveData == null) {
        return HomeWidget.buildErrorWidget(context, 'chat_channelNotFound'.tr);
      }

      final result = SelectorResult(
        pluginId: 'chat',
        selectorId: 'chat.channel',
        path: [],
        data: liveData,
      );

      return widgetDef!.dataRenderer!(context, result, config);
    }

    return _buildChannelWidget(context, channelId);
  }

  /// 使用实时数据构建公共小组件
  static Widget _buildCommonWidgetWithLiveData(
    BuildContext context,
    Map<String, dynamic> config,
    String channelId,
    String commonWidgetId,
    Map<String, dynamic> savedProps,
  ) {
    // 获取实时频道数据
    final liveData = _getLiveChannelData(channelId);
    if (liveData == null) {
      return HomeWidget.buildErrorWidget(context, 'chat_channelNotFound'.tr);
    }

    // 转换为枚举
    final widgetIdEnum = CommonWidgetsRegistry.fromString(commonWidgetId);
    if (widgetIdEnum == null) {
      return HomeWidget.buildErrorWidget(context, '未知的公共组件: $commonWidgetId');
    }

    // 获取元数据
    final metadata = CommonWidgetsRegistry.getMetadata(widgetIdEnum);
    final size = config['widgetSize'] as HomeWidgetSize? ?? metadata.defaultSize;

    // 使用实时数据更新 props
    final liveProps = _getLiveCommonWidgetProps(commonWidgetId, liveData, savedProps);

    // 添加 custom 尺寸的实际宽高到 props 中
    if (size == const CustomSize(width: -1, height: -1)) {
      liveProps['customWidth'] = config['customWidth'] as int?;
      liveProps['customHeight'] = config['customHeight'] as int?;
    }

    return CommonWidgetBuilder.build(
      context,
      widgetIdEnum,
      liveProps,
      size,
      inline: true,
    );
  }

  /// 从插件获取实时的频道数据
  static Map<String, dynamic>? _getLiveChannelData(String channelId) {
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
  static Map<String, dynamic> _getLiveCommonWidgetProps(
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

  /// 公共小组件提供者函数
  static Future<Map<String, Map<String, dynamic>>> _provideCommonWidgets(
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
  static List<String> _getPendingTasks(Map<String, dynamic> data) {
    final lastMessage = data['lastMessage'] as String?;
    if (lastMessage != null && lastMessage.isNotEmpty) {
      return [lastMessage];
    }
    return [];
  }

  /// 从选择器数据数组中提取小组件需要的数据
  static Map<String, dynamic> _extractChannelData(List<dynamic> dataArray) {
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

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
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

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    try {
      // 解析插件配置
      PluginWidgetConfig widgetConfig;
      try {
        if (config.containsKey('pluginWidgetConfig')) {
          widgetConfig = PluginWidgetConfig.fromJson(
            config['pluginWidgetConfig'] as Map<String, dynamic>,
          );
        } else {
          widgetConfig = PluginWidgetConfig();
        }
      } catch (e) {
        widgetConfig = PluginWidgetConfig();
      }

      // 获取可用的统计项数据
      final availableItems = _getAvailableStats(context);

      // 使用通用小组件
      return GenericPluginWidget(
        pluginId: 'chat',
        pluginName: 'chat_widgetName'.tr,
        pluginIcon: Icons.chat_bubble,
        pluginDefaultColor: Colors.indigoAccent,
        availableItems: availableItems,
        config: widgetConfig,
      );
    } catch (e) {
      return HomeWidget.buildErrorWidget(context, e.toString());
    }
  }

  /// 渲染选中的频道数据
  static Widget _renderChannelData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    // 从初始化数据中获取频道ID
    final channelData = result.data as Map<String, dynamic>;
    final channelId = channelData['id'] as String?;

    if (channelId == null) {
      return HomeWidget.buildErrorWidget(context, 'chat_channelNotFound'.tr);
    }

    // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
    return StatefulBuilder(
      builder: (context, setState) {
        return EventListenerContainer(
          events: const ['chat_message_sent', 'chat_message_updated'],
          onEvent: () => setState(() {}),
          child: _buildChannelWidget(context, channelId),
        );
      },
    );
  }

  /// 构建频道小组件内容（获取最新数据）
  static Widget _buildChannelWidget(BuildContext context, String channelId) {
    // 从 PluginManager 获取最新的频道数据
    final plugin = PluginManager.instance.getPlugin('chat') as ChatPlugin?;
    if (plugin == null) {
      return HomeWidget.buildErrorWidget(context, 'chat_pluginNotAvailable'.tr);
    }

    // 查找对应频道
    final channel = plugin.channelService.channels.firstWhere(
      (c) => c.id == channelId,
      orElse: () => throw Exception('频道不存在'),
    );

    // 使用最新的频道数据
    final title = channel.title;
    final lastMessage = channel.lastMessage?.content ?? '';
    final lastMessageTime = channel.lastMessage?.date ?? DateTime.now();
    final messageCount = channel.messages.length;
    final channelIcon = channel.icon;
    final channelColor = channel.backgroundColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: channelColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(channelIcon, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 最后一条消息预览
              if (lastMessage.isNotEmpty)
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lastMessage,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: Text(
                        'chat_noMessages'.tr,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // 底部信息栏
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 左侧：消息数
                  Text(
                    'chat_messageCount'.trParams({'count': '$messageCount'}),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  // 右侧：时间
                  Text(
                    _formatDateTime(lastMessageTime),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 导航到选中的频道
  static void _navigateToChannel(BuildContext context, SelectorResult result) {
    final channelData = result.data as Map<String, dynamic>;
    final channelId = channelData['id'] as String;

    NavigationHelper.pushNamed(
      context,
      '/chat/channel',
      arguments: {'channelId': channelId},
    );
  }

  /// 格式化时间显示
  static String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'chat_justNow'.tr;
    } else if (difference.inHours < 1) {
      return 'chat_minutesAgo'.trParams({'minutes': '${difference.inMinutes}'});
    } else if (difference.inDays < 1) {
      return 'chat_hoursAgo'.trParams({'hours': '${difference.inHours}'});
    } else if (difference.inDays < 7) {
      return 'chat_daysAgo'.trParams({'days': '${difference.inDays}'});
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}
