import 'package:flutter/foundation.dart';
import 'package:Memento/screens/routing/route_definition.dart';
import 'package:Memento/screens/routing/route_helpers.dart';
import 'package:Memento/screens/js_console/js_console_screen.dart';
import 'package:Memento/screens/json_dynamic_test/json_dynamic_test_screen.dart';
import 'package:Memento/screens/notification_test/notification_test_page.dart';
import 'package:Memento/screens/floating_widget_screen/floating_widget_screen.dart';
import 'package:Memento/screens/data_selector_test/data_selector_test_screen.dart';
import 'package:Memento/screens/toast_test/toast_test_screen.dart';
import 'package:Memento/screens/test_screens/swipe_action_test_screen.dart';
import 'package:Memento/screens/settings_screen/screens/live_activities_test_screen.dart';
import 'package:Memento/screens/form_fields_test/form_fields_test_screen.dart';
import 'package:Memento/screens/log_screen/log_screen.dart';

/// 测试页面路由注册表
class TestRoutes implements RouteRegistry {
  @override
  String get name => 'TestRoutes';

  @override
  List<RouteDefinition> get routes => [
        // JS 控制台
        RouteDefinition(
          path: '/js_console',
          handler: (settings) => RouteHelpers.createRoute(const JSConsoleScreen()),
          description: 'JavaScript 控制台',
        ),
        RouteDefinition(
          path: 'js_console',
          handler: (settings) => RouteHelpers.createRoute(const JSConsoleScreen()),
          description: 'JavaScript 控制台（别名）',
        ),

        // JSON 动态测试
        RouteDefinition(
          path: '/json_dynamic_test',
          handler: (settings) => RouteHelpers.createRoute(const JsonDynamicTestScreen()),
          description: 'JSON 动态测试',
        ),
        RouteDefinition(
          path: 'json_dynamic_test',
          handler: (settings) => RouteHelpers.createRoute(const JsonDynamicTestScreen()),
          description: 'JSON 动态测试（别名）',
        ),

        // 通知测试
        RouteDefinition(
          path: '/notification_test',
          handler: (settings) => RouteHelpers.createRoute(const NotificationTestPage()),
          description: '通知测试',
        ),
        RouteDefinition(
          path: 'notification_test',
          handler: (settings) => RouteHelpers.createRoute(const NotificationTestPage()),
          description: '通知测试（别名）',
        ),

        // 悬浮小组件测试
        RouteDefinition(
          path: '/floating_ball',
          handler: (settings) => RouteHelpers.createRoute(const FloatingBallScreen()),
          description: '悬浮小组件设置',
        ),
        RouteDefinition(
          path: 'floating_ball',
          handler: (settings) => RouteHelpers.createRoute(const FloatingBallScreen()),
          description: '悬浮小组件设置（别名）',
        ),

        // 数据选择器测试
        RouteDefinition(
          path: '/data_selector_test',
          handler: (settings) => RouteHelpers.createRoute(const DataSelectorTestScreen()),
          description: '数据选择器测试',
        ),
        RouteDefinition(
          path: 'data_selector_test',
          handler: (settings) => RouteHelpers.createRoute(const DataSelectorTestScreen()),
          description: '数据选择器测试（别名）',
        ),

        // Toast 测试
        RouteDefinition(
          path: '/toast_test',
          handler: (settings) => RouteHelpers.createRoute(const ToastTestScreen()),
          description: 'Toast 测试',
        ),
        RouteDefinition(
          path: 'toast_test',
          handler: (settings) => RouteHelpers.createRoute(const ToastTestScreen()),
          description: 'Toast 测试（别名）',
        ),

        // 滑动操作测试
        RouteDefinition(
          path: '/swipe_action_test',
          handler: (settings) => RouteHelpers.createRoute(const SwipeActionTestScreen()),
          description: '滑动操作测试',
        ),
        RouteDefinition(
          path: 'swipe_action_test',
          handler: (settings) => RouteHelpers.createRoute(const SwipeActionTestScreen()),
          description: '滑动操作测试（别名）',
        ),

        // Live Activities 测试
        RouteDefinition(
          path: '/live_activities_test',
          handler: (settings) => RouteHelpers.createRoute(const LiveActivitiesTestScreen()),
          description: 'Live Activities 测试',
        ),
        RouteDefinition(
          path: 'live_activities_test',
          handler: (settings) => RouteHelpers.createRoute(const LiveActivitiesTestScreen()),
          description: 'Live Activities 测试（别名）',
        ),

        // 表单字段测试
        RouteDefinition(
          path: '/form_fields_test',
          handler: (settings) => RouteHelpers.createRoute(const FormFieldsTestScreen()),
          description: '表单字段测试',
        ),
        RouteDefinition(
          path: 'form_fields_test',
          handler: (settings) => RouteHelpers.createRoute(const FormFieldsTestScreen()),
          description: '表单字段测试（别名）',
        ),

        // 日志屏幕
        RouteDefinition(
          path: '/log',
          handler: (settings) => RouteHelpers.createRoute(const LogScreen()),
          description: '日志屏幕',
        ),
        RouteDefinition(
          path: 'log',
          handler: (settings) => RouteHelpers.createRoute(const LogScreen()),
          description: '日志屏幕（别名）',
        ),
      ];
}
