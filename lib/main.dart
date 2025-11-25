import 'dart:async';
import 'package:Memento/core/event/event.dart';
import 'package:Memento/core/floating_ball/l10n/floating_ball_localizations.dart';
import 'package:Memento/core/services/shortcut_manager.dart';
import 'package:Memento/core/notification_controller.dart';
import 'package:Memento/plugins/bill/l10n/bill_localizations.dart';
import 'package:Memento/plugins/calendar/l10n/calendar_localizations.dart';
import 'package:Memento/plugins/contact/contact_plugin.dart';
import 'package:Memento/plugins/contact/l10n/contact_localizations.dart';
import 'package:Memento/plugins/database/l10n/database_localizations.dart';
import 'package:Memento/plugins/goods/l10n/goods_localizations.dart';
import 'package:Memento/plugins/habits/habits_plugin.dart';
import 'package:Memento/plugins/habits/l10n/habits_localizations.dart';
import 'package:Memento/plugins/nodes/l10n/nodes_localizations.dart';
import 'package:Memento/plugins/store/l10n/store_localizations.dart';
import 'package:Memento/plugins/timer/l10n/timer_localizations.dart';
import 'package:Memento/plugins/todo/l10n/todo_localizations.dart';
import 'package:Memento/plugins/tts/l10n/tts_localizations.dart';
import 'package:Memento/screens/settings_screen/controllers/permission_controller.dart';
import 'package:Memento/screens/settings_screen/l10n/settings_screen_localizations.dart';
import 'package:Memento/screens/settings_screen/screens/data_management_localizations.dart';
import 'package:Memento/screens/settings_screen/widgets/l10n/webdav_localizations.dart';
import 'package:Memento/widgets/file_preview/l10n/file_preview_localizations.dart';
import 'package:Memento/widgets/l10n/group_selector_localizations.dart';
import 'package:Memento/widgets/l10n/image_picker_localizations.dart';
import 'package:Memento/widgets/l10n/location_picker_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:logging/logging.dart';
import 'package:home_widget/home_widget.dart';
import 'package:universal_platform/universal_platform.dart';

import 'package:flutter/material.dart';
import 'core/services/system_widget_service.dart';
import 'core/services/plugin_widget_sync_helper.dart';
import 'package:flutter/services.dart';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'plugins/chat/l10n/chat_localizations.dart';
import 'plugins/diary/l10n/diary_localizations.dart';
import 'plugins/day/l10n/day_localizations.dart';
import 'plugins/checkin/l10n/checkin_localizations.dart';
import 'plugins/activity/l10n/activity_localizations.dart';
import 'plugins/openai/l10n/openai_localizations.dart';
import 'plugins/notes/l10n/notes_localizations.dart';
import 'plugins/calendar_album/calendar_album_plugin.dart';
import 'plugins/calendar_album/l10n/calendar_album_localizations.dart';
import 'core/plugin_manager.dart';
import 'core/storage/storage_manager.dart';
import 'core/config_manager.dart';
import 'core/js_bridge/js_bridge_manager.dart';
import 'core/route/route_history_manager.dart';
import 'screens/route.dart';

import 'plugins/chat/chat_plugin.dart'; // 聊天插件
import 'plugins/diary/diary_plugin.dart'; // 日记插件
import 'plugins/activity/activity_plugin.dart'; // 活动插件
import 'plugins/checkin/checkin_plugin.dart'; // 打卡插件
import 'plugins/timer/timer_plugin.dart'; // 计时器插件
import 'plugins/todo/todo_plugin.dart'; // 任务插件
import 'plugins/day/day_plugin.dart'; // 纪念日插件
import 'plugins/nodes/nodes_plugin.dart'; // 笔记插件
import 'plugins/notes/notes_plugin.dart'; // Notes插件
import 'plugins/goods/goods_plugin.dart'; // 物品插件
import 'plugins/bill/bill_plugin.dart'; // 账单插件
import 'plugins/calendar/calendar_plugin.dart'; // 日历插件
import 'plugins/openai/openai_plugin.dart'; // OpenAI插件
import 'plugins/store/store_plugin.dart'; // store插件
import 'plugins/tracker/tracker_plugin.dart'; // OpenAI插件
import 'screens/settings_screen/controllers/auto_update_controller.dart'; // 自动更新控制器
import 'plugins/database/database_plugin.dart';
import 'plugins/scripts_center/scripts_center_plugin.dart'; // 脚本中心插件
import 'plugins/agent_chat/agent_chat_plugin.dart'; // Agent Chat插件
import 'plugins/tts/tts_plugin.dart'; // TTS语音朗读插件
import 'utils/image_utils.dart'; // 图片工具类


