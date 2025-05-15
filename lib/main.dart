import 'dart:async';

import 'package:Memento/core/event/event.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/utils/logger_util.dart';
import 'package:Memento/plugins/chat/screens/chat_screen/chat_screen.dart';
import 'package:Memento/screens/settings_screen/controllers/settings_screen_controller.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:media_kit/media_kit.dart';
import 'plugins/chat/l10n/chat_localizations.dart';
import 'plugins/diary/l10n/diary_localizations.dart';
import 'plugins/day/l10n/day_localizations.dart';
import 'plugins/checkin/l10n/checkin_localizations.dart';
import 'plugins/activity/l10n/activity_localizations.dart';
import 'plugins/openai/l10n/openai_localizations.dart';
import 'plugins/notes/l10n/notes_localizations.dart';
// 移除未使用的导入
import 'core/plugin_manager.dart';
import 'core/storage/storage_manager.dart';
import 'core/config_manager.dart';
import 'screens/home_screen/home_screen.dart';
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
import 'core/services/backup_service.dart'; // 备份服务

// 全局导航键
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// 全局单例实例
late final StorageManager globalStorage;
late final ConfigManager globalConfigManager;
late final PluginManager globalPluginManager;

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

    // 注册内置插件
    final plugins = [
      OpenAIPlugin(), // 添加OpenAI插件
      ChatPlugin.instance,
      DiaryPlugin.instance,
      ActivityPlugin.instance,
      CheckinPlugin.instance,
      TimerPlugin.instance,
      TodoPlugin.instance,
      DayPlugin.instance,
      await TrackerPlugin.initializeAndRegister(
        globalPluginManager,
        globalConfigManager,
      ),
      StorePlugin(), 
      NodesPlugin(), // 添加笔记插件
      NotesPlugin(), // 添加Notes插件
      GoodsPlugin.instance, // 添加物品插件
      BillPlugin(), // 添加账单插件
      CalendarPlugin(), 
    ];

    // 遍历并注册插件
    for (final plugin in plugins) {
      try {
        await globalPluginManager.registerPlugin(plugin);
      } catch (e) {
        _showError('插件注册失败: ${plugin.name} - $e');
      }
    }

    final updateController = AutoUpdateController.instance;
    updateController.initialize();

    // 延迟备份服务初始化到Widget构建完成后
    late final BackupService backupService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        backupService = BackupService(SettingsScreenController(), context);
      }
      // 插件初始化完成，发布事件
      eventManager.broadcast('plugins_initialized', EventArgs('plugins_initialized'));
    });
  } catch (e) {
    _showError('初始化失败: $e');
  }

  runApp(const MyApp());
}

// 临时错误处理桥接，直到MyApp初始化完成
void _showError(String message) {
  debugPrint(message);
  // 使用LoggerUtil记录错误
  LoggerUtil().log(message, level: 'ERROR');
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
    // 设置全局错误处理器
    FlutterError.onError = (details) {
      print(details);
      _showError(details.exceptionAsString());
    };

    // 延迟执行以确保context可用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAutoUpdate();
    });
  }

  void _showError(String message) {
    // 使用LoggerUtil记录错误
    LoggerUtil().log(message, level: 'ERROR');

    if (!mounted) return;

    // 使用runZonedGuarded捕获可能的异步错误
    runZonedGuarded(
      () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          // scaffoldMessengerKey.currentState?.showSnackBar(
          //   SnackBar(
          //     content: Text(message),
          //     duration: const Duration(seconds: 5),
          //   ),
          // );
        });
      },
      (error, stack) {
        debugPrint('Failed to show error: $error\nOriginal error: $message');
      },
    );
  }

  void _setupAutoUpdate() {
    if (!mounted) return;
    final updateController = AutoUpdateController.instance;

    // 设置context，这样更新控制器就可以显示UI了
    updateController.context = context;
  }

  // 手动检查更新的方法，可以在需要时调用
  Future<void> checkForUpdates() async {
    if (!mounted) return;

    final updateController = AutoUpdateController.instance;
    updateController.context = context;

    try {
      final hasUpdate = await updateController.checkForUpdates();
      if (!mounted) return;

      if (hasUpdate) {
        updateController.showUpdateDialog(skipCheck: true);
      }
    } catch (e) {}
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
        ChatLocalizations.delegate, // 添加聊天插件的本地化代理
        DayLocalizationsDelegate.delegate, // 添加纪念日插件的本地化代理
        OpenAILocalizationsDelegate.delegate, // 添加OpenAI插件的本地化代理
        NotesLocalizations.delegate, // 添加Notes插件的本地化代理
        NodesPlugin().localizationsDelegate, // 添加笔记插件的本地化代理
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
      navigatorObservers: [routeObserver], // 添加路由观察者
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        cardTheme: const CardTheme(
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
      home: const HomeScreen(),
      onGenerateRoute: (settings) {
        if (settings.name?.startsWith('/channel/') ?? false) {
          final channelId = settings.name!.substring('/channel/'.length);
          final args = settings.arguments as Map<String, dynamic>?;
          final channel = args?['channel'];
          final initialMessage = args?['initialMessage'];
          final highlightMessage = args?['highlightMessage'];
          final autoScroll = args?['autoScroll'] as bool? ?? false;

          if (channel != null) {
            return MaterialPageRoute(
              builder:
                  (context) => ChatScreen(
                    channel: channel,
                    initialMessage: initialMessage,
                    highlightMessage: highlightMessage,
                    autoScroll: autoScroll,
                  ),
            );
          }
        }
        return null;
      },
      onGenerateTitle:
          (BuildContext context) => AppLocalizations.of(context)!.appTitle,
    );
  }
}
