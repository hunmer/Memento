import 'dart:async';
import 'package:Memento/core/event/event.dart';
import 'package:Memento/core/floating_ball/l10n/floating_ball_localizations.dart';
import 'package:Memento/core/services/shortcut_manager.dart';
import 'package:Memento/core/utils/logger_util.dart';
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
import 'package:Memento/screens/settings_screen/controllers/permission_controller.dart';
import 'package:Memento/screens/settings_screen/l10n/log_settings_localizations.dart';
import 'package:Memento/screens/settings_screen/l10n/settings_screen_localizations.dart';
import 'package:Memento/screens/settings_screen/screens/data_management_localizations.dart';
import 'package:Memento/screens/settings_screen/widgets/l10n/webdav_localizations.dart';
import 'package:Memento/widgets/l10n/group_selector_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:media_kit/media_kit.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:Memento/core/theme_controller.dart';
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

// 全局导航键
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// 全局单例实例
late final StorageManager globalStorage;
late final ConfigManager globalConfigManager;
late final PluginManager globalPluginManager;
late final AppShortcutManager globalShortcutManager;
AdaptiveThemeMode? _savedThemeMode;
LoggerUtil? logger;
late PermissionController _permissionController;

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 MediaKit
  MediaKit.ensureInitialized();

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

    // 获取插件管理器单例实例并初始化
    globalPluginManager = PluginManager();
    await globalPluginManager.setStorageManager(globalStorage);

    logger = LoggerUtil();
    // 设置全局错误处理器
    FlutterError.onError = (details) {
      logger?.log(details.exceptionAsString(), level: 'ERROR');
      debugPrint(details.toString());
    };

    globalShortcutManager = AppShortcutManager();
    globalShortcutManager.initialize();

    // 注册内置插件
    final plugins = [
      ChatPlugin(),
      OpenAIPlugin(),
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
    ];

    // 遍历并注册插件
    for (final plugin in plugins) {
      try {
        await globalPluginManager.registerPlugin(plugin);
      } catch (e) {
        logger?.log('插件注册失败: ${plugin.id} - $e', level: 'ERROR');
      }
    }

    final updateController = AutoUpdateController.instance;
    updateController.initialize();

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
    logger?.log('初始化失败: $e', level: 'ERROR');
    debugPrint('初始化失败: $e');
  }

  runApp(const MyApp());
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
      light: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      dark: ThemeData.dark(useMaterial3: true),
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
              SettingsScreenLocalizations.delegate,
              DataManagementLocalizations.delegate,
              LogSettingsLocalizationsDelegate(),
              CalendarLocalizations.delegate,
              GroupSelectorLocalizations.delegate,
              BillLocalizations.delegate,
              DayLocalizationsDelegate.delegate,
              OpenAILocalizationsDelegate.delegate,
              NotesLocalizations.delegate,
              TodoLocalizations.delegate,
              CalendarAlbumLocalizations.delegate,
              FloatingBallLocalizations.delegate,
              GoodsLocalizations.delegate,
              NodesLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              WebDAVLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('zh', ''), // 中文
              Locale('en', ''), // 英文
            ],
            locale:
                globalConfigManager.getLocale() ??
                WidgetsBinding.instance.window.locale,
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
