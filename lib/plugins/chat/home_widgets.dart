import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'chat_plugin.dart';

/// 聊天插件的主页小组件注册
class ChatHomeWidgets {
  /// 注册所有聊天插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'chat_icon',
      pluginId: 'chat',
      name: 'chat_widget_name',
      description: 'chat_widget_description',
      icon: Icons.chat_bubble,
      color: Colors.indigoAccent,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: 'communication_category',
      builder: (context, config) => const GenericIconWidget(
        icon: Icons.chat_bubble,
        color: Colors.indigoAccent,
        name: 'chat_widget_icon',
      ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'chat_overview',
      pluginId: 'chat',
      name: 'chat_overview_widget_name',
      description: 'chat_overview_widget_description',
      icon: Icons.chat_bubble_outline,
      color: Colors.indigoAccent,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: 'communication_category',
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ));
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    try {
      final l10n = ChatLocalizations.of(context);
      final plugin = PluginManager.instance.getPlugin('chat') as ChatPlugin?;
      if (plugin == null) return [];

      final channels = plugin.channelService.channels;
      final totalMessages = plugin.channelService.getTotalMessageCount();
      final todayMessages = plugin.channelService.getTodayMessageCount();

      return [
        StatItemData(
          id: 'channel_count',
          label: l10n.channelCount,
          value: '${channels.length}',
          highlight: false,
        ),
        StatItemData(
          id: 'total_messages',
          label: l10n.totalMessages,
          value: '$totalMessages',
          highlight: false,
        ),
        StatItemData(
          id: 'today_messages',
          label: l10n.todayMessages,
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
      final availableItems = _getAvailableStats(context);

      // 使用通用小组件
      return GenericPluginWidget(
        pluginName: l10n.chatWidgetName,
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
    final l10n = ChatLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 32, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            l10n.loadFailed,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
