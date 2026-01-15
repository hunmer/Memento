import 'package:flutter/material.dart';
import 'package:Memento/screens/routing/route_definition.dart';
import 'package:Memento/screens/routing/route_helpers.dart';
import 'package:Memento/plugins/activity/activity_plugin.dart';
import 'package:Memento/plugins/checkin/checkin_plugin.dart';
import 'package:Memento/plugins/tts/screens/tts_services_screen.dart';
import 'package:Memento/plugins/nodes/nodes_plugin.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';
import 'package:Memento/plugins/scripts_center/scripts_center_plugin.dart';
import 'package:Memento/plugins/timer/views/timer_main_view.dart';
import 'package:Memento/plugins/timer/views/timer_task_details_page.dart';
import 'package:Memento/plugins/contact/contact_plugin.dart';
import 'package:Memento/plugins/database/database_plugin.dart';
import 'package:Memento/plugins/day/day_plugin.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';
import 'package:Memento/screens/home_screen/widgets/common_widget_selector_page.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/selector_widget_types.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 常见插件路由注册表
/// 包含：Activity, Checkin, TTS, Nodes, OpenAI, ScriptsCenter, Timer
class PluginCommonRoutes implements RouteRegistry {
  @override
  String get name => 'PluginCommonRoutes';

  @override
  List<RouteDefinition> get routes => [
        // Activity 插件
        RouteDefinition(
          path: '/activity',
          handler: (settings) => RouteHelpers.createRoute(const ActivityMainView()),
          description: '活动记录主页面',
        ),
        RouteDefinition(
          path: 'activity',
          handler: (settings) => RouteHelpers.createRoute(const ActivityMainView()),
          description: '活动记录主页面（别名）',
        ),

        // Checkin 插件
        RouteDefinition(
          path: '/checkin',
          handler: (settings) => RouteHelpers.createRoute(const CheckinMainView()),
          description: '签到主页面',
        ),
        RouteDefinition(
          path: 'checkin',
          handler: (settings) => RouteHelpers.createRoute(const CheckinMainView()),
          description: '签到主页面（别名）',
        ),

        // TTS 插件
        RouteDefinition(
          path: '/tts',
          handler: (settings) => RouteHelpers.createRoute(const TTSServicesScreen()),
          description: '文本转语音服务页面',
        ),
        RouteDefinition(
          path: 'tts',
          handler: (settings) => RouteHelpers.createRoute(const TTSServicesScreen()),
          description: '文本转语音服务页面（别名）',
        ),

        // Nodes 插件
        RouteDefinition(
          path: '/nodes',
          handler: (settings) => RouteHelpers.createRoute(const NodesMainView()),
          description: '笔记本主页面',
        ),
        RouteDefinition(
          path: 'nodes',
          handler: (settings) => RouteHelpers.createRoute(const NodesMainView()),
          description: '笔记本主页面（别名）',
        ),

        // OpenAI 插件
        RouteDefinition(
          path: '/openai',
          handler: (settings) => RouteHelpers.createRoute(const OpenAIMainView()),
          description: 'AI 助手主页面',
        ),
        RouteDefinition(
          path: 'openai',
          handler: (settings) => RouteHelpers.createRoute(const OpenAIMainView()),
          description: 'AI 助手主页面（别名）',
        ),

        // ScriptsCenter 插件
        RouteDefinition(
          path: '/scripts_center',
          handler: (settings) => RouteHelpers.createRoute(const ScriptsCenterMainView()),
          description: '脚本中心主页面',
        ),
        RouteDefinition(
          path: 'scripts_center',
          handler: (settings) => RouteHelpers.createRoute(const ScriptsCenterMainView()),
          description: '脚本中心主页面（别名）',
        ),

        // Timer 插件
        RouteDefinition(
          path: '/timer',
          handler: (settings) => RouteHelpers.createRoute(const TimerMainView()),
          description: '计时器主页面',
        ),
        RouteDefinition(
          path: 'timer',
          handler: (settings) => RouteHelpers.createRoute(const TimerMainView()),
          description: '计时器主页面（别名）',
        ),

        // Timer 详情页面
        RouteDefinition(
          path: '/timer_details',
          handler: (settings) {
            final arguments = settings.arguments as Map<String, dynamic>?;
            final taskId = arguments?['taskId'] as String?;
            if (taskId != null) {
              return RouteHelpers.createRoute(_TimerDetailsRoute(taskId: taskId));
            }
            return RouteHelpers.createRoute(const TimerMainView());
          },
          description: '计时器详情页面',
        ),

        // Contact 插件
        RouteDefinition(
          path: '/contact',
          handler: (settings) => RouteHelpers.createRoute(const ContactMainView()),
          description: '联系人主页面',
        ),
        RouteDefinition(
          path: 'contact',
          handler: (settings) => RouteHelpers.createRoute(const ContactMainView()),
          description: '联系人主页面（别名）',
        ),

        // Database 插件
        RouteDefinition(
          path: '/database',
          handler: (settings) => RouteHelpers.createRoute(const DatabaseMainView()),
          description: '自定义数据库主页面',
        ),
        RouteDefinition(
          path: 'database',
          handler: (settings) => RouteHelpers.createRoute(const DatabaseMainView()),
          description: '自定义数据库主页面（别名）',
        ),

        // Day 插件
        RouteDefinition(
          path: '/day',
          handler: (settings) => RouteHelpers.createRoute(const DayMainView()),
          description: '纪念日主页面',
        ),
        RouteDefinition(
          path: 'day',
          handler: (settings) => RouteHelpers.createRoute(const DayMainView()),
          description: '纪念日主页面（别名）',
        ),

        // Goods 插件
        RouteDefinition(
          path: '/goods',
          handler: (settings) => RouteHelpers.createRoute(const GoodsMainView()),
          description: '物品管理主页面',
        ),
        RouteDefinition(
          path: 'goods',
          handler: (settings) => RouteHelpers.createRoute(const GoodsMainView()),
          description: '物品管理主页面（别名）',
        ),

        // 公共小组件选择器页面
        RouteDefinition(
          path: '/common_widget_selector',
          handler: (settings) {
            final arguments = settings.arguments as Map<String, dynamic>?;
            final pluginWidget = arguments?['pluginWidget'] as HomeWidget;
            final folderId = arguments?['folderId'] as String?;
            final replaceWidgetItemId = arguments?['replaceWidgetItemId'] as String?;
            final initialCommonWidgetId = arguments?['initialCommonWidgetId'] as String?;
            final initialSelectorConfig = arguments?['initialSelectorConfig'] as SelectorWidgetConfig?;
            final originalSize = arguments?['originalSize'] as HomeWidgetSize?;
            final originalConfig = arguments?['originalConfig'] as Map<String, dynamic>?;
            if (pluginWidget != null) {
              return RouteHelpers.createRoute(CommonWidgetSelectorPage(
                pluginWidget: pluginWidget,
                folderId: folderId,
                replaceWidgetItemId: replaceWidgetItemId,
                initialCommonWidgetId: initialCommonWidgetId,
                initialSelectorConfig: initialSelectorConfig,
                originalSize: originalSize,
                originalConfig: originalConfig,
              ));
            }
            return RouteHelpers.createRoute(const SizedBox.shrink());
          },
          description: '公共小组件选择页面',
        ),
        RouteDefinition(
          path: 'common_widget_selector',
          handler: (settings) {
            final arguments = settings.arguments as Map<String, dynamic>?;
            final pluginWidget = arguments?['pluginWidget'] as HomeWidget;
            final folderId = arguments?['folderId'] as String?;
            final replaceWidgetItemId = arguments?['replaceWidgetItemId'] as String?;
            final initialCommonWidgetId = arguments?['initialCommonWidgetId'] as String?;
            final initialSelectorConfig = arguments?['initialSelectorConfig'] as SelectorWidgetConfig?;
            final originalSize = arguments?['originalSize'] as HomeWidgetSize?;
            final originalConfig = arguments?['originalConfig'] as Map<String, dynamic>?;
            if (pluginWidget != null) {
              return RouteHelpers.createRoute(CommonWidgetSelectorPage(
                pluginWidget: pluginWidget,
                folderId: folderId,
                replaceWidgetItemId: replaceWidgetItemId,
                initialCommonWidgetId: initialCommonWidgetId,
                initialSelectorConfig: initialSelectorConfig,
                originalSize: originalSize,
                originalConfig: originalConfig,
              ));
            }
            return RouteHelpers.createRoute(const SizedBox.shrink());
          },
          description: '公共小组件选择页面（别名）',
        ),
      ];
}

/// 计时器详情页面路由
class _TimerDetailsRoute extends StatelessWidget {
  final String taskId;

  const _TimerDetailsRoute({required this.taskId});

  @override
  Widget build(BuildContext context) {
    return TimerTaskDetailsPage(taskId: taskId);
  }
}
