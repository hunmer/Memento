import 'package:flutter/material.dart';
import 'package:Memento/screens/routing/route_definition.dart';
import 'package:Memento/screens/routing/route_helpers.dart';
import 'package:Memento/plugins/agent_chat/agent_chat_plugin.dart';
import 'package:Memento/plugins/agent_chat/screens/chat_screen/chat_screen.dart';

/// Agent Chat 插件路由注册表
class AgentChatRoutes implements RouteRegistry {
  @override
  String get name => 'AgentChatRoutes';

  @override
  List<RouteDefinition> get routes => [
        // Agent Chat 主页面
        RouteDefinition(
          path: '/agent_chat',
          handler: (settings) {
            String? conversationId;
            if (settings.arguments is Map<String, String>) {
              conversationId = (settings.arguments as Map<String, String>)['conversationId'];
            } else if (settings.arguments is String) {
              conversationId = settings.arguments as String;
            }
            return RouteHelpers.createRoute(AgentChatMainView(conversationId: conversationId));
          },
          description: 'Agent Chat 主页面',
        ),
        RouteDefinition(
          path: 'agent_chat',
          handler: (settings) {
            String? conversationId;
            if (settings.arguments is Map<String, String>) {
              conversationId = (settings.arguments as Map<String, String>)['conversationId'];
            } else if (settings.arguments is String) {
              conversationId = settings.arguments as String;
            }
            return RouteHelpers.createRoute(AgentChatMainView(conversationId: conversationId));
          },
          description: 'Agent Chat 主页面（别名）',
        ),

        // Agent Chat 聊天页面
        RouteDefinition(
          path: '/agent_chat/chat',
          handler: (settings) {
            String? chatConversationId;

            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              chatConversationId = args['conversationId'] as String?;
            }

            if (chatConversationId == null) {
              debugPrint('错误: 缺少必需参数 conversationId');
              return RouteHelpers.createRoute(const AgentChatMainView());
            }

            debugPrint('打开 Agent Chat 聊天页: conversationId=$chatConversationId');

            // 获取插件实例
            final agentChatPlugin = AgentChatPlugin.instance;
            final controller = agentChatPlugin.conversationController;

            if (controller == null) {
              debugPrint('错误: conversationController 未初始化');
              return RouteHelpers.createRoute(const AgentChatMainView());
            }

            // 查找指定的会话
            try {
              final conversation = controller.conversations.firstWhere(
                (c) => c.id == chatConversationId,
              );

              return RouteHelpers.createRoute(
                ChatScreen(
                  conversation: conversation,
                  storage: controller.storage,
                  conversationService: controller.conversationService,
                  getSettings: () => agentChatPlugin.settings,
                ),
              );
            } catch (e) {
              debugPrint('错误: 找不到会话 $chatConversationId');
              return RouteHelpers.createRoute(const AgentChatMainView());
            }
          },
          description: 'Agent Chat 聊天页面',
        ),
        RouteDefinition(
          path: 'agent_chat/chat',
          handler: (settings) {
            String? chatConversationId;

            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              chatConversationId = args['conversationId'] as String?;
            }

            if (chatConversationId == null) {
              debugPrint('错误: 缺少必需参数 conversationId');
              return RouteHelpers.createRoute(const AgentChatMainView());
            }

            debugPrint('打开 Agent Chat 聊天页: conversationId=$chatConversationId');

            // 获取插件实例
            final agentChatPlugin = AgentChatPlugin.instance;
            final controller = agentChatPlugin.conversationController;

            if (controller == null) {
              debugPrint('错误: conversationController 未初始化');
              return RouteHelpers.createRoute(const AgentChatMainView());
            }

            // 查找指定的会话
            try {
              final conversation = controller.conversations.firstWhere(
                (c) => c.id == chatConversationId,
              );

              return RouteHelpers.createRoute(
                ChatScreen(
                  conversation: conversation,
                  storage: controller.storage,
                  conversationService: controller.conversationService,
                  getSettings: () => agentChatPlugin.settings,
                ),
              );
            } catch (e) {
              debugPrint('错误: 找不到会话 $chatConversationId');
              return RouteHelpers.createRoute(const AgentChatMainView());
            }
          },
          description: 'Agent Chat 聊天页面（别名）',
        ),
      ];
}
