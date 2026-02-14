import 'package:flutter/material.dart';
import 'package:Memento/core/routing/plugin_route_handler.dart';
import 'package:Memento/screens/routing/route_definition.dart';
import 'package:Memento/screens/routing/route_manager.dart';
import 'package:Memento/screens/routing/route_helpers.dart';

// 导入所有路由注册表
import 'package:Memento/screens/routing/routes/core_routes.dart';
import 'package:Memento/screens/routing/routes/test_routes.dart';
import 'package:Memento/screens/routing/routes/widget_gallery_routes.dart';
import 'package:Memento/screens/routing/routes/chat_routes.dart';
import 'package:Memento/screens/routing/routes/diary_routes.dart';
import 'package:Memento/screens/routing/routes/plugin_common_routes.dart';
import 'package:Memento/screens/routing/routes/agent_chat_routes.dart';
import 'package:Memento/screens/routing/routes/bill_routes.dart';
import 'package:Memento/screens/routing/routes/calendar_routes.dart';
import 'package:Memento/screens/routing/routes/notes_routes.dart';
import 'package:Memento/screens/routing/routes/store_routes.dart';
import 'package:Memento/screens/routing/routes/habits_routes.dart';
import 'package:Memento/screens/routing/routes/tracker_routes.dart';
import 'package:Memento/screens/routing/routes/activity_routes.dart';
import 'package:Memento/screens/routing/routes/calendar_album_routes.dart';
import 'package:Memento/screens/routing/routes/contact_routes.dart';
import 'package:Memento/screens/routing/routes/todo_routes.dart';
import 'package:Memento/screens/routing/routes/webview_routes.dart';

// 插件路由处理器导入
import 'package:Memento/plugins/checkin/checkin_route_handler.dart';
import 'package:Memento/plugins/todo/todo_route_handler.dart';
import 'package:Memento/plugins/goods/goods_route_handler.dart';
import 'package:Memento/plugins/habits/habits_route_handler.dart';
import 'package:Memento/plugins/tracker/tracker_route_handler.dart';

// 导入页面组件（用于 routes Map）
import 'package:Memento/screens/home_screen/home_screen.dart';
import 'package:Memento/screens/settings_screen/settings_screen.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:Memento/plugins/diary/diary_plugin.dart';
import 'package:Memento/plugins/activity/activity_plugin.dart';
import 'package:Memento/plugins/checkin/checkin_plugin.dart';
import 'package:Memento/plugins/agent_chat/agent_chat_plugin.dart';
import 'package:Memento/plugins/bill/bill_plugin.dart';
import 'package:Memento/plugins/calendar/calendar_plugin.dart';
import 'package:Memento/plugins/contact/contact_plugin.dart';
import 'package:Memento/plugins/database/database_plugin.dart';
import 'package:Memento/plugins/tts/screens/tts_services_screen.dart';
import 'package:Memento/plugins/day/day_plugin.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';
import 'package:Memento/plugins/habits/habits_plugin.dart';
import 'package:Memento/plugins/store/widgets/store_view/store_main.dart';
import 'package:Memento/plugins/calendar_album/calendar_album_plugin.dart';
import 'package:Memento/plugins/nodes/nodes_plugin.dart';
import 'package:Memento/plugins/notes/screens/notes_screen.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';
import 'package:Memento/plugins/scripts_center/scripts_center_plugin.dart';
import 'package:Memento/plugins/timer/views/timer_main_view.dart';
import 'package:Memento/plugins/todo/views/todo_bottombar_view.dart';
import 'package:Memento/plugins/tracker/tracker_plugin.dart';
import 'package:Memento/screens/floating_widget_screen/floating_widget_screen.dart';
import 'package:Memento/plugins/activity/screens/activity_daily_config_screen.dart';
import 'package:Memento/screens/js_console/js_console_screen.dart';
import 'package:Memento/screens/json_dynamic_test/json_dynamic_test_screen.dart';
import 'package:Memento/screens/notification_test/notification_test_page.dart';
import 'package:Memento/screens/data_selector_test/data_selector_test_screen.dart';
import 'package:Memento/screens/settings_screen/screens/live_activities_test_screen.dart';
import 'package:Memento/screens/settings_screen/screens/background_announcement_test_screen.dart';

