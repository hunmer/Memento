import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:adaptive_theme/adaptive_theme.dart';

import 'package:Memento/core/notification_controller.dart';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/services/shortcut_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_manager.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/core/services/system_widget_service.dart';
import 'package:Memento/core/services/plugin_widget_sync_helper.dart';
import 'package:Memento/core/services/timer/unified_timer_controller.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:memento_foreground_service/memento_foreground_service.dart';
import 'package:memento_notifications/memento_notifications.dart';
import 'package:Memento/core/builtin_plugins.dart';
import 'package:Memento/screens/settings_screen/controllers/auto_update_controller.dart';
import 'package:Memento/screens/settings_screen/controllers/permission_controller.dart';
import 'package:Memento/screens/settings_screen/widgets/permission_request_dialog.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:Memento/core/event/event.dart';
import 'package:Memento/core/action/action_manager.dart';
import 'package:Memento/core/floating_ball/floating_ball_service.dart';
import 'app_widgets/home_widget_service.dart';
import 'app_widgets/floating_ball_service.dart';
import 'package:Memento/screens/route.dart';
import 'global_flags.dart';
import 'services/toast_service.dart';
import 'services/file_watch_sync_service.dart';
import 'services/log_service.dart';
import 'api_forwarding/api_forwarding_config.dart';
import 'api_forwarding/api_forwarding_service.dart';
import 'services/speech_recognition_config_service.dart';

/// 应用启动状态管理
class AppStartupState extends ChangeNotifier {
  static final AppStartupState instance = AppStartupState._();
  AppStartupState._();

  bool _coreReady = false; // 核心服务就绪（存储、配置）
  bool _pluginsReady = false; // 插件注册完成
  bool _fullyReady = false; // 所有初始化完成
  String _loadingMessage = '正在启动...';

  // 待处理的初始URI（从小组件启动时）
  Uri? _initialWidgetUri;
  bool _isHandlingInitialUri = false; // 是否正在处理初始URI

  bool get coreReady => _coreReady;
  bool get pluginsReady => _pluginsReady;
  bool get fullyReady => _fullyReady;
  String get loadingMessage => _loadingMessage;
  Uri? get initialWidgetUri => _initialWidgetUri;
  bool get isHandlingInitialUri => _isHandlingInitialUri;

  void _setCoreReady() {
    _coreReady = true;
    notifyListeners();
  }

  void _setPluginsReady() {
    _pluginsReady = true;
    notifyListeners();
  }

  void _setFullyReady() {
    _fullyReady = true;
    notifyListeners();
  }

  void _setLoadingMessage(String message) {
    _loadingMessage = message;
    notifyListeners();
  }

  /// 设置待处理的初始URI
  void setInitialWidgetUri(Uri uri) {
    _initialWidgetUri = uri;
    _isHandlingInitialUri = true;
    notifyListeners();
  }

  /// 清除初始URI（处理完成后调用）
  void clearInitialWidgetUri() {
    _initialWidgetUri = null;
    _isHandlingInitialUri = false;
    notifyListeners();
  }
}

const String _permissionOnboardingKey = 'permissionsOnboardingCompleted';

bool _shouldHandlePermissionsForPlatform() {
  return UniversalPlatform.isAndroid || UniversalPlatform.isIOS;
}

