import 'package:Memento/plugins/store/widgets/store_view/store_main.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/home_screen.dart';
import 'package:Memento/plugins/chat/screens/chat_screen/chat_screen.dart';
import 'package:Memento/screens/settings_screen/settings_screen.dart';

// 插件路由导入
import 'package:Memento/plugins/activity/activity_plugin.dart';
import 'package:Memento/plugins/bill/bill_plugin.dart';
import 'package:Memento/plugins/calendar/calendar_plugin.dart';
import 'package:Memento/plugins/calendar_album/calendar_album.dart';
import 'package:Memento/plugins/checkin/checkin_plugin.dart';
import 'package:Memento/plugins/contact/contact_plugin.dart';
import 'package:Memento/plugins/database/database_plugin.dart';
import 'package:Memento/plugins/day/day_plugin.dart';
import 'package:Memento/plugins/diary/diary_plugin.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';
import 'package:Memento/plugins/habits/habits_plugin.dart';
import 'package:Memento/plugins/nodes/nodes_plugin.dart';
import 'package:Memento/plugins/notes/notes_plugin.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';
import 'package:Memento/plugins/store/store_plugin.dart';
import 'package:Memento/plugins/timer/views/timer_main_view.dart';
import 'package:Memento/plugins/todo/todo_plugin.dart';
import 'package:Memento/plugins/tracker/tracker_plugin.dart';

class AppRoutes extends NavigatorObserver {
  // 路由路径常量
  static const String home = '/';
  static const String chat = '/chat';
  static const String diary = '/diary';
  static const String activity = '/activity';
  static const String checkin = '/checkin';
  static const String settings = '/settings';

  // 插件路由路径
  static const String bill = '/bill';
  static const String calendar = '/calendar';
  static const String calendarAlbum = '/calendar-album';
  static const String contact = '/contact';
  static const String database = '/database';
  static const String day = '/day';
  static const String goods = '/goods';
  static const String habits = '/habits';
  static const String nodes = '/nodes';
  static const String notes = '/notes';
  static const String openai = '/openai';
  static const String store = '/store';
  static const String timer = '/timer';
  static const String todo = '/todo';
  static const String tracker = '/tracker';

  // 自定义页面过渡动画
  static Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOut;

        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: curve),
          child: child,
        );
      },
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case 'home':
        return _createRoute(const HomeScreen());
      case 'chat':
        final args = settings.arguments as Map<String, dynamic>?;
        return _createRoute(
          ChatScreen(
            channel: args?['channel'],
            initialMessage: args?['initialMessage'],
            highlightMessage: args?['highlightMessage'],
            autoScroll: args?['autoScroll'] ?? false,
          ),
        );
      case 'diary':
        return _createRoute(const DiaryMainView());
      case 'activity':
        return _createRoute(const ActivityMainView());
      case 'checkin':
        return _createRoute(const CheckinMainView());
      case 'settings':
        return _createRoute(const SettingsScreen());
      case 'bill':
        return _createRoute(const BillMainView());
      // case 'calendar':
      //   return _createRoute(const CalendarMainView());
      // case 'calendarAlbum':
      //   return _createRoute(const CalendarAlbumMainView());
      case 'contact':
        return _createRoute(const ContactMainView());
      // case 'database':
      //   return _createRoute(const DatabaseMainView());
      // case 'day':
      //   return _createRoute(const DayMainView());
      // case 'goods':
      //   return _createRoute(const GoodsMainView());
      case 'habits':
        return _createRoute(const HabitsMainView());
      // case 'nodes':
      //   return _createRoute(const NodesScreen());
      // case 'notes':
      //   return _createRoute(const NotesScreen());
      case 'openai':
        return _createRoute(const OpenAIMainView());
      case 'store':
        return _createRoute(const StoreMainView());
      case 'timer':
        return _createRoute(const TimerMainView());
      // case 'todo':
      //   return _createRoute(const TodoScreen());
      // case 'tracker':
      //   return _createRoute(const TrackerScreen());
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
    diary: (context) => const DiaryMainView(),
    activity: (context) => const ActivityMainView(),
    checkin: (context) => const CheckinMainView(),
    settings: (context) => const SettingsScreen(),
    // 插件路由映射
    // bill: (context) => const BillScreen(),
    // calendar: (context) => const CalendarScreen(),
    // calendarAlbum: (context) => const CalendarAlbumScreen(),
    contact: (context) => const ContactMainView(),
    // database: (context) => const DatabaseScreen(),
    // day: (context) => const DayScreen(),
    // goods: (context) => const GoodsScreen(),
    habits: (context) => const HabitsMainView(),
    // nodes: (context) => const NodesScreen(),
    // notes: (context) => const NotesScreen(),
    openai: (context) => const OpenAIMainView(),
    store: (context) => const StoreMainView(),
    timer: (context) => const TimerMainView(),
    // todo: (context) => const TodoScreen(),
    // tracker: (context) => const TrackerScreen(),
  };

  static String get initialRoute => home;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    debugPrint('路由已推入: ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    debugPrint('路由已弹出: ${route.settings.name}');
  }
}
