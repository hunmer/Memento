import 'package:Memento/screens/routing/route_definition.dart';
import 'package:Memento/screens/routing/route_helpers.dart';
import 'package:Memento/plugins/calendar_album/calendar_album_plugin.dart';
import 'package:Memento/plugins/calendar_album/screens/calendar_album_weekly_selector_screen.dart';

/// Calendar Album 插件路由注册表
class CalendarAlbumRoutes implements RouteRegistry {
  @override
  String get name => 'CalendarAlbumRoutes';

  @override
  List<RouteDefinition> get routes => [
        // Calendar Album 主页面
        RouteDefinition(
          path: '/calendar_album',
          handler: (settings) => RouteHelpers.createRoute(const CalendarAlbumMainView()),
          description: '日记相册主页面',
        ),
        RouteDefinition(
          path: 'calendar_album',
          handler: (settings) => RouteHelpers.createRoute(const CalendarAlbumMainView()),
          description: '日记相册主页面（别名）',
        ),

        // 每周相册小组件配置界面
        RouteDefinition(
          path: '/calendar_album_weekly_selector',
          handler: (settings) {
            int? weeklyWidgetId;

            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              final widgetIdValue = args['widgetId'];
              if (widgetIdValue is int) {
                weeklyWidgetId = widgetIdValue;
              } else if (widgetIdValue is String) {
                weeklyWidgetId = int.tryParse(widgetIdValue);
              }
            } else if (settings.arguments is int) {
              weeklyWidgetId = settings.arguments as int;
            }

            return RouteHelpers.createRoute(
              CalendarAlbumWeeklySelectorScreen(widgetId: weeklyWidgetId),
            );
          },
          description: '每周相册小组件配置界面',
        ),
        RouteDefinition(
          path: 'calendar_album_weekly_selector',
          handler: (settings) {
            int? weeklyWidgetId;

            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              final widgetIdValue = args['widgetId'];
              if (widgetIdValue is int) {
                weeklyWidgetId = widgetIdValue;
              } else if (widgetIdValue is String) {
                weeklyWidgetId = int.tryParse(widgetIdValue);
              }
            } else if (settings.arguments is int) {
              weeklyWidgetId = settings.arguments as int;
            }

            return RouteHelpers.createRoute(
              CalendarAlbumWeeklySelectorScreen(widgetId: weeklyWidgetId),
            );
          },
          description: '每周相册小组件配置界面（别名）',
        ),
      ];
}