class AppRoutes extends NavigatorObserver {
  // 单例路由管理器
  static final RouteManager _routeManager = RouteManager();

  // 插件路由处理器列表（保留兼容性）
  static final List<PluginRouteHandler> _pluginRouteHandlers = [
    CheckinRouteHandler(),
    TodoRouteHandler(),
    GoodsRouteHandler(),
    HabitsRouteHandler(),
    TrackerRouteHandler(),
  ];

  // 初始化所有路由
  static void _initRoutes() {
    if (_routeManager.registeredPaths.isEmpty) {
      // 注册所有路由表
      final registries = <RouteRegistry>[
        // 核心路由
        CoreRoutes(),
        // 测试路由
        TestRoutes(),
        // 组件展示路由
        WidgetGalleryRoutes(),
        // 插件路由
        ChatRoutes(),
        DiaryRoutes(),
        PluginCommonRoutes(),
        AgentChatRoutes(),
        BillRoutes(),
        CalendarRoutes(),
        NotesRoutes(),
        StoreRoutes(),
        HabitsRoutes(),
        TrackerRoutes(),
        ActivityRoutes(),
        CalendarAlbumRoutes(),
        ContactRoutes(),
        TodoRoutes(),
        WebViewRoutes(),
      ];

      // 注册所有路由定义
      for (final registry in registries) {
        _routeManager.registerRoutes(registry.routes);
      }
    }
  }

  // 判断是否可以返回上一级路由
  static bool canPop(BuildContext context) {
    final navigator = Navigator.of(context);
    return ModalRoute.of(context)?.settings.name != home && navigator.canPop();
  }

  // ==================== 路由路径常量 ====================
  static const String home = '/';
  static const String chat = '/chat';
  static const String diary = '/diary';
  static const String diaryDetail = '/diary_detail';
  static const String activity = '/activity';
  static const String checkin = '/checkin';
  static const String settings = '/settings';
  static const String jsConsole = '/js_console';
  static const String jsonDynamicTest = '/json_dynamic_test';
  static const String notificationTest = '/notification_test';
  static const String backgroundAnnouncementTest = '/background_announcement_test';
  static const String superCupertinoTest = '/super_cupertino_test';
  static const String overlayTest = '/overlay_test';
  static const String formFieldsTest = '/form_fields_test';
  static const String widgetsGallery = '/widgets_gallery';
  static const String log = '/log';

  // 插件路由路径
  static const String agentChat = '/agent_chat';
  static const String agentChatChat = '/agent_chat/chat';
  static const String bill = '/bill';
  static const String calendar = '/calendar';
  static const String calendarAlbum = '/calendar_album';
  static const String contact = '/contact';
  static const String contactDetail = '/contact/detail';
  static const String database = '/database';
  static const String day = '/day';
  static const String goods = '/goods';
  static const String habits = '/habits';
  static const String nodes = '/nodes';
  static const String tts = '/tts';
  static const String notes = '/notes';
  static const String notesCreate = '/notes/create';
  static const String openai = '/openai';
  static const String scriptsCenter = '/scripts_center';
  static const String store = '/store';
  static const String storePointsHistory = '/store/points_history';
  static const String storeProductItems = '/store/product_items';
  static const String storeUserItem = '/store/user_item';
  static const String timer = '/timer';
  static const String timerDetails = '/timer_details';
  static const String todo = '/todo';
  static const String tracker = '/tracker';
  static const String floatingBall = '/floating_ball';
  static const String widgetsConfig = '/widgets_config';

  // Agent Chat 子页面路由
  static const String toolTemplate = '/tool_template';
  static const String toolManagement = '/tool_management';

  // 打卡小组件配置路由
  static const String checkinItemSelector = '/checkin_item_selector';

  // 待办列表小组件配置路由
  static const String todoListSelector = '/todo_list_selector';

  // 待办任务详情路由（从小组件打开）
  static const String todoTaskDetail = '/todo_task_detail';

  // 待办添加任务路由（从小组件打开）
  static const String todoAdd = '/todo_add';

  // 日历月视图小组件配置路由
  static const String calendarMonthSelector = '/calendar_month_selector';

