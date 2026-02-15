import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/routing/route_definition.dart';
import 'package:Memento/screens/routing/route_helpers.dart';
import 'package:Memento/plugins/activity/activity_plugin.dart';
import 'package:Memento/plugins/activity/screens/activity_weekly_config_screen.dart';
import 'package:Memento/plugins/activity/screens/activity_daily_config_screen.dart';
import 'package:Memento/plugins/activity/screens/tag_statistics_screen.dart';

/// Activity 插件路由注册表
class ActivityRoutes implements RouteRegistry {
  @override
  String get name => 'ActivityRoutes';

  @override
  List<RouteDefinition> get routes => [
    // Activity 主页面（已在 plugin_common_routes.dart 中定义，此处只定义子路由）

    // 活动编辑界面（从活动通知打开）
    RouteDefinition(
      path: '/activity_edit',
      handler: (settings) {
        return RouteHelpers.createRoute(ActivityEditScreen());
      },
      description: '活动编辑界面（从活动通知打开）',
    ),
    RouteDefinition(
      path: 'activity_edit',
      handler: (settings) {
        return RouteHelpers.createRoute(ActivityEditScreen());
      },
      description: '活动编辑界面（别名）',
    ),

    // 活动周视图小组件配置界面
    RouteDefinition(
      path: '/activity_weekly_config',
      handler: (settings) {
        int? activityWeeklyWidgetId;

        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          final widgetIdValue = args['widgetId'];
          if (widgetIdValue is int) {
            activityWeeklyWidgetId = widgetIdValue;
          } else if (widgetIdValue is String) {
            activityWeeklyWidgetId = int.tryParse(widgetIdValue);
          }
        } else if (settings.arguments is int) {
          activityWeeklyWidgetId = settings.arguments as int;
        }

        if (activityWeeklyWidgetId == null) {
          return RouteHelpers.createErrorRoute('error', 'errorWidgetIdMissing');
        }

        return RouteHelpers.createRoute(
          ActivityWeeklyConfigScreen(widgetId: activityWeeklyWidgetId),
        );
      },
      description: '活动周视图小组件配置界面',
    ),
    RouteDefinition(
      path: 'activity_weekly_config',
      handler: (settings) {
        int? activityWeeklyWidgetId;

        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          final widgetIdValue = args['widgetId'];
          if (widgetIdValue is int) {
            activityWeeklyWidgetId = widgetIdValue;
          } else if (widgetIdValue is String) {
            activityWeeklyWidgetId = int.tryParse(widgetIdValue);
          }
        } else if (settings.arguments is int) {
          activityWeeklyWidgetId = settings.arguments as int;
        }

        if (activityWeeklyWidgetId == null) {
          return RouteHelpers.createErrorRoute('error', 'errorWidgetIdMissing');
        }

        return RouteHelpers.createRoute(
          ActivityWeeklyConfigScreen(widgetId: activityWeeklyWidgetId),
        );
      },
      description: '活动周视图小组件配置界面（别名）',
    ),

    // 活动日视图小组件配置界面
    RouteDefinition(
      path: '/activity_daily_config',
      handler: (settings) {
        int? activityDailyWidgetId;

        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          final widgetIdValue = args['widgetId'];
          if (widgetIdValue is int) {
            activityDailyWidgetId = widgetIdValue;
          } else if (widgetIdValue is String) {
            activityDailyWidgetId = int.tryParse(widgetIdValue);
          }
        } else if (settings.arguments is int) {
          activityDailyWidgetId = settings.arguments as int;
        }

        if (activityDailyWidgetId == null) {
          return RouteHelpers.createErrorRoute('error', 'errorWidgetIdMissing');
        }

        return RouteHelpers.createRoute(
          ActivityDailyConfigScreen(widgetId: activityDailyWidgetId),
        );
      },
      description: '活动日视图小组件配置界面',
    ),
    RouteDefinition(
      path: 'activity_daily_config',
      handler: (settings) {
        int? activityDailyWidgetId;

        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          final widgetIdValue = args['widgetId'];
          if (widgetIdValue is int) {
            activityDailyWidgetId = widgetIdValue;
          } else if (widgetIdValue is String) {
            activityDailyWidgetId = int.tryParse(widgetIdValue);
          }
        } else if (settings.arguments is int) {
          activityDailyWidgetId = settings.arguments as int;
        }

        if (activityDailyWidgetId == null) {
          return RouteHelpers.createErrorRoute('error', 'errorWidgetIdMissing');
        }

        return RouteHelpers.createRoute(
          ActivityDailyConfigScreen(widgetId: activityDailyWidgetId),
        );
      },
      description: '活动日视图小组件配置界面（别名）',
    ),

    // 标签统计页面（从桌面小组件打开）
    RouteDefinition(
      path: '/tag_statistics',
      handler: (settings) {
        String? tagName;

        if (settings.arguments is Map<String, dynamic>) {
          tagName =
              (settings.arguments as Map<String, dynamic>)['tag'] as String?;
        } else if (settings.arguments is String) {
          tagName = settings.arguments as String;
        }

        debugPrint('打开标签统计页面: tag=$tagName');

        if (tagName == null || tagName.isEmpty) {
          return RouteHelpers.createRoute(const ActivityMainView());
        }

        final activityPlugin =
            PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
        if (activityPlugin == null) {
          debugPrint('ActivityPlugin 未初始化，回退到主视图');
          return RouteHelpers.createRoute(const ActivityMainView());
        }

        return RouteHelpers.createRoute(
          TagStatisticsScreen(
            tagName: tagName,
            activityService: activityPlugin.activityService,
          ),
        );
      },
      description: '标签统计页面',
    ),
    RouteDefinition(
      path: 'tag_statistics',
      handler: (settings) {
        String? tagName;

        if (settings.arguments is Map<String, dynamic>) {
          tagName =
              (settings.arguments as Map<String, dynamic>)['tag'] as String?;
        } else if (settings.arguments is String) {
          tagName = settings.arguments as String;
        }

        debugPrint('打开标签统计页面: tag=$tagName');

        if (tagName == null || tagName.isEmpty) {
          return RouteHelpers.createRoute(const ActivityMainView());
        }

        final activityPlugin =
            PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
        if (activityPlugin == null) {
          debugPrint('ActivityPlugin 未初始化，回退到主视图');
          return RouteHelpers.createRoute(const ActivityMainView());
        }

        return RouteHelpers.createRoute(
          TagStatisticsScreen(
            tagName: tagName,
            activityService: activityPlugin.activityService,
          ),
        );
      },
      description: '标签统计页面（别名）',
    ),
  ];
}
