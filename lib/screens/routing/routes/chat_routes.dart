import 'package:flutter/material.dart';
import 'package:Memento/screens/routing/route_definition.dart';
import 'package:Memento/screens/routing/route_helpers.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';

/// Chat 插件路由注册表
class ChatRoutes implements RouteRegistry {
  @override
  String get name => 'ChatRoutes';

  @override
  List<RouteDefinition> get routes => [
        // Chat 主页面
        RouteDefinition(
          path: '/chat',
          handler: (settings) {
            String? channelId;
            if (settings.arguments is Map<String, String>) {
              channelId = (settings.arguments as Map<String, String>)['channelId'];
            } else if (settings.arguments is String) {
              channelId = settings.arguments as String;
            }
            return RouteHelpers.createRoute(ChatMainView(channelId: channelId));
          },
          description: 'Chat 主页面',
        ),
        RouteDefinition(
          path: 'chat',
          handler: (settings) {
            String? channelId;
            if (settings.arguments is Map<String, String>) {
              channelId = (settings.arguments as Map<String, String>)['channelId'];
            } else if (settings.arguments is String) {
              channelId = settings.arguments as String;
            }
            return RouteHelpers.createRoute(ChatMainView(channelId: channelId));
          },
          description: 'Chat 主页面（别名）',
        ),

        // Chat 频道页面
        RouteDefinition(
          path: '/chat/channel',
          handler: (settings) {
            String? chatChannelId;
            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              chatChannelId = args['channelId'] as String?;
            }

            if (chatChannelId == null) {
              debugPrint('错误: 缺少必需参数 channelId');
              return RouteHelpers.createRoute(const ChatMainView());
            }

            debugPrint('打开 Chat 频道: channelId=$chatChannelId');
            return RouteHelpers.createRoute(ChatMainView(channelId: chatChannelId));
          },
          description: 'Chat 频道页面',
        ),
        RouteDefinition(
          path: 'chat/channel',
          handler: (settings) {
            String? chatChannelId;
            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              chatChannelId = args['channelId'] as String?;
            }

            if (chatChannelId == null) {
              debugPrint('错误: 缺少必需参数 channelId');
              return RouteHelpers.createRoute(const ChatMainView());
            }

            debugPrint('打开 Chat 频道: channelId=$chatChannelId');
            return RouteHelpers.createRoute(ChatMainView(channelId: chatChannelId));
          },
          description: 'Chat 频道页面（别名）',
        ),
      ];
}
