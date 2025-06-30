import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:Memento/plugins/notes/screens/notes_screen.dart';
import 'package:Memento/plugins/store/widgets/store_view/store_main.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/home_screen.dart';
import 'package:Memento/screens/settings_screen/settings_screen.dart';

// 插件路由导入
import 'package:Memento/plugins/activity/activity_plugin.dart';
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

  // 插件路由路径
  static const String bill = '/bill';
  static const String calendar = '/calendar';
  static const String calendarAlbum = '/calendar_album';
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
    switch (settings.name) {
      case '/':
        return _createRoute(const HomeScreen());
      case 'chat':
        return _createRoute(const ChatMainView());
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
      case 'calendar':
        return _createRoute(const CalendarMainView());
      case 'calendar_album':
        return _createRoute(const CalendarAlbumMainView());
      case 'contact':
        return _createRoute(const ContactMainView());
      case 'database':
        return _createRoute(const DatabaseMainView());
      case 'day':
        return _createRoute(const DayMainView());
      case 'goods':
        return _createRoute(const GoodsMainView());
      case 'habits':
        return _createRoute(const HabitsMainView());
      case 'nodes':
        return _createRoute(const NodesMainView());
      case 'notes':
        return _createRoute(const NotesMainView());
      case 'openai':
        return _createRoute(const OpenAIMainView());
      case 'store':
        return _createRoute(const StoreMainView());
      case 'timer':
        return _createRoute(const TimerMainView());
      case 'todo':
        return _createRoute(const TodoMainView());
      case 'tracker':
        return _createRoute(const TrackerMainView());
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
    bill: (context) => const BillMainView(),
    calendar: (context) => const CalendarMainView(),
    calendarAlbum: (context) => const CalendarAlbumMainView(),
    contact: (context) => const ContactMainView(),
    database: (context) => const DatabaseMainView(),
    day: (context) => const DayMainView(),
    goods: (context) => const GoodsMainView(),
    habits: (context) => const HabitsMainView(),
    nodes: (context) => const NodesMainView(),
    notes: (context) => const NotesMainView(),
    openai: (context) => const OpenAIMainView(),
    store: (context) => const StoreMainView(),
    timer: (context) => const TimerMainView(),
    todo: (context) => const TodoMainView(),
    tracker: (context) => const TrackerMainView(),
  };

  static String get initialRoute => home;
}
