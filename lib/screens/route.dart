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
import 'package:Memento/screens/settings_screen/screens/overlay_test_screen.dart';

// 插件路由导入
import 'package:Memento/plugins/activity/activity_plugin.dart';
import 'package:Memento/plugins/agent_chat/agent_chat_plugin.dart';
import 'package:Memento/plugins/bill/bill_plugin.dart';
import 'package:Memento/plugins/calendar/calendar_plugin.dart';
import 'package:Memento/plugins/calendar_album/calendar_album_plugin.dart';
import 'package:Memento/plugins/checkin/checkin_plugin.dart';
import 'package:Memento/plugins/contact/contact_plugin.dart';
import 'package:Memento/plugins/database/database_plugin.dart';
import 'package:Memento/plugins/day/day_plugin.dart';
import 'package:Memento/plugins/diary/diary_plugin.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';
import 'package:Memento/plugins/habits/habits_plugin.dart';
import 'package:Memento/plugins/nodes/nodes_plugin.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';
import 'package:Memento/plugins/scripts_center/scripts_center_plugin.dart';
import 'package:Memento/plugins/timer/views/timer_main_view.dart';
import 'package:Memento/plugins/todo/views/todo_main_view.dart';
import 'package:Memento/plugins/tracker/tracker_plugin.dart';

class AppRoutes extends NavigatorObserver {
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

  // Agent Chat 子页面路由
  static const String toolTemplate = '/tool_template';
  static const String toolManagement = '/tool_management';

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
    // 处理系统小组件的 Deep Link 跳转
    // 格式: memento://widget/{pluginId} 或 memento://widget/{pluginId}?id={id}
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
        final conversationId = settings.arguments as String?;
        return _createRoute(AgentChatMainView(conversationId: conversationId));
      case '/bill':
      case 'bill':
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
      case '/overlay_test':
      case 'overlay_test':
        return _createRoute(const OverlayTestScreen());
      case '/chat':
      case 'chat':
        // 支持通过 channelId 参数直接打开指定频道
        final channelId = settings.arguments as String?;
        return _createRoute(ChatMainView(channelId: channelId));
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
    jsConsole: (context) => const JSConsoleScreen(),
    jsonDynamicTest: (context) => const JsonDynamicTestScreen(),
    notificationTest: (context) => const NotificationTestPage(),
    superCupertinoTest: (context) => const SuperCupertinoTestScreen(),
    overlayTest: (context) => const OverlayTestScreen(),
  };

  static String get initialRoute => home;
}
