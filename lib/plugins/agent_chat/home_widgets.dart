import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'agent_chat_plugin.dart';
import 'controllers/conversation_controller.dart';

/// Agent Chat插件的主页小组件注册
class AgentChatHomeWidgets {
  /// 注册所有Agent Chat插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'agent_chat_icon',
      pluginId: 'agent_chat',
      name: 'agent_chat_name'.tr,
      description: 'agent_chat_description'.tr,
      icon: Icons.chat_bubble_outline,
      color: const Color(0xFF2196F3),
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => GenericIconWidget(
        icon: Icons.chat_bubble_outline,
        color: const Color(0xFF2196F3),
        name: 'agent_chat_name'.tr,
      ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'agent_chat_overview',
      pluginId: 'agent_chat',
      name: 'agent_chat_overview'.tr,
      description: 'agent_chat_overviewDescription'.tr,
      icon: Icons.analytics_outlined,
      color: const Color(0xFF2196F3),
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ));
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
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
  static int _getUniqueGroupsCount(ConversationController controller) {
    final allGroupNames = <String>{};
    // 重要：使用 allConversations 而不是 conversations，以确保分组计数准确
    for (final conv in controller.allConversations) {
      allGroupNames.addAll(conv.groups);
    }
    return allGroupNames.length;
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

      // 获取基础统计项数据
      final baseItems = _getAvailableStats(context);

      // 使用GetX翻译更新统计项标签
      final availableItems = baseItems;

      // 使用通用小组件
      return GenericPluginWidget(
        pluginId: 'agent_chat',
        pluginName: 'agent_chat_name'.tr,
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
            'home_loadFailed'.tr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
