import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:Memento/plugins/notes/screens/notes_screen.dart';
import 'package:Memento/plugins/store/widgets/store_view/store_main.dart';
import 'package:Memento/plugins/tts/screens/tts_services_screen.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/home_screen.dart';
import 'package:Memento/screens/settings_screen/settings_screen.dart';
import 'package:Memento/screens/js_console/js_console_screen.dart';
import 'package:Memento/screens/json_dynamic_test/json_dynamic_test_screen.dart';
import 'package:Memento/screens/notification_test/notification_test_page.dart';
import 'package:Memento/screens/super_cupertino_test_screen/super_cupertino_test_screen.dart';
import 'package:Memento/screens/floating_widget_screen/floating_widget_screen.dart';
import 'package:Memento/screens/widgets_config_screen/widgets_config_screen.dart';

// 插件路由导入
import 'package:Memento/plugins/activity/activity_plugin.dart';
import 'package:Memento/plugins/activity/screens/activity_weekly_config_screen.dart';
import 'package:Memento/plugins/agent_chat/agent_chat_plugin.dart';
import 'package:Memento/plugins/bill/bill_plugin.dart';
import 'package:Memento/plugins/bill/screens/bill_edit_screen.dart';
import 'package:Memento/plugins/bill/screens/bill_shortcuts_selector_screen.dart';
import 'package:Memento/plugins/calendar/calendar_plugin.dart';
import 'package:Memento/plugins/calendar/screens/calendar_month_selector_screen.dart';
import 'package:Memento/plugins/calendar_album/calendar_album_plugin.dart';
import 'package:Memento/plugins/checkin/checkin_plugin.dart';
import 'package:Memento/plugins/contact/contact_plugin.dart';
import 'package:Memento/plugins/database/database_plugin.dart';
import 'package:Memento/plugins/day/day_plugin.dart';
import 'package:Memento/plugins/diary/diary_plugin.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';
import 'package:Memento/plugins/habits/habits_plugin.dart';
import 'package:Memento/plugins/habits/screens/habit_timer_selector_screen.dart';
import 'package:Memento/plugins/habits/screens/habits_weekly_config_screen.dart';
import 'package:Memento/plugins/habits/widgets/timer_dialog.dart';
import 'package:Memento/plugins/habits/controllers/habit_controller.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/nodes/nodes_plugin.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';
import 'package:Memento/plugins/scripts_center/scripts_center_plugin.dart';
import 'package:Memento/plugins/timer/views/timer_main_view.dart';
import 'package:Memento/plugins/todo/views/todo_main_view.dart';
import 'package:Memento/plugins/tracker/tracker_plugin.dart';
import 'package:Memento/plugins/tracker/screens/tracker_goal_selector_screen.dart';

// 插件路由处理器导入
import 'package:Memento/core/routing/plugin_route_handler.dart';
import 'package:Memento/plugins/checkin/checkin_route_handler.dart';
import 'package:Memento/plugins/todo/todo_route_handler.dart';

class AppRoutes extends NavigatorObserver {
  // 插件路由处理器列表
  static final List<PluginRouteHandler> _pluginRouteHandlers = [
    CheckinRouteHandler(),
    TodoRouteHandler(),
  ];

  // 判断是否可以返回上一级路由
  static bool canPop(BuildContext context) {
    final navigator = Navigator.of(context);
    // 如果当前路由是根路由(/)或者没有上一级路由，则不能返回
    return ModalRoute.of(context)?.settings.name != home && navigator.canPop();
  }

  // 路由路径常量
  static const String home = '/';
  static const String chat = '/chat';
  static const String diary = '/diary';
  static const String activity = '/activity';
  static const String checkin = '/checkin';
  static const String settings = '/settings';
  static const String jsConsole = '/js_console';
  static const String jsonDynamicTest = '/json_dynamic_test';
  static const String notificationTest = '/notification_test';
  static const String superCupertinoTest = '/super_cupertino_test';
  static const String overlayTest = '/overlay_test';

  // 插件路由路径
  static const String agentChat = '/agent_chat';
  static const String bill = '/bill';
  static const String calendar = '/calendar';
  static const String calendarAlbum = '/calendar_album';
  static const String contact = '/contact';
  static const String database = '/database';
  static const String day = '/day';
  static const String goods = '/goods';
  static const String habits = '/habits';
  static const String nodes = '/nodes';
  static const String tts = '/tts';
  static const String notes = '/notes';
  static const String openai = '/openai';
  static const String scriptsCenter = '/scripts_center';
  static const String store = '/store';
  static const String timer = '/timer';
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

