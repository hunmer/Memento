import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:Memento/core/app_widgets/page_transitions.dart';
import 'package:Memento/core/app_initializer.dart';
import 'package:Memento/core/services/log_service.dart';

// GetX 统一翻译导入
import 'package:Memento/l10n/unified_translations.dart';

// 第三方库国际化
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

// 条件导入：StyledToast 在 Web 平台有问题
// 默认使用存根，有 IO 库时（移动/桌面）使用真实实现
import 'utils/styled_toast_stub.dart'
    if (dart.library.io) 'package:flutter_styled_toast/flutter_styled_toast.dart';

import 'package:flutter/material.dart';
import 'core/services/plugin_widget_sync_helper.dart';
import 'core/services/clipboard_service.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'screens/route.dart';
import 'screens/settings_screen/controllers/auto_update_controller.dart';

// 从 app_initializer 导入全局变量

void main() async {
  // 1. 捕获 Flutter Framework 错误（如 widget build 错误）
  FlutterError.onError = (FlutterErrorDetails details) {
    // 记录到日志服务
    final logService = LogService.instance;
    if (logService.isEnabled && logService.isInitialized) {
      logService.error(
        'FlutterError: ${details.exception}',
        error: details.exception,
        stackTrace: details.stack,
      );
    }

    // 在调试模式下仍然显示错误界面
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };

  // 2. 使用 runZonedGuarded 捕获所有未处理的异步异常
  runZonedGuarded(() async {
    // 3. 重写 debugPrint，让所有日志输出路由到 LogService
    // 这样无需修改现有的 debugPrint 调用
      final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message == null || message.isEmpty) return;

      // 在控制台仍然输出（开发环境方便调试）
        originalDebugPrint(message, wrapWidth: wrapWidth);

      // 同时记录到日志服务（如果启用）
      final logService = LogService.instance;
      if (logService.isEnabled && logService.isInitialized) {
        logService.info(message);
      }
    };

    // 执行核心初始化（快速完成）
    await initializeApp();

    // 立即启动应用，其他初始化在后台进行
    runApp(const MyApp());
  }, (error, stack) {
    // 捕获所有未处理的异步异常
    final logService = LogService.instance;
    if (logService.isEnabled && logService.isInitialized) {
      logService.error(
        'Uncaught Exception: $error',
        error: error,
        stackTrace: stack,
      );
    }

    // 在调试模式下打印到控制台（使用 print 而不是 debugPrint）
    if (kDebugMode) {
      print('Uncaught Exception: $error');
      print(stack);
    }
  });
}

/// 处理小组件URI的包装组件
/// 在应用启动时，如果有初始URI，直接返回目标页面而不显示首页
class WidgetUriHandler extends StatelessWidget {
  final Widget child;

  const WidgetUriHandler({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStartupState.instance,
      builder: (context, child) {
        final startupState = AppStartupState.instance;
        final initialUri = startupState.initialWidgetUri;

        // 如果有待处理的初始URI，显示加载页面
        if (initialUri != null && startupState.isHandlingInitialUri) {
          debugPrint('WidgetUriHandler: 显示加载页面，等待处理初始URI: $initialUri');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('core_starting'.tr),
                ],
              ),
            ),
          );
        }

        // 没有待处理的URI，正常显示子组件
        return child!;
      },
      child: child,
    );
  }
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
      // 初始化Flutter悬浮球
      await initializeFlutterFloatingBall();
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
      // 检查剪贴板数据
      ClipboardService.instance.processClipboard();
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
        cardColor: Colors.white, // 卡片背景设为纯白色
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, // AppBar 背景设为纯白色
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ).copyWith(
          surface: Colors.white, // 表面颜色设为纯白色
          secondaryContainer: Colors.white, // 次要容器颜色设为纯白色
        ),
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
          (theme, darkTheme) => WidgetUriHandler(
            child: GetMaterialApp(
              translations: UnifiedTranslations(),
              locale:
                  globalConfigManager.getLocale().languageCode == 'zh'
                      ? const Locale('zh', 'CN')
                      : const Locale('en', 'US'),
              fallbackLocale: const Locale('zh', 'CN'),
              scaffoldMessengerKey: scaffoldMessengerKey,
              navigatorKey: navigatorKey,
              title: 'Memento',
              debugShowCheckedModeBanner: false,
              localizationsDelegates: const [
                // 仅保留第三方库的国际化
                SfGlobalLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                FlutterQuillLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('zh', 'CN'), // 中文
                Locale('en', 'US'), // 英文
              ],
              theme: theme,
              darkTheme: darkTheme,
              builder: (context, child) {
                // 确保字体大小不受系统设置影响
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(1.0)),
                  child: StyledToast(
                    child: child!,
                  ),
                );
              },
              initialRoute: AppRoutes.initialRoute,
              routes: AppRoutes.routes,
              onGenerateRoute: AppRoutes.generateRoute,
              onGenerateTitle: (BuildContext context) => 'app_appTitle'.tr,
            ),
          ),
    );
  }
}
