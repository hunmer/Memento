import 'package:flutter/foundation.dart';
import 'package:Memento/screens/routing/route_definition.dart';
import 'package:Memento/screens/routing/route_helpers.dart';
import 'package:Memento/plugins/webview/screens/webview_browser_screen.dart';

/// WebView 插件路由注册表
class WebViewRoutes implements RouteRegistry {
  @override
  String get name => 'WebViewRoutes';

  @override
  List<RouteDefinition> get routes => [
        // WebView 浏览器页面
        RouteDefinition(
          path: '/webview/browser',
          handler: (settings) {
            String? url;
            String? title;
            String? cardId;
            bool hideUI = false;

            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              url = args['url'] as String?;
              title = args['title'] as String?;
              cardId = args['cardId'] as String?;
              hideUI = args['hideUI'] as bool? ?? false;
            }

            debugPrint('打开 WebView 浏览器: url=$url, cardId=$cardId, hideUI=$hideUI');

            return RouteHelpers.createRoute(
              WebViewBrowserScreen(
                initialUrl: url,
                initialTitle: title,
                cardId: cardId,
                hideUI: hideUI,
              ),
            );
          },
          description: 'WebView 浏览器页面',
        ),
        RouteDefinition(
          path: 'webview/browser',
          handler: (settings) {
            String? url;
            String? title;
            String? cardId;
            bool hideUI = false;

            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              url = args['url'] as String?;
              title = args['title'] as String?;
              cardId = args['cardId'] as String?;
              hideUI = args['hideUI'] as bool? ?? false;
            }

            debugPrint('打开 WebView 浏览器: url=$url, cardId=$cardId, hideUI=$hideUI');

            return RouteHelpers.createRoute(
              WebViewBrowserScreen(
                initialUrl: url,
                initialTitle: title,
                cardId: cardId,
                hideUI: hideUI,
              ),
            );
          },
          description: 'WebView 浏览器页面（别名）',
        ),
      ];
}