/// 应用初始化函数 - 快速启动版本
/// 只执行最小必要的同步初始化，其他功能后台加载
Future<void> initializeApp() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 配置日志输出（轻量级，不阻塞）
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint(
      '[${record.level.name}] ${record.loggerName}: ${record.message}',
    );
    if (record.error != null) {
      debugPrint('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      debugPrint('StackTrace: ${record.stackTrace}');
    }

    // 同时输出到日志服务
    final logService = LogService.instance;
    if (logService.isEnabled) {
      final message = '[${record.loggerName}] ${record.message}';
      switch (record.level.name) {
        case 'WARNING':
          logService.warning(message);
          break;
        case 'SEVERE':
        case 'SHOUT':
          logService.error(
            message,
            error: record.error,
            stackTrace: record.stackTrace,
          );
          break;
        case 'INFO':
        case 'CONFIG':
          logService.info(message);
          break;
        default:
          logService.debug(message);
      }
    }
  });

  // 设置首选方向为竖屏（快速操作）
  unawaited(
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]),
  );

  // 异步获取主题，不阻塞启动
  unawaited(
    AdaptiveTheme.getThemeMode().then((mode) {
      savedThemeMode = mode;
    }),
  );

  try {
    // === 核心初始化（必须同步完成） ===
    // 创建并初始化存储管理器
    globalStorage = StorageManager();
    await globalStorage.initialize();

    // 初始化配置管理器
    globalConfigManager = ConfigManager(globalStorage);
    await globalConfigManager.initialize();

    // 初始化日志服务（根据配置决定是否启用）
    unawaited(LogService.instance.initialize(globalStorage));

    // 初始化插件管理器（不注册插件）
    globalPluginManager = PluginManager();
    await globalPluginManager.setStorageManager(globalStorage);

    // 设置全局错误处理器
    FlutterError.onError = (details) {
      debugPrint(details.toString());
    };

    // 初始化 Toast 服务
    Toast.setNavigatorKey(navigatorKey);

    // 在初始化通知服务之前先清理历史通知和计时器状态
    // 这是防止应用重启后通知自动复原的关键步骤
    AppStartupState.instance._setLoadingMessage('正在清理历史通知...');
    await MementoNotifications.instance.cancelAll();

    // 同时清理统一计时器控制器的活动计时器，防止插件重新创建通知
    try {
      final timerController = UnifiedTimerController();
      await timerController.clearAll();
      debugPrint('[AppInitializer] 已清理所有活动计时器');
    } catch (e) {
      debugPrint('[AppInitializer] 清理计时器状态失败（可能尚未初始化）: $e');
    }

    // 停止前台服务（防止系统重启后自动启动）
    // 仅在移动端执行此操作
    if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) {
      try {
        final foregroundService = MementoForegroundService.instance;
        if (await foregroundService.isRunning) {
          await foregroundService.stopService();
          debugPrint('[AppInitializer] 已停止前台服务');
        }
      } catch (e) {
        debugPrint('[AppInitializer] 停止前台服务失败: $e');
      }
    }

    debugPrint('[AppInitializer] 已清理所有历史通知、计时器状态和前台服务');

    // 初始化通知控制器（设置监听器和配置）
    AppStartupState.instance._setLoadingMessage('正在初始化通知服务...');
    await NotificationController.initialize();

    // 核心服务就绪，可以显示UI
    AppStartupState.instance._setCoreReady();

    // === 检查是否有来自小组件的初始URI ===
    // 这必须在设置监听器之前执行，否则会错过启动时的URI
    unawaited(_handleInitialWidgetUri());

    // === 后台异步初始化 ===
    unawaited(_initializeBackgroundServices());
  } catch (e) {
    debugPrint('核心初始化失败: $e');
    // 即使失败也标记为就绪，让用户能看到错误界面
    AppStartupState.instance._setCoreReady();
  }
}

/// 后台服务初始化 - 在UI显示后执行
Future<void> _initializeBackgroundServices() async {
  final startupState = AppStartupState.instance;

  try {
    // 请求通知权限（在后台执行，不阻塞启动）
    unawaited(NotificationController.requestPermission());

    // 初始化 ImageUtils
    unawaited(ImageUtils.initializeSync());

    // 初始化路由历史管理器
    unawaited(RouteHistoryManager.instance.initialize(storage: globalStorage));

    // 初始化快捷方式管理器
    globalShortcutManager = AppShortcutManager();
    globalShortcutManager.initialize();

    // 初始化 JS Bridge
    unawaited(
      JSBridgeManager.instance
          .initialize()
          .then((_) {
            debugPrint('JS Bridge 初始化成功');
          })
          .catchError((e) {
            debugPrint('JS Bridge 初始化失败: $e');
          }),
    );

    // 初始化语音识别配置服务
    unawaited(
      SpeechRecognitionConfigService.instance
          .initialize()
          .then((_) {
            debugPrint('语音识别配置服务初始化成功');
          })
          .catchError((e) {
            debugPrint('语音识别配置服务初始化失败: $e');
          }),
    );

    // === 注册插件（核心功能，可配置） ===
    startupState._setLoadingMessage('正在加载插件...');
    await _registerPlugins();
    startupState._setPluginsReady();

    // === 初始化悬浮球动作管理器 ===
    unawaited(_initializeFloatingBallActions());

    // === 后续初始化（低优先级） ===
    startupState._setLoadingMessage('正在完成初始化...');

    // 初始化主页小组件系统
    unawaited(initializeHomeWidgets());

    // 初始化自动更新控制器
    final updateController = AutoUpdateController.instance;
    updateController.initialize();

    // 设置桌面小组件点击监听器
    unawaited(setupWidgetClickListener());

    // 初始化系统桌面小组件服务并同步数据
    unawaited(
      SystemWidgetService.instance.initialize().then((_) {
        PluginWidgetSyncHelper.instance.syncAllPlugins();
      }),
    );

    // 恢复悬浮球状态
    unawaited(restoreFloatingBallState());

    // 初始化文件监听同步服务（用于自动同步文件变更到服务器）
    unawaited(fileWatchSyncService.initialize());

    // 初始化 API 转发服务（如果配置了自动连接）
    unawaited(_initializeApiForwardingService());

    // 延迟执行权限检查和小组件同步
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = navigatorKey.currentContext;
      if (context != null && _shouldHandlePermissionsForPlatform()) {
        _permissionController = PermissionController();
        final hasCompletedPermissions = globalConfigManager
            .getAppConfigValue<bool>(_permissionOnboardingKey, false);

        if (!hasCompletedPermissions) {
          await showPermissionRequestDialog(
            context: context,
            controller: _permissionController,
            barrierDismissible: false,
            showSkipButton: true,
          );
          await globalConfigManager.setAppConfigValue(
            _permissionOnboardingKey,
            true,
          );
        }
      }

      // 发布插件初始化完成事件
      eventManager.broadcast(
        'plugins_initialized',
        EventArgs('plugins_initialized'),
      );

      // 同步待处理的小组件变更
      await PluginWidgetSyncHelper.instance.syncPendingTaskChangesOnStartup();
      await PluginWidgetSyncHelper.instance.syncPendingGoalChangesOnStartup();
      await PluginWidgetSyncHelper.instance
          .syncPendingHabitTimerChangesOnStartup();
    });

    startupState._setFullyReady();
  } catch (e) {
    debugPrint('后台初始化失败: $e');
    startupState._setFullyReady();
  }
}

