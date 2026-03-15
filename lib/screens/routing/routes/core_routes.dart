import 'package:Memento/screens/routing/route_definition.dart';
import 'package:Memento/screens/routing/route_helpers.dart';
import 'package:Memento/screens/home_screen/home_screen.dart';
import 'package:Memento/screens/settings_screen/settings_screen.dart';
import 'package:Memento/screens/ios_widget_config/ios_widget_config_screen.dart';

/// 核心屏幕路由注册表
class CoreRoutes implements RouteRegistry {
  @override
  String get name => 'CoreRoutes';

  @override
  List<RouteDefinition> get routes => [
        // 主屏幕
        RouteDefinition(
          path: '/',
          handler: (settings) => RouteHelpers.createRoute(const HomeScreen()),
          description: '主屏幕',
        ),
        RouteDefinition(
          path: 'home',
          handler: (settings) => RouteHelpers.createRoute(const HomeScreen()),
          description: '主屏幕（别名）',
        ),

        // 设置页面
        RouteDefinition(
          path: '/settings',
          handler: (settings) => RouteHelpers.createRoute(const SettingsScreen()),
          description: '设置界面',
        ),
        RouteDefinition(
          path: 'settings',
          handler: (settings) => RouteHelpers.createRoute(const SettingsScreen()),
          description: '设置界面（别名）',
        ),

        // iOS 小组件配置页面（通用，支持参数）
        RouteDefinition(
          path: '/ios_widget_config',
          handler: (settings) {
            final args = settings.arguments as Map<String, dynamic>?;
            final widgetKind = args?['widgetKind'] as String?;
            return RouteHelpers.createRoute(
              IOSWidgetConfigScreen(widgetKind: widgetKind),
            );
          },
          description: 'iOS 桌面小组件配置',
        ),

        // iOS 小组件配置页面 - Small 尺寸
        RouteDefinition(
          path: '/ios_widget_config_small',
          handler: (settings) => RouteHelpers.createRoute(
            const IOSWidgetConfigScreen(widgetKind: 'small'),
          ),
          description: 'iOS 小组件配置 - Small',
        ),

        // iOS 小组件配置页面 - Wide 尺寸
        RouteDefinition(
          path: '/ios_widget_config_wide',
          handler: (settings) => RouteHelpers.createRoute(
            const IOSWidgetConfigScreen(widgetKind: 'wide'),
          ),
          description: 'iOS 小组件配置 - Wide',
        ),

        // iOS 小组件配置页面 - Large 尺寸
        RouteDefinition(
          path: '/ios_widget_config_large',
          handler: (settings) => RouteHelpers.createRoute(
            const IOSWidgetConfigScreen(widgetKind: 'large'),
          ),
          description: 'iOS 小组件配置 - Large',
        ),
      ];
}
