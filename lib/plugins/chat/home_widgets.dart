import 'package:flutter/material.dart';
import '../../screens/home_screen/models/home_widget_size.dart';
import '../../screens/home_screen/widgets/home_widget.dart';
import '../../screens/home_screen/widgets/generic_plugin_widget.dart';
import '../../screens/home_screen/models/plugin_widget_config.dart';
import '../../screens/home_screen/managers/home_widget_registry.dart';
import '../../core/plugin_manager.dart';
import 'chat_plugin.dart';
import 'l10n/chat_localizations.dart';

/// 聊天插件的主页小组件注册
class ChatHomeWidgets {
  /// 注册所有聊天插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'chat_icon',
      pluginId: 'chat',
      name: '聊天',
      description: '快速打开聊天',
      icon: Icons.chat_bubble,
      color: Colors.indigoAccent,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: '通讯',
      builder: (context, config) => const GenericIconWidget(
        icon: Icons.chat_bubble,
        color: Colors.indigoAccent,
      ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'chat_overview',
      pluginId: 'chat',
      name: '聊天概览',
      description: '显示频道和消息统计',
      icon: Icons.chat_bubble_outline,
      color: Colors.indigoAccent,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: '通讯',
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ));
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats() {
    try {
      final plugin = PluginManager.instance.getPlugin('chat') as ChatPlugin?;
      if (plugin == null) return [];

      final channels = plugin.channelService.channels;
      final totalMessages = plugin.channelService.getTotalMessageCount();
      final todayMessages = plugin.channelService.getTodayMessageCount();

      return [
        StatItemData(
          id: 'channel_count',
          label: '频道数',
          value: '${channels.length}',
          highlight: false,
        ),
        StatItemData(
          id: 'total_messages',
          label: '总消息数',
          value: '$totalMessages',
          highlight: false,
        ),
        StatItemData(
          id: 'today_messages',
          label: '今日消息',
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
  static Widget _buildOverviewWidget(BuildContext context, Map<String, dynamic> config) {
    try {
      final l10n = ChatLocalizations.of(context);

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
      final availableItems = _getAvailableStats();

      // 使用通用小组件
      return GenericPluginWidget(
        pluginName: l10n.name,
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
            '加载失败',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