// 主页小组件注册
import 'plugins/chat/home_widgets.dart';
import 'plugins/diary/home_widgets.dart';
import 'plugins/activity/home_widgets.dart';
import 'plugins/agent_chat/home_widgets.dart';
import 'plugins/openai/home_widgets.dart';
import 'plugins/notes/home_widgets.dart';
import 'plugins/goods/home_widgets.dart';
import 'plugins/bill/home_widgets.dart';
import 'plugins/todo/home_widgets.dart';
import 'plugins/checkin/home_widgets.dart';
import 'plugins/calendar/home_widgets.dart';
import 'plugins/timer/home_widgets.dart';
import 'plugins/day/home_widgets.dart';
import 'plugins/tracker/home_widgets.dart';
import 'plugins/store/home_widgets.dart';
import 'plugins/nodes/home_widgets.dart';
import 'plugins/contact/home_widgets.dart';
import 'plugins/habits/home_widgets.dart';
import 'plugins/database/home_widgets.dart';
import 'plugins/calendar_album/home_widgets.dart';
import 'screens/home_screen/managers/home_layout_manager.dart';

// 无动画的页面过渡构建器 - 解决键盘弹出时的卡顿问题
class NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 直接返回子组件,不添加任何过渡动画
    return child;
  }
}

// 全局导航键
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// 全局单例实例
late final StorageManager globalStorage;
late final ConfigManager globalConfigManager;
late final PluginManager globalPluginManager;
late final AppShortcutManager globalShortcutManager;
AdaptiveThemeMode? _savedThemeMode;
late PermissionController _permissionController;

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化通知控制器
  await NotificationController.initialize();

  // 请求通知权限
  await NotificationController.requestPermission();

  // 配置日志输出
  Logger.root.level = Level.ALL; // 设置日志级别为 ALL 以显示所有日志
  Logger.root.onRecord.listen((record) {
    // 输出日志到控制台
    debugPrint('[${record.level.name}] ${record.loggerName}: ${record.message}');
    // 如果有错误或堆栈追踪,也输出
    if (record.error != null) {
      debugPrint('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      debugPrint('StackTrace: ${record.stackTrace}');
    }
  });

  // 设置首选方向为竖屏
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  _savedThemeMode = await AdaptiveTheme.getThemeMode();

  try {
    // 创建并初始化存储管理器（内部会处理Web平台的情况）
    globalStorage = StorageManager();
    await globalStorage.initialize();

    // 初始化配置管理器
    globalConfigManager = ConfigManager(globalStorage);
    await globalConfigManager.initialize();

    // 初始化 ImageUtils 的同步方法缓存
    await ImageUtils.initializeSync();

    // 初始化路由历史管理器
    await RouteHistoryManager.instance.initialize(storage: globalStorage);

    // 获取插件管理器单例实例并初始化
    globalPluginManager = PluginManager();
    await globalPluginManager.setStorageManager(globalStorage);

    // 设置全局错误处理器
    FlutterError.onError = (details) {
      debugPrint(details.toString());
    };

    globalShortcutManager = AppShortcutManager();
    globalShortcutManager.initialize();

    // 初始化 JS Bridge（在插件注册前）
    try {
      await JSBridgeManager.instance.initialize();
      debugPrint('JS Bridge 初始化成功');
    } catch (e) {
      debugPrint('JS Bridge 初始化失败: $e');
    }

    // 注册内置插件
    final plugins = [
      ChatPlugin(),
      OpenAIPlugin(),
      AgentChatPlugin(), // Agent Chat插件
      DiaryPlugin(),
      ActivityPlugin(),
      CheckinPlugin(),
      ContactPlugin(),
      HabitsPlugin(),
      DatabasePlugin(),
      TimerPlugin(),
      TodoPlugin(),
      DayPlugin(),
      TrackerPlugin(),
      StorePlugin(),
      NodesPlugin(),
      NotesPlugin(),
      GoodsPlugin(),
      BillPlugin(),
      CalendarPlugin(),
      CalendarAlbumPlugin(),
      ScriptsCenterPlugin(), // 脚本中心插件
      TTSPlugin(), // TTS语音朗读插件
    ];

    // 遍历并注册插件
    for (final plugin in plugins) {
      try {
        await globalPluginManager.registerPlugin(plugin);
      } catch (e) {
        debugPrint('插件注册失败: ${plugin.id} - $e');
      }
    }

    // 初始化主页小组件系统
    await _initializeHomeWidgets();
    final updateController = AutoUpdateController.instance;
    updateController.initialize();

    // 设置桌面小组件点击监听器
    await _setupWidgetClickListener();

    // 初始化系统桌面小组件服务并同步数据
    await SystemWidgetService.instance.initialize();
    await PluginWidgetSyncHelper.instance.syncAllPlugins();

    // 延迟备份服务初始化到Widget构建完成后
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = navigatorKey.currentContext;
      if (context != null) {
        _permissionController = PermissionController(context);
        // 检查权限
        await _permissionController.checkAndRequestPermissions();
      }
      // 插件初始化完成，发布事件
      eventManager.broadcast(
        'plugins_initialized',
        EventArgs('plugins_initialized'),
      );
    });
  } catch (e) {
    debugPrint('初始化失败: $e');
  }

  runApp(const MyApp());
}

