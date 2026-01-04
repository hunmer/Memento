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
import 'package:Memento/widgets/event_listener_container.dart';
import 'agent_chat_plugin.dart';
import 'controllers/conversation_controller.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';

/// Agent Chat插件的主页小组件注册
class AgentChatHomeWidgets {
  /// 注册所有Agent Chat插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(
      HomeWidget(
        id: 'agent_chat_icon',
        pluginId: 'agent_chat',
        name: 'agent_chat_name'.tr,
        description: 'agent_chat_description'.tr,
        icon: Icons.chat_bubble_outline,
        color: const Color(0xFF2196F3),
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
        category: 'home_categoryTools'.tr,
        builder:
            (context, config) => GenericIconWidget(
              icon: Icons.chat_bubble_outline,
              color: const Color(0xFF2196F3),
              name: 'agent_chat_name'.tr,
            ),
      ),
    );

    // 2x2 详细卡片 - 显示统计信息
    registry.register(
      HomeWidget(
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
      ),
    );

    // 选择器小组件 - 快速进入指定频道
    registry.register(
      HomeWidget(
        id: 'agent_chat_conversation_selector',
        pluginId: 'agent_chat',
        name: 'agent_chat_conversationQuickAccess'.tr,
        description: 'agent_chat_conversationQuickAccessDesc'.tr,
        icon: Icons.chat,
        color: const Color(0xFF2196F3),
        defaultSize: HomeWidgetSize.medium,
        supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
        category: 'home_categoryTools'.tr,

        selectorId: 'agent_chat.conversation',
        dataRenderer: _renderConversationData,
        navigationHandler: _navigateToConversation,
        dataSelector: _extractConversationData,

        builder: (context, config) {
          return GenericSelectorWidget(
            widgetDefinition:
                registry.getWidget('agent_chat_conversation_selector')!,
            config: config,
          );
        },
      ),
    );
  }

  /// 从选择器数据数组中提取小组件需要的数据
  static Map<String, dynamic> _extractConversationData(List<dynamic> dataArray) {
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

  /// 渲染选中的会话数据
  static Widget _renderConversationData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    // 从初始化数据中获取会话ID
    final convData = result.data as Map<String, dynamic>;
    final conversationId = convData['id'] as String?;

    if (conversationId == null) {
      return _buildErrorWidget(context, 'agent_chat_conversationNotFound'.tr);
    }

    // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
    return StatefulBuilder(
      builder: (context, setState) {
        return EventListenerContainer(
          events: const [
            'agent_chat_conversation_added',
            'agent_chat_conversation_updated',
            'agent_chat_conversation_deleted',
          ],
          onEvent: () => setState(() {}),
          child: _buildConversationWidget(context, conversationId),
        );
      },
    );
  }

  /// 构建会话小组件内容（获取最新数据）
  static Widget _buildConversationWidget(BuildContext context, String conversationId) {
    // 从 PluginManager 获取最新的会话数据
    final plugin = PluginManager.instance.getPlugin('agent_chat') as AgentChatPlugin?;
    if (plugin == null) {
      return _buildErrorWidget(context, 'agent_chat_pluginNotAvailable'.tr);
    }

    // 查找对应会话
    final conversation = plugin.conversationController!.conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => throw Exception('会话不存在'),
    );

    // 获取小组件尺寸
    final widgetSize = HomeWidgetSize.large; // 默认值，实际应从 context 获取

    // 使用最新的会话数据
    final title = conversation.title;
    final lastMessagePreview = conversation.lastMessagePreview ?? '';
    final lastMessageAt = conversation.lastMessageAt ?? DateTime.now();
    final agentId = conversation.agentId;

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
                  Icon(
                    Icons.chat_bubble,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 最后一条消息预览
              if (lastMessagePreview.isNotEmpty)
                Expanded(
                  child: Text(
                    lastMessagePreview,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer.withOpacity(0.7),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const Expanded(
                  child: Center(
                    child: Text(
                      '暂无消息',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

              // 时间和 Agent 信息
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDateTime(lastMessageAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer.withOpacity(0.6),
                    ),
                  ),
                  // Agent 信息（异步加载）
                  if (agentId != null)
                    FutureBuilder<AIAgent?>(
                      future: _getAgentById(agentId),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.smart_toy_outlined,
                                size: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer.withOpacity(0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                snapshot.data!.name,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer.withOpacity(0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 根据 ID 获取 Agent
  static Future<AIAgent?> _getAgentById(String agentId) async {
    try {
      final openAIPlugin =
          PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;
      if (openAIPlugin != null) {
        return await openAIPlugin.controller.getAgent(agentId);
      }
    } catch (e) {
      debugPrint('获取 Agent 失败: $e');
    }
    return null;
  }

  /// 导航到选中的会话
  static void _navigateToConversation(
    BuildContext context,
    SelectorResult result,
  ) {
    final convData = result.data as Map<String, dynamic>;
    final conversationId = convData['id'] as String;

    NavigationHelper.pushNamed(
      context,
      '/agent_chat/chat',
      arguments: {'conversationId': conversationId},
    );
  }

  /// 格式化时间显示
  static String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'agent_chat_justNow'.tr;
    } else if (difference.inHours < 1) {
      return 'agent_chat_minutesAgo'.trParams({
        'count': '${difference.inMinutes}',
      });
    } else if (difference.inDays < 1) {
      return 'agent_chat_hoursAgo'.trParams({'count': '${difference.inHours}'});
    } else if (difference.inDays < 7) {
      return 'agent_chat_daysAgo'.trParams({'count': '${difference.inDays}'});
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
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