  // 目标追踪进度增减小组件配置路由
  static const String trackerGoalSelector = '/tracker_goal_selector';

  // 习惯计时器小组件配置路由
  static const String habitTimerSelector = '/habit_timer_selector';

  // 快捷记账小组件配置路由
  static const String billShortcutsSelector = '/bill_shortcuts_selector';

  // 活动周视图小组件配置路由
  static const String activityWeeklyConfig = '/activity_weekly_config';

  // 习惯计时器对话框路由（从小组件打开）
  static const String habitTimerDialog = '/habit_timer_dialog';

  // 自定义页面过渡动画 - 无动画
  static Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
      transitionDuration: Duration(milliseconds: 0),
      reverseTransitionDuration: Duration(milliseconds: 0),
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // 尝试使用插件路由处理器处理路由
    for (final handler in _pluginRouteHandlers) {
      final route = handler.handleRoute(settings);
      if (route != null) {
        return route;
      }
    }

    // 如果插件路由处理器无法处理，使用原有的路由逻辑
    final routeName = settings.name ?? '/';

    switch (routeName) {
      case '/':
        return _createRoute(const HomeScreen());
      case '/tts':
      case 'tts':
        return _createRoute(const TTSServicesScreen());
      case '/diary':
      case 'diary':
        return _createRoute(const DiaryMainView());
      case '/activity':
      case 'activity':
        return _createRoute(const ActivityMainView());
      case '/checkin':
      case 'checkin':
        return _createRoute(const CheckinMainView());
      case '/settings':
      case 'settings':
        return _createRoute(const SettingsScreen());
      case '/agent_chat':
      case 'agent_chat':
        // 支持通过 conversationId 参数直接打开指定对话
        String? conversationId;
        if (settings.arguments is Map<String, String>) {
          conversationId = (settings.arguments as Map<String, String>)['conversationId'];
        } else if (settings.arguments is String) {
          conversationId = settings.arguments as String;
        }
        return _createRoute(AgentChatMainView(conversationId: conversationId));
      case '/bill':
      case 'bill':
        // 检查是否来自快捷记账小组件（带有预填充参数）
        if (settings.arguments is Map<String, dynamic> ||
            settings.arguments is Map<String, String>) {
          final args = settings.arguments as Map<String, dynamic>;

          // 如果有category参数，说明是从快捷记账小组件打开的
          if (args.containsKey('category')) {
            // 获取 BillPlugin 实例
            final billPlugin =
                PluginManager.instance.getPlugin('bill') as BillPlugin?;

            if (billPlugin == null) {
              // 如果插件未初始化，回退到主视图
              debugPrint('BillPlugin 未初始化，回退到主视图');
              return _createRoute(const BillMainView());
            }

            // 解析参数
            final String? accountId = args['accountId'] as String?;
            final String? category = args['category'] as String?;
            final double? amount = args['amount'] != null
                ? double.tryParse(args['amount'].toString())
                : null;
            final bool? isExpense = args['isExpense'] != null
                ? (args['isExpense'].toString().toLowerCase() == 'true')
                : null;

            // 如果缺少必需的 accountId，回退到主视图
            if (accountId == null || accountId.isEmpty) {
              debugPrint('缺少 accountId 参数，回退到主视图');
              return _createRoute(const BillMainView());
            }

            // 打开账单编辑页面并传递预填充参数
            return _createRoute(BillEditScreen(
              billPlugin: billPlugin,
              accountId: accountId,
              initialCategory: category,
              initialAmount: amount,
              initialIsExpense: isExpense,
            ));
          }
        }

        // 默认打开账单主视图
        return _createRoute(const BillMainView());
      case '/calendar':
      case 'calendar':
        return _createRoute(const CalendarMainView());
      case '/calendar_album':
      case 'calendar_album':
        return _createRoute(const CalendarAlbumMainView());
      case '/contact':
      case 'contact':
        return _createRoute(const ContactMainView());
      case '/database':
      case 'database':
        return _createRoute(const DatabaseMainView());
      case '/day':
      case 'day':
        return _createRoute(const DayMainView());
      case '/goods':
      case 'goods':
        return _createRoute(const GoodsMainView());
      case '/habits':
      case 'habits':
        return _createRoute(const HabitsMainView());
      case '/nodes':
      case 'nodes':
        return _createRoute(const NodesMainView());
      case '/notes':
      case 'notes':
        return _createRoute(const NotesMainView());
      case '/openai':
      case 'openai':
        return _createRoute(const OpenAIMainView());
      case '/scripts_center':
      case 'scripts_center':
        return _createRoute(const ScriptsCenterMainView());
      case '/store':
      case 'store':
        return _createRoute(const StoreMainView());
      case '/timer':
      case 'timer':
        return _createRoute(const TimerMainView());
      case '/todo':
      case 'todo':
        return _createRoute(const TodoMainView());
      case '/tracker':
      case 'tracker':
        return _createRoute(const TrackerMainView());
      case '/floating_ball':
      case 'floating_ball':
        return _createRoute(const FloatingBallScreen());
      case '/widgets_config':
      case 'widgets_config':
        return _createRoute(const WidgetsConfigScreen());
      case '/js_console':
      case 'js_console':
        return _createRoute(const JSConsoleScreen());
      case '/json_dynamic_test':
      case 'json_dynamic_test':
        return _createRoute(const JsonDynamicTestScreen());
      case '/notification_test':
      case 'notification_test':
        return _createRoute(const NotificationTestPage());
      case '/super_cupertino_test':
      case 'super_cupertino_test':
        return _createRoute(const SuperCupertinoTestScreen());
      case '/chat':
      case 'chat':
        // 支持通过 channelId 参数直接打开指定频道
        String? channelId;
        if (settings.arguments is Map<String, String>) {
          channelId = (settings.arguments as Map<String, String>)['channelId'];
        } else if (settings.arguments is String) {
          channelId = settings.arguments as String;
        }
        return _createRoute(ChatMainView(channelId: channelId));
      case '/calendar_month_selector':
      case 'calendar_month_selector':
        // 日历月视图小组件配置界面
        int? widgetId;

        // 从 arguments 中解析 widgetId
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          // widgetId 可能是字符串或整数
          final widgetIdValue = args['widgetId'];
          if (widgetIdValue is int) {
            widgetId = widgetIdValue;
          } else if (widgetIdValue is String) {
            widgetId = int.tryParse(widgetIdValue);
          }
        } else if (settings.arguments is int) {
          widgetId = settings.arguments as int;
        }

