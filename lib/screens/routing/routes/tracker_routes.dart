import 'package:flutter/foundation.dart';
import 'package:Memento/screens/routing/route_definition.dart';
import 'package:Memento/screens/routing/route_helpers.dart';
import 'package:Memento/plugins/tracker/tracker_plugin.dart';
import 'package:Memento/plugins/tracker/screens/goal_detail_screen.dart';
import 'package:Memento/plugins/tracker/screens/tracker_goal_selector_screen.dart';
import 'package:Memento/plugins/tracker/screens/tracker_goal_progress_selector_screen.dart';

/// Tracker 插件路由注册表
class TrackerRoutes implements RouteRegistry {
  @override
  String get name => 'TrackerRoutes';

  @override
  List<RouteDefinition> get routes => [
        // Tracker 主页面
        RouteDefinition(
          path: '/tracker',
          handler: (settings) {
            String? goalId;
            if (settings.arguments is Map<String, dynamic>) {
              goalId = (settings.arguments as Map<String, dynamic>)['goalId'] as String?;
            }
            debugPrint('[Route] /tracker: goalId=$goalId');

            if (goalId != null) {
              return RouteHelpers.createRoute(
                GoalDetailScreen(goalId: goalId),
                settings: settings,
              );
            }
            return RouteHelpers.createRoute(const TrackerMainView());
          },
          description: '目标追踪主页面',
        ),
        RouteDefinition(
          path: 'tracker',
          handler: (settings) {
            String? goalId;
            if (settings.arguments is Map<String, dynamic>) {
              goalId = (settings.arguments as Map<String, dynamic>)['goalId'] as String?;
            }
            debugPrint('[Route] /tracker: goalId=$goalId');

            if (goalId != null) {
              return RouteHelpers.createRoute(
                GoalDetailScreen(goalId: goalId),
                settings: settings,
              );
            }
            return RouteHelpers.createRoute(const TrackerMainView());
          },
          description: '目标追踪主页面（别名）',
        ),

        // 目标追踪进度增减小组件配置界面
        RouteDefinition(
          path: '/tracker_goal_selector',
          handler: (settings) {
            int? trackerWidgetId;

            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              final widgetIdValue = args['widgetId'];
              if (widgetIdValue is int) {
                trackerWidgetId = widgetIdValue;
              } else if (widgetIdValue is String) {
                trackerWidgetId = int.tryParse(widgetIdValue);
              }
            } else if (settings.arguments is int) {
              trackerWidgetId = settings.arguments as int;
            }

            return RouteHelpers.createRoute(
              TrackerGoalSelectorScreen(widgetId: trackerWidgetId),
            );
          },
          description: '目标追踪进度增减小组件配置界面',
        ),
        RouteDefinition(
          path: 'tracker_goal_selector',
          handler: (settings) {
            int? trackerWidgetId;

            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              final widgetIdValue = args['widgetId'];
              if (widgetIdValue is int) {
                trackerWidgetId = widgetIdValue;
              } else if (widgetIdValue is String) {
                trackerWidgetId = int.tryParse(widgetIdValue);
              }
            } else if (settings.arguments is int) {
              trackerWidgetId = settings.arguments as int;
            }

            return RouteHelpers.createRoute(
              TrackerGoalSelectorScreen(widgetId: trackerWidgetId),
            );
          },
          description: '目标追踪进度增减小组件配置界面（别名）',
        ),

        // 目标追踪进度条小组件配置界面
        RouteDefinition(
          path: '/tracker_goal_progress_selector',
          handler: (settings) {
            int? trackerProgressWidgetId;

            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              final widgetIdValue = args['widgetId'];
              if (widgetIdValue is int) {
                trackerProgressWidgetId = widgetIdValue;
              } else if (widgetIdValue is String) {
                trackerProgressWidgetId = int.tryParse(widgetIdValue);
              }
            } else if (settings.arguments is int) {
              trackerProgressWidgetId = settings.arguments as int;
            }

            return RouteHelpers.createRoute(
              TrackerGoalProgressSelectorScreen(widgetId: trackerProgressWidgetId),
            );
          },
          description: '目标追踪进度条小组件配置界面',
        ),
        RouteDefinition(
          path: 'tracker_goal_progress_selector',
          handler: (settings) {
            int? trackerProgressWidgetId;

            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              final widgetIdValue = args['widgetId'];
              if (widgetIdValue is int) {
                trackerProgressWidgetId = widgetIdValue;
              } else if (widgetIdValue is String) {
                trackerProgressWidgetId = int.tryParse(widgetIdValue);
              }
            } else if (settings.arguments is int) {
              trackerProgressWidgetId = settings.arguments as int;
            }

            return RouteHelpers.createRoute(
              TrackerGoalProgressSelectorScreen(widgetId: trackerProgressWidgetId),
            );
          },
          description: '目标追踪进度条小组件配置界面（别名）',
        ),
      ];
}