/// 处理来自小组件的初始URI（应用冷启动时）
Future<void> _handleInitialWidgetUri() async {
  try {
    // 检查是否有初始的URI（通过小组件启动时）
    final initialUri = await SystemWidgetService.instance.getInitialUri();
    if (initialUri != null && initialUri.toString().isNotEmpty) {
      debugPrint('检测到来自小组件的初始URI: $initialUri');

      // 将URI设置到AppStartupState中
      AppStartupState.instance.setInitialWidgetUri(initialUri);

      // 延迟等待应用完全初始化
      await Future.delayed(const Duration(milliseconds: 500));

      // 直接导航到对应路由
      _navigateToWidgetUri(initialUri.toString());
    }
  } catch (e) {
    debugPrint('处理初始URI失败: $e');
  }
}

/// 导航到小组件URI对应的页面
/// 这是从 home_widget_service.dart 移植过来的简化版本
void _navigateToWidgetUri(String url) {
  debugPrint('收到桌面小组件点击事件: $url');

  // 标记应用从小组件启动，防止错误地自动打开最后使用的插件
  isLaunchedFromWidget = true;

  try {
    final uri = Uri.parse(url);
    debugPrint('URI scheme: ${uri.scheme}');
    debugPrint('URI host: ${uri.host}');
    debugPrint('URI path: ${uri.path}');
    debugPrint('URI query: ${uri.query}');

    // 解析 URI 路径和参数
    String routePath = uri.path;

    // 如果 path 为空或只有斜杠，使用 host 作为路由路径
    if (routePath.isEmpty || routePath == '/') {
      routePath = '/${uri.host}';
      debugPrint('使用 host 作为路由路径: $routePath');
    }

    // 移除 /widget 前缀（如果存在）
    if (routePath.startsWith('/widget/')) {
      routePath = routePath.substring(7);
    } else if (routePath.startsWith('widget/')) {
      routePath = '/${routePath.substring(7)}';
    }

    debugPrint('处理后的路由路径: $routePath');

    // 提取所有查询参数
    final queryParams = uri.queryParameters;

    // 将 queryParams 作为 arguments 传递
    final arguments = queryParams.isNotEmpty ? queryParams : null;

    debugPrint('导航到路由: $routePath, 参数: $arguments');

    // 执行导航
    Future.delayed(const Duration(milliseconds: 100), () {
      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        debugPrint(
          '执行导航: 重置路由栈并push RouteSettings($routePath, arguments: $arguments)',
        );
        try {
          // 从小组件进入时，重置路由栈为两层：首页 + 目标页面
          navigator.pushNamedAndRemoveUntil('/', (route) => false);

          // 延迟一帧后再推入目标路由
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final route = AppRoutes.generateRoute(
              RouteSettings(name: routePath, arguments: arguments),
            );
            navigator.push(route);
            debugPrint('导航成功：路由栈现在有两层 (/ -> $routePath)');

            // 导航成功后清除初始URI状态
            AppStartupState.instance.clearInitialWidgetUri();
          });
        } catch (error, stack) {
          debugPrint('路由导航失败: $error');
          debugPrint('堆栈: $stack');

          // 导航失败时也清除状态
          AppStartupState.instance.clearInitialWidgetUri();
        }
      } else {
        debugPrint('导航器尚未初始化，延迟500ms后重试');
        Future.delayed(const Duration(milliseconds: 500), () {
          final retryNavigator = navigatorKey.currentState;
          if (retryNavigator != null) {
            try {
              retryNavigator.pushNamedAndRemoveUntil('/', (route) => false);

              WidgetsBinding.instance.addPostFrameCallback((_) {
                final route = AppRoutes.generateRoute(
                  RouteSettings(name: routePath, arguments: arguments),
                );
                retryNavigator.push(route);
                debugPrint('重试导航成功');

                // 导航成功后清除初始URI状态
                AppStartupState.instance.clearInitialWidgetUri();
              });
            } catch (e) {
              debugPrint('重试导航失败: $e');

              // 导航失败时也清除状态
              AppStartupState.instance.clearInitialWidgetUri();
            }
          } else {
            debugPrint('导航器初始化失败');

            // 失败时清除状态
            AppStartupState.instance.clearInitialWidgetUri();
          }
        });
      }
    });
  } catch (e, stack) {
    debugPrint('处理小组件点击失败: $e');
    debugPrint('堆栈: $stack');

    // 发生异常时清除状态
    AppStartupState.instance.clearInitialWidgetUri();
  }
}

