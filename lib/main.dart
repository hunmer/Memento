import 'dart:async';
import 'package:Memento/core/event/event.dart';
import 'package:Memento/core/services/shortcut_manager.dart';
import 'package:Memento/core/utils/logger_util.dart';
import 'package:Memento/plugins/chat/screens/chat_screen/chat_screen.dart';
import 'package:Memento/plugins/contact/contact_plugin.dart';
import 'package:Memento/plugins/habits/habits_plugin.dart';
import 'package:Memento/screens/settings_screen/controllers/permission_controller.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:media_kit/media_kit.dart';
import 'plugins/chat/l10n/chat_localizations.dart';
import 'plugins/diary/l10n/diary_localizations.dart';
import 'plugins/day/l10n/day_localizations.dart';
import 'plugins/checkin/l10n/checkin_localizations.dart';
import 'plugins/activity/l10n/activity_localizations.dart';
import 'plugins/openai/l10n/openai_localizations.dart';
import 'plugins/notes/l10n/notes_localizations.dart';
import 'plugins/calendar_album/calendar_album.dart';
import 'plugins/calendar_album/l10n/calendar_album_localizations.dart';
import 'core/plugin_manager.dart';
import 'core/storage/storage_manager.dart';
import 'core/config_manager.dart';
import 'screens/home_screen/home_screen.dart';
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
      OpenAIPlugin(), // 添加OpenAI插件
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
        logger?.log('插件注册失败: ${plugin.name} - $e', level: 'ERROR');
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
    // 延迟执行以确保context可用
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    if (!mounted) return;

    if (hasUpdate) {
      updateController.showUpdateDialog(skipCheck: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      navigatorKey: navigatorKey,
      title: 'Memento',
      debugShowCheckedModeBanner: false, // 关闭调试横幅
      localizationsDelegates: [
        AppLocalizations.delegate,
        DiaryLocalizations.delegate,
        CheckinLocalizations.delegate,
        ActivityLocalizations.delegate,
        ChatLocalizations.delegate,
        DayLocalizationsDelegate.delegate,
        OpenAILocalizationsDelegate.delegate,
        NotesLocalizations.delegate,
        NodesPlugin().localizationsDelegate,
        const CalendarAlbumLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', ''), // 中文
        Locale('en', ''), // 英文
      ],
      locale:
          globalConfigManager.getLocale() ??
          const Locale('en', ''), // 使用保存的语言设置，默认英文

      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 4,
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        ),
      ),
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
          (BuildContext context) => AppLocalizations.of(context)!.appTitle,
    );
  }
}
