import 'package:flutter/material.dart';
import '../../../plugins/agent_chat/agent_chat_plugin.dart';
import '../../plugin_manager.dart';
import 'plugin_widget_syncer.dart';
import 'package:memento_widgets/memento_widgets.dart';

/// AI对话插件同步器
class AgentChatSyncer extends PluginWidgetSyncer {
  @override
  Future<void> sync() async {
    await syncSafely('agent_chat', () async {
      final plugin = PluginManager.instance.getPlugin('agent_chat') as AgentChatPlugin?;
      if (plugin == null) return;

      final totalConversations = plugin.getTotalConversationsCount();
      final todayMessages = await plugin.getTodayMessagesCount();
      final activeConversations = await plugin.getActiveConversationsCount();

      await updateWidget(
        pluginId: 'agent_chat',
        pluginName: 'AI对话',
        iconCodePoint: Icons.smart_toy.codePoint,
        colorValue: Colors.tealAccent.shade700.value,
        stats: [
          WidgetStatItem(
            id: 'conversations',
            label: '总对话',
            value: '$totalConversations',
            highlight: totalConversations > 0,
            colorValue: totalConversations > 0 ? Colors.teal.value : null,
          ),
          WidgetStatItem(
            id: 'today_messages',
            label: '今日消息',
            value: '$todayMessages',
            highlight: todayMessages > 0,
            colorValue: todayMessages > 0 ? Colors.blue.value : null,
          ),
          WidgetStatItem(
            id: 'active',
            label: '活跃会话',
            value: '$activeConversations',
            highlight: activeConversations > 0,
            colorValue: activeConversations > 0 ? Colors.green.value : null,
          ),
        ],
      );
    });
  }
}