/// 初始化主页小组件系统
Future<void> _initializeHomeWidgets() async {
  try {
    // 注册所有插件的小组件
    ChatHomeWidgets.register();
    DiaryHomeWidgets.register();
    ActivityHomeWidgets.register();
    AgentChatHomeWidgets.register();
    OpenAIHomeWidgets.register();
    NotesHomeWidgets.register();
    GoodsHomeWidgets.register();
    BillHomeWidgets.register();
    TodoHomeWidgets.register();
    CheckinHomeWidgets.register();
    CalendarHomeWidgets.register();
    TimerHomeWidgets.register();
    DayHomeWidgets.register();
    TrackerHomeWidgets.register();
    StoreHomeWidgets.register();
    NodesHomeWidgets.register();
    ContactHomeWidgets.register();
    HabitsHomeWidgets.register();
    DatabaseHomeWidgets.register();
    CalendarAlbumHomeWidgets.register();

    // 初始化布局管理器
    final layoutManager = HomeLayoutManager();
    await layoutManager.initialize();

    debugPrint('主页小组件系统初始化完成');
  } catch (e) {
    debugPrint('主页小组件系统初始化失败: $e');
  }
}

/// 设置桌面小组件点击监听器
Future<void> _setupWidgetClickListener() async {
  // home_widget 插件只支持 Android 和 iOS 平台
  if (!UniversalPlatform.isAndroid && !UniversalPlatform.isIOS) {
    debugPrint('跳过小组件点击监听器设置（当前平台不支持 home_widget 插件）');
    return;
  }

  // 初始化 HomeWidget (必须在监听前调用)
  // 只在 iOS 平台上设置 App Group ID，因为 setAppGroupId 只在 iOS 上有效
  if (UniversalPlatform.isIOS) {
    await HomeWidget.setAppGroupId('group.github.hunmer.memento');
  }

  // 监听 HomeWidget 的点击事件（备用方式）
  HomeWidget.widgetClicked.listen((Uri? uri) {
    if (uri != null) {
      _handleWidgetClick(uri.toString());
    }
  });

  // 监听 Android 原生通过 MethodChannel 发送的小组件点击事件
  const platform = MethodChannel('github.hunmer.memento/widget');
  platform.setMethodCallHandler((call) async {
    if (call.method == 'onWidgetClicked') {
      final url = call.arguments as String?;
      if (url != null) {
        _handleWidgetClick(url);
      }
    }
  });

  debugPrint('桌面小组件点击监听器已设置');
}

