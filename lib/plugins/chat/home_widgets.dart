import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
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
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
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
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large],
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
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
        category: 'home_categoryCommunication'.tr,

        selectorId: 'chat.channel',
        dataRenderer: _renderChannelData,
        navigationHandler: _navigateToChannel,

        builder: (context, config) {
          return GenericSelectorWidget(
            widgetDefinition: registry.getWidget('chat_channel_selector')!,
            config: config,
          );
        },
      ),
    );
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
      return _buildErrorWidget(context, e.toString());
    }
  }

  /// 构建错误提示组件
  static Widget _buildErrorWidget(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 32, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            'home_loadFailed'.tr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// 渲染选中的频道数据
  static Widget _renderChannelData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    final channelData = result.data as Map<String, dynamic>;
    final title = channelData['title'] as String? ?? 'chat_untitled'.tr;
    final lastMessage = channelData['lastMessage'] as String? ?? '';
    final lastMessageTimeStr = channelData['lastMessageTime'] as String?;
    final messageCount = channelData['messageCount'] as int? ?? 0;
    final iconCodePoint = channelData['icon'] as int?;
    final backgroundColorValue = channelData['backgroundColor'] as int?;

    final lastMessageTime =
        lastMessageTimeStr != null
            ? DateTime.parse(lastMessageTimeStr)
            : DateTime.now();

    final channelIcon =
        iconCodePoint != null
            ? IconData(iconCodePoint, fontFamily: 'MaterialIcons')
            : Icons.chat_bubble;

    final channelColor =
        backgroundColorValue != null
            ? Color(backgroundColorValue)
            : Colors.indigoAccent;

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
                )
              else
                Expanded(
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