  // 日历事件详情路由
  static const String calendarMonthEvent = '/calendar_month/event';

  // 目标追踪进度增减小组件配置路由
  static const String trackerGoalSelector = '/tracker_goal_selector';

  // 目标追踪进度条小组件配置路由
  static const String trackerGoalProgressSelector = '/tracker_goal_progress_selector';

  // 习惯计时器小组件配置路由
  static const String habitTimerSelector = '/habit_timer_selector';

  // 快捷记账小组件配置路由
  static const String billShortcutsSelector = '/bill_shortcuts_selector';

  // 活动周视图小组件配置路由
  static const String activityWeeklyConfig = '/activity_weekly_config';

  // 活动日视图小组件配置路由
  static const String activityDailyConfig = '/activity_daily_config';

  // 习惯计时器对话框路由（从小组件打开）
  static const String habitTimerDialog = '/habit_timer_dialog';

  // 习惯周视图小组件配置路由
  static const String habitsWeeklyConfig = '/habits_weekly_config';

  // 习惯分组列表小组件配置路由
  static const String habitGroupListSelector = '/habit_group_list_selector';

  // 每周相册小组件配置路由
  static const String calendarAlbumWeeklySelector = '/calendar_album_weekly_selector';

  // 标签统计页面路由（从小组件打开）
  static const String tagStatistics = '/tag_statistics';

  // WebView 浏览器路由
  static const String webviewBrowser = '/webview/browser';

  // 公共小组件选择器路由
  static const String commonWidgetSelector = '/common_widget_selector';

  // ==================== 路由生成器 ====================
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // 确保路由已初始化
    _initRoutes();

    // 1. 尝试使用插件路由处理器处理路由（保留兼容性）
    for (final handler in _pluginRouteHandlers) {
      final route = handler.handleRoute(settings);
      if (route != null) {
        return route;
      }
    }

    // 2. 使用新的路由管理器处理路由
    final route = _routeManager.handleRoute(settings);
    if (route != null) {
      return route;
    }

    // 3. 未找到路由，返回加载页面
    debugPrint('AppRoutes: 未找到路由: ${settings.name}');
    return RouteHelpers.createRoute(
      Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }

  // ==================== 简化路由 Map（用于 GetX）====================
  static Map<String, WidgetBuilder> get routes => {
    home: (context) => const HomeScreen(),
    chat: (context) => const ChatMainView(),
    diary: (context) => const DiaryMainView(),
    activity: (context) => const ActivityMainView(),
    checkin: (context) => const CheckinMainView(),
    settings: (context) => const SettingsScreen(),
    agentChat: (context) => const AgentChatMainView(),
    bill: (context) => const BillMainView(),
    calendar: (context) => const CalendarMainView(),
    contact: (context) => const ContactMainView(),
    database: (context) => const DatabaseMainView(),
    tts: (context) => const TTSServicesScreen(),
    day: (context) => const DayMainView(),
    goods: (context) => const GoodsMainView(),
    habits: (context) => const HabitsMainView(),
    store: (context) => const StoreMainView(),
    calendarAlbum: (context) => const CalendarAlbumMainView(),
    nodes: (context) => const NodesMainView(),
    notes: (context) => const NotesMainView(),
    openai: (context) => const OpenAIMainView(),
    scriptsCenter: (context) => const ScriptsCenterMainView(),
    timer: (context) => const TimerMainView(),
    todo: (context) => const TodoBottomBarView(),
    tracker: (context) => const TrackerMainView(),
    floatingBall: (context) => const FloatingBallScreen(),
    activityDailyConfig: (context) => const ActivityDailyConfigScreen(widgetId: 0),
    jsConsole: (context) => const JSConsoleScreen(),
    jsonDynamicTest: (context) => const JsonDynamicTestScreen(),
    notificationTest: (context) => const NotificationTestPage(),
    backgroundAnnouncementTest: (context) => const BackgroundAnnouncementTestScreen(),
    'data_selector_test': (context) => const DataSelectorTestScreen(),
    'live_activities_test': (context) => const LiveActivitiesTestScreen(),
  };

  static String get initialRoute => home;
}