/// 处理小组件点击事件
void _handleWidgetClick(String url) {
  debugPrint('收到桌面小组件点击事件: $url');

  try {
    final uri = Uri.parse(url);
    debugPrint('URI path: ${uri.path}');
    debugPrint('URI query: ${uri.query}');

    // 解析 URI 路径和参数
    // 例如: memento://widget/quick_send?channelId=xxx
    String routePath = uri.path;

    // 移除 /widget 前缀（如果存在）
    if (routePath.startsWith('/widget/')) {
      routePath = routePath.substring(7); // 移除 "/widget"，保留 /quick_send
    } else if (routePath.startsWith('widget/')) {
      routePath = '/${routePath.substring(7)}'; // 添加前导斜杠
    }

    debugPrint('处理后的路由路径: $routePath');

    // 提取参数
    final queryParams = uri.queryParameters;
    String? argument;
    if (queryParams.containsKey('channelId')) {
      argument = queryParams['channelId'];
    } else if (queryParams.containsKey('conversationId')) {
      argument = queryParams['conversationId'];
    }

    debugPrint('导航到路由: $routePath, 参数: $argument');

    // 延迟导航，确保应用完全启动
    Future.delayed(const Duration(milliseconds: 100), () {
      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        debugPrint('执行导航: 重置路由栈并push RouteSettings($routePath, arguments: $argument)');
        try {
          // 从小组件进入时，重置路由栈为两层：首页 + 目标页面
          // 1. 先清除所有路由并回到首页
          navigator.pushNamedAndRemoveUntil(
            '/',
            (route) => false,
          );

          // 2. 延迟一帧后再推入目标路由，确保首页已经完全加载
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final route = AppRoutes.generateRoute(RouteSettings(
              name: routePath,
              arguments: argument,
            ));
            navigator.push(route);
            debugPrint('导航成功：路由栈现在有两层 (/ -> $routePath)');
          });
        } catch (error, stack) {
          debugPrint('路由导航失败: $error');
          debugPrint('堆栈: $stack');
        }
      } else {
        debugPrint('导航器尚未初始化，延迟500ms后重试');
        Future.delayed(const Duration(milliseconds: 500), () {
          final retryNavigator = navigatorKey.currentState;
          if (retryNavigator != null) {
            try {
              // 重试时也使用相同的两层路由栈逻辑
              retryNavigator.pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );

              WidgetsBinding.instance.addPostFrameCallback((_) {
                final route = AppRoutes.generateRoute(RouteSettings(
                  name: routePath,
                  arguments: argument,
                ));
                retryNavigator.push(route);
                debugPrint('重试导航成功');
              });
            } catch (e) {
              debugPrint('重试导航失败: $e');
            }
          } else {
            debugPrint('导航器初始化失败');
          }
        });
      }
    });
  } catch (e, stack) {
    debugPrint('处理小组件点击失败: $e');
    debugPrint('堆栈: $stack');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _setupAutoUpdate();
    });
  }

  void _setupAutoUpdate() {
    if (!mounted) return;
    final updateController = AutoUpdateController.instance;
    updateController.context = context;
  }

  Future<void> checkForUpdates() async {
    if (!mounted) return;

    final updateController = AutoUpdateController.instance;
    updateController.context = context;
    final hasUpdate = await updateController.checkForUpdates();
    if (hasUpdate) {
      updateController.showUpdateDialog(skipCheck: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        // 使用无动画构建器以提升性能,特别是键盘弹出时
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.iOS: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
          },
        ),
      ),
      dark: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        // 使用无动画构建器以提升性能,特别是键盘弹出时
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.iOS: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
          },
        ),
      ),
      initial: _savedThemeMode ?? AdaptiveThemeMode.light,
      builder:
          (theme, darkTheme) => MaterialApp(
            scaffoldMessengerKey: scaffoldMessengerKey,
            navigatorKey: navigatorKey,
            title: 'Memento',
            debugShowCheckedModeBanner: false, // 关闭调试横幅
            localizationsDelegates: [
              AppLocalizations.delegate,
              DiaryLocalizations.delegate,
              StoreLocalizations.delegate,
              CheckinLocalizations.delegate,
              DatabaseLocalizations.delegate,
              ActivityLocalizations.delegate,
              TimerLocalizations.delegate,
              ChatLocalizations.delegate,
              ContactLocalizations.delegate,
              TrackerLocalizations.delegate,
              HabitsLocalizations.delegate,
              TTSLocalizations.delegate,
              ImagePickerLocalizations.delegate,
              SettingsScreenLocalizations.delegate,
              DataManagementLocalizations.delegate,
              CalendarLocalizations.delegate,
              FilePreviewLocalizations.delegate,
              GroupSelectorLocalizations.delegate,
              BillLocalizations.delegate,
              LocationPickerLocalizations.delegate,
              DayLocalizationsDelegate.delegate,
              OpenAILocalizationsDelegate.delegate,
              NotesLocalizations.delegate,
              TodoLocalizations.delegate,
              CalendarAlbumLocalizations.delegate,
              FloatingBallLocalizations.delegate,
              GoodsLocalizations.delegate,
              NodesLocalizations.delegate,
              SfGlobalLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              WebDAVLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('zh', ''), // 中文
              Locale('en', ''), // 英文
            ],
            locale:
                globalConfigManager.getLocale(),
            theme: theme,
            darkTheme: darkTheme,
            builder: (context, child) {
              // 确保字体大小不受系统设置影响
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.0)),
                child: child!,
              );
            },
            initialRoute: AppRoutes.initialRoute,
            routes: AppRoutes.routes,
            onGenerateRoute: AppRoutes.generateRoute,
            onGenerateTitle:
                (BuildContext context) =>
                    AppLocalizations.of(context)!.appTitle,
          ),
    );
  }
}