        return _createRoute(CalendarMonthSelectorScreen(widgetId: widgetId));
      case '/tracker_goal_selector':
      case 'tracker_goal_selector':
        // 目标追踪进度增减小组件配置界面
        int? trackerWidgetId;

        // 从 arguments 中解析 widgetId
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          // widgetId 可能是字符串或整数
          final widgetIdValue = args['widgetId'];
          if (widgetIdValue is int) {
            trackerWidgetId = widgetIdValue;
          } else if (widgetIdValue is String) {
            trackerWidgetId = int.tryParse(widgetIdValue);
          }
        } else if (settings.arguments is int) {
          trackerWidgetId = settings.arguments as int;
        }

        return _createRoute(
            TrackerGoalSelectorScreen(widgetId: trackerWidgetId));
      case '/habit_timer_selector':
      case 'habit_timer_selector':
        // 习惯计时器小组件配置界面
        int? habitTimerWidgetId;

        // 从 arguments 中解析 widgetId
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          // widgetId 可能是字符串或整数
          final widgetIdValue = args['widgetId'];
          if (widgetIdValue is int) {
            habitTimerWidgetId = widgetIdValue;
          } else if (widgetIdValue is String) {
            habitTimerWidgetId = int.tryParse(widgetIdValue);
          }
        } else if (settings.arguments is int) {
          habitTimerWidgetId = settings.arguments as int;
        }

        return _createRoute(
            HabitTimerSelectorScreen(widgetId: habitTimerWidgetId));
      case '/bill_shortcuts_selector':
      case 'bill_shortcuts_selector':
        // 快捷记账小组件配置界面
        int? billShortcutsWidgetId;

        // 从 arguments 中解析 widgetId
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          // widgetId 可能是字符串或整数
          final widgetIdValue = args['widgetId'];
          if (widgetIdValue is int) {
            billShortcutsWidgetId = widgetIdValue;
          } else if (widgetIdValue is String) {
            billShortcutsWidgetId = int.tryParse(widgetIdValue);
          }
        } else if (settings.arguments is int) {
          billShortcutsWidgetId = settings.arguments as int;
        }

        return _createRoute(
            BillShortcutsSelectorScreen(widgetId: billShortcutsWidgetId ?? 0));
      case '/activity_weekly_config':
      case 'activity_weekly_config':
        // 活动周视图小组件配置界面
        int? activityWeeklyWidgetId;

        // 从 arguments 中解析 widgetId
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          // widgetId 可能是字符串或整数
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
          return _createRoute(
            Scaffold(
              appBar: AppBar(title: const Text('错误')),
              body: const Center(
                child: Text('错误: widgetId 参数缺失'),
              ),
            ),
          );
        }

        return _createRoute(
            ActivityWeeklyConfigScreen(widgetId: activityWeeklyWidgetId));
      case '/habits_weekly_config':
      case 'habits_weekly_config':
        // 习惯周视图小组件配置界面
        int? habitsWeeklyWidgetId;

        // 从 arguments 中解析 widgetId
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          // widgetId 可能是字符串或整数
          final widgetIdValue = args['widgetId'];
          if (widgetIdValue is int) {
            habitsWeeklyWidgetId = widgetIdValue;
          } else if (widgetIdValue is String) {
            habitsWeeklyWidgetId = int.tryParse(widgetIdValue);
          }
        } else if (settings.arguments is int) {
          habitsWeeklyWidgetId = settings.arguments as int;
        }

        if (habitsWeeklyWidgetId == null) {
          return _createRoute(
            Scaffold(
              appBar: AppBar(title: const Text('错误')),
              body: const Center(
                child: Text('错误: widgetId 参数缺失'),
              ),
            ),
          );
        }

        return _createRoute(
            HabitsWeeklyConfigScreen(widgetId: habitsWeeklyWidgetId));
      case '/habit_timer_dialog':
      case 'habit_timer_dialog':
        // 习惯计时器对话框（从小组件打开）
        String? habitId;

        // 从 arguments 中解析 habitId
        if (settings.arguments is Map<String, dynamic>) {
          habitId = (settings.arguments as Map<String, dynamic>)['habitId'];
        } else if (settings.arguments is String) {
          habitId = settings.arguments as String;
        }

        if (habitId == null) {
          return _createRoute(
            Scaffold(
              body: Center(
                child: Text('Error: habitId is required'),
              ),
            ),
          );
        }

        // 获取 HabitsPlugin 实例
        final habitsPlugin = PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
        if (habitsPlugin == null) {
          return _createRoute(
            Scaffold(
              body: Center(
                child: Text('Error: HabitsPlugin not found'),
              ),
            ),
          );
        }

        // 查找对应的 Habit
        final habitController = habitsPlugin.getHabitController();
        final habits = habitController.getHabits();
        final habit = habits.cast<dynamic>().firstWhere(
          (h) => h.id == habitId,
          orElse: () => null,
        );

        if (habit == null) {
          return _createRoute(
            Scaffold(
              body: Center(
                child: Text('Error: Habit not found with id: $habitId'),
              ),
            ),
          );
        }

        // 返回包含 TimerDialog 的页面
        return _createRoute(
          Scaffold(
            backgroundColor: Colors.black.withOpacity(0.5),
            body: Center(
              child: TimerDialog(
                habit: habit,
                controller: habitController,
                initialTimerData: habitsPlugin.timerController.getTimerData(habitId),
              ),
            ),
          ),
        );
      default:
        return _createRoute(
          Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }

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
    todo: (context) => const TodoMainView(),
    tracker: (context) => const TrackerMainView(),
    floatingBall: (context) => const FloatingBallScreen(),
    widgetsConfig: (context) => const WidgetsConfigScreen(),
    jsConsole: (context) => const JSConsoleScreen(),
    jsonDynamicTest: (context) => const JsonDynamicTestScreen(),
    notificationTest: (context) => const NotificationTestPage(),
    superCupertinoTest: (context) => const SuperCupertinoTestScreen(),
  };

  static String get initialRoute => home;
}
