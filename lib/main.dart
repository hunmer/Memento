import 'dart:async';
import 'package:Memento/core/floating_ball/l10n/floating_ball_localizations.dart';
import 'package:Memento/plugins/bill/l10n/bill_localizations.dart';
import 'package:Memento/plugins/calendar/l10n/calendar_localizations.dart';
import 'package:Memento/plugins/contact/l10n/contact_localizations.dart';
import 'package:Memento/plugins/database/l10n/database_localizations.dart';
import 'package:Memento/plugins/goods/l10n/goods_localizations.dart';
import 'package:Memento/plugins/habits/l10n/habits_localizations.dart';
import 'package:Memento/plugins/nodes/l10n/nodes_localizations.dart';
import 'package:Memento/plugins/store/l10n/store_localizations.dart';
import 'package:Memento/plugins/timer/l10n/timer_localizations.dart';
import 'package:Memento/plugins/todo/l10n/todo_localizations.dart';
import 'package:Memento/plugins/tts/l10n/tts_localizations.dart';
import 'package:Memento/screens/settings_screen/l10n/settings_screen_localizations.dart';
import 'package:Memento/screens/settings_screen/screens/data_management_localizations.dart';
import 'package:Memento/screens/settings_screen/widgets/l10n/webdav_localizations.dart';
import 'package:Memento/widgets/file_preview/l10n/file_preview_localizations.dart';
import 'package:Memento/widgets/l10n/group_selector_localizations.dart';
import 'package:Memento/widgets/l10n/image_picker_localizations.dart';
import 'package:Memento/widgets/l10n/location_picker_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';

import 'package:flutter/material.dart';
import 'core/services/plugin_widget_sync_helper.dart';
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
import 'plugins/tracker/l10n/tracker_localizations.dart';
import 'plugins/calendar_album/l10n/calendar_album_localizations.dart';
import 'screens/route.dart';
import 'screens/settings_screen/controllers/auto_update_controller.dart';

// 从 app_initializer 导入全局变量
import 'core/app_initializer.dart';

// 从 app_widgets 导入页面过渡构建器
import 'core/app_widgets/page_transitions.dart';

void main() async {
  // 执行核心初始化（快速完成）
  await initializeApp();

  // 立即启动应用，其他初始化在后台进行
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    // 添加生命周期观察者
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _setupAutoUpdate();
    });
  }

  @override
  void dispose() {
    // 移除生命周期观察者
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 应用从后台恢复到前台时同步待处理的小组件变更
    if (state == AppLifecycleState.resumed) {
      debugPrint('应用恢复到前台，同步待处理的小组件变更');
      PluginWidgetSyncHelper.instance.syncPendingTaskChangesOnStartup();
      PluginWidgetSyncHelper.instance.syncPendingCalendarEventsOnStartup();
      PluginWidgetSyncHelper.instance.syncPendingGoalChangesOnStartup();
      PluginWidgetSyncHelper.instance.syncPendingHabitTimerChangesOnStartup();
    }
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
      initial: savedThemeMode ?? AdaptiveThemeMode.light,
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
            locale: globalConfigManager.getLocale(),
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
