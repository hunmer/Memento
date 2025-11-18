import 'package:flutter/material.dart';
import '../../screens/home_screen/models/home_widget_size.dart';
import '../../screens/home_screen/widgets/home_widget.dart';
import '../../screens/home_screen/widgets/generic_plugin_widget.dart';
import '../../screens/home_screen/models/plugin_widget_config.dart';
import '../../screens/home_screen/managers/home_widget_registry.dart';
import '../../core/plugin_manager.dart';
import 'agent_chat_plugin.dart';

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
      description: '快速打开 Agent Chat',
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
      name: 'Agent Chat 概览',
      description: '显示会话统计信息',
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
      final conversations = controller.conversations;

      // 计算未读消息总数
      int totalUnread = 0;
      for (var conv in conversations) {
        totalUnread += conv.unreadCount;
      }

      return [
        StatItemData(
          id: 'total_conversations',
          label: '会话总数',
          value: '${conversations.length}',
          highlight: conversations.isNotEmpty,
          color: const Color(0xFF2196F3),
        ),
        StatItemData(
          id: 'unread_messages',
          label: '未读消息',
          value: '$totalUnread',
          highlight: totalUnread > 0,
          color: Colors.orange,
        ),
        StatItemData(
          id: 'total_groups',
          label: '分组总数',
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
        pluginName: 'Agent Chat',
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
