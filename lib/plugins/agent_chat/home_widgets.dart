import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'agent_chat_plugin.dart';
import 'l10n/agent_chat_localizations.dart';

/// Agent Chat插件的主页小组件注册
class AgentChatHomeWidgets {
  /// 注册所有Agent Chat插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'agent_chat_icon',
      pluginId: 'agent_chat',
      name: 'Agent Chat',
      description: 'Quick access to Agent Chat',
      icon: Icons.chat_bubble_outline,
      color: const Color(0xFF2196F3),
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: '工具',
      builder: (context, config) => const GenericIconWidget(
        icon: Icons.chat_bubble_outline,
        color: Color(0xFF2196F3),
        name: 'Agent Chat',
      ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'agent_chat_overview',
      pluginId: 'agent_chat',
      name: 'Agent Chat Overview',
      description: 'Display conversation statistics',
      icon: Icons.analytics_outlined,
      color: const Color(0xFF2196F3),
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: '工具',
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ));
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats() {
    try {
      final plugin = PluginManager.instance.getPlugin('agent_chat') as AgentChatPlugin?;
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

      // Note: We can't use l10n here as this is a static method without context
      // The labels will be translated in the build method if needed
      return [
        StatItemData(
          id: 'total_conversations',
          label: 'Total Conversations', // Default English
          value: '${conversations.length}',
          highlight: conversations.isNotEmpty,
          color: const Color(0xFF2196F3),
        ),
        StatItemData(
          id: 'unread_messages',
          label: 'Unread Messages', // Default English
          value: '$totalUnread',
          highlight: totalUnread > 0,
          color: Colors.orange,
        ),
        StatItemData(
          id: 'total_groups',
          label: 'Total Groups', // Default English
          value: '${controller.groups.length}',
          highlight: controller.groups.isNotEmpty,
          color: Colors.purple,
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(BuildContext context, Map<String, dynamic> config) {
    try {
      final l10n = AgentChatLocalizations.of(context);

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

      // 获取基础统计项数据
      final baseItems = _getAvailableStats();

      // 使用l10n更新统计项标签
      final availableItems = baseItems.map((item) {
        if (item.id == 'total_conversations') {
          return StatItemData(
            id: item.id,
            label: l10n.totalConversations,
            value: item.value,
            highlight: item.highlight,
            color: item.color,
          );
        } else if (item.id == 'unread_messages') {
          return StatItemData(
            id: item.id,
            label: l10n.unreadMessages,
            value: item.value,
            highlight: item.highlight,
            color: item.color,
          );
        } else if (item.id == 'total_groups') {
          return StatItemData(
            id: item.id,
            label: l10n.totalGroups,
            value: item.value,
            highlight: item.highlight,
            color: item.color,
          );
        }
        return item;
      }).toList();

      // 使用通用小组件
      return GenericPluginWidget(
        pluginName: l10n.name,
        pluginIcon: Icons.chat_bubble_outline,
        pluginDefaultColor: const Color(0xFF2196F3),
        availableItems: availableItems,
        config: widgetConfig,
      );
    } catch (e) {
      return _buildErrorWidget(context, e.toString());
    }
  }

  /// 构建错误提示组件
  static Widget _buildErrorWidget(BuildContext context, String error) {
    final l10n = AgentChatLocalizations.of(context);
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