/// 初始化悬浮球动作管理器
Future<void> _initializeFloatingBallActions() async {
  try {
    debugPrint('初始化悬浮球动作管理器...');
    final actionManager = ActionManager();
    await actionManager.initialize();
    debugPrint('悬浮球动作管理器初始化完成');
  } catch (e, stack) {
    debugPrint('悬浮球动作管理器初始化失败: $e');
    debugPrint('堆栈: $stack');
  }
}

/// 注册所有内置插件
Future<void> _registerPlugins() async {
  final plugins = BuiltinPlugins.createAll();

  await Future.wait(
    plugins.map((plugin) async {
      final isEnabled = globalConfigManager.isPluginEnabled(plugin.id);
      if (!isEnabled) {
        debugPrint('插件已禁用，跳过注册: ${plugin.id}');
        return;
      }
      try {
        await globalPluginManager.registerPlugin(plugin);
      } catch (e) {
        debugPrint('插件注册失败: ${plugin.id} - $e');
      }
    }),
  );
}

/// 保存的主题模式（公共变量，供其他模块使用）
AdaptiveThemeMode? savedThemeMode;

/// 全局导航键
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// 全局单例实例
late final StorageManager globalStorage;
late final ConfigManager globalConfigManager;
late final PluginManager globalPluginManager;
late final AppShortcutManager globalShortcutManager;

late PermissionController _permissionController;

/// 初始化并显示Flutter悬浮球（应用内Overlay）
/// 在应用启动完成后，导航器可用时调用
Future<void> initializeFlutterFloatingBall() async {
  try {
    debugPrint('初始化Flutter悬浮球...');

    // 等待一小段时间确保导航器已初始化
    await Future.delayed(const Duration(milliseconds: 100));

    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('导航器上下文未就绪，延迟重试');
      // 延迟一帧后重试
      WidgetsBinding.instance.addPostFrameCallback((_) {
        initializeFlutterFloatingBall();
      });
      return;
    }

    // 使用 addPostFrameCallback 确保 UI 完全构建后再显示浮动球
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // 再次检查上下文是否有效
        if (!context.mounted) {
          debugPrint('上下文已失效，跳过悬浮球初始化');
          return;
        }

        // 初始化悬浮球服务
        final floatingBallService = FloatingBallService();
        await floatingBallService.initialize(context);

        // 设置悬浮球动作上下文，使手势动作生效
        floatingBallService.manager.setActionContext(context);

        // 检查悬浮球是否启用，如果启用则显示
        final isEnabled = await floatingBallService.manager.isEnabled();
        if (isEnabled) {
          debugPrint('悬浮球已启用，显示悬浮球');
          await floatingBallService.show(context);
        } else {
          debugPrint('悬浮球未启用，跳过显示');
        }

        debugPrint('Flutter悬浮球初始化完成');
      } catch (e, stack) {
        debugPrint('Flutter悬浮球初始化失败: $e');
        debugPrint('堆栈: $stack');
      }
    });
  } catch (e, stack) {
    debugPrint('Flutter悬浮球初始化失败: $e');
    debugPrint('堆栈: $stack');
  }
}

/// 初始化 API 转发服务
/// 检查配置是否启用自动连接，如果是则启动服务
Future<void> _initializeApiForwardingService() async {
  try {
    final config = await ApiForwardingConfig.load();
    if (config.autoConnect && config.enabled && config.isValid) {
      debugPrint('[API转发] 检测到自动连接已启用，正在启动服务...');
      await ApiForwardingService.instance.start(config);
    } else {
      debugPrint('[API转发] 自动连接未启用或配置无效，跳过启动');
    }
  } catch (e) {
    debugPrint('[API转发] 自动启动失败: $e');
  }
}
