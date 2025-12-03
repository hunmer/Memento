import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:adaptive_theme/adaptive_theme.dart';

import '../core/notification_controller.dart';
import '../core/storage/storage_manager.dart';
import '../core/config_manager.dart';
import '../core/plugin_manager.dart';
import '../core/services/shortcut_manager.dart';
import '../core/js_bridge/js_bridge_manager.dart';
import '../core/route/route_history_manager.dart';
import '../core/services/system_widget_service.dart';
import '../core/services/plugin_widget_sync_helper.dart';
import '../utils/image_utils.dart';
import '../plugins/chat/chat_plugin.dart';
import '../plugins/diary/diary_plugin.dart';
import '../plugins/activity/activity_plugin.dart';
import '../plugins/checkin/checkin_plugin.dart';
import '../plugins/timer/timer_plugin.dart';
import '../plugins/todo/todo_plugin.dart';
import '../plugins/day/day_plugin.dart';
import '../plugins/nodes/nodes_plugin.dart';
import '../plugins/notes/notes_plugin.dart';
import '../plugins/goods/goods_plugin.dart';
import '../plugins/bill/bill_plugin.dart';
import '../plugins/calendar/calendar_plugin.dart';
import '../plugins/openai/openai_plugin.dart';
import '../plugins/store/store_plugin.dart';
import '../plugins/tracker/tracker_plugin.dart';
import '../plugins/database/database_plugin.dart';
import '../plugins/scripts_center/scripts_center_plugin.dart';
import '../plugins/agent_chat/agent_chat_plugin.dart';
import '../plugins/tts/tts_plugin.dart';
import '../plugins/habits/habits_plugin.dart';
import '../plugins/contact/contact_plugin.dart';
import '../plugins/calendar_album/calendar_album_plugin.dart';
import '../screens/settings_screen/controllers/auto_update_controller.dart';
import '../screens/settings_screen/controllers/permission_controller.dart';
import '../core/event/event.dart';
import 'app_widgets/home_widget_service.dart';
import 'app_widgets/floating_ball_service.dart';

/// 应用初始化函数
/// 负责应用启动前的所有准备工作
Future<void> initializeApp() async {
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
    debugPrint(
      '[${record.level.name}] ${record.loggerName}: ${record.message}',
    );
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

  savedThemeMode = await AdaptiveTheme.getThemeMode();

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
    await initializeHomeWidgets();
    final updateController = AutoUpdateController.instance;
    updateController.initialize();

    // 设置桌面小组件点击监听器
    await setupWidgetClickListener();

    // 初始化系统桌面小组件服务并同步数据
    await SystemWidgetService.instance.initialize();
    await PluginWidgetSyncHelper.instance.syncAllPlugins();

    // 恢复悬浮球状态（在权限检查之前）
    await restoreFloatingBallState();

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

      // 同步待处理的小组件任务变更（用户在小组件上完成的任务）
      await PluginWidgetSyncHelper.instance.syncPendingTaskChangesOnStartup();
      // 同步待处理的小组件目标变更（用户在小组件上增减的进度）
      await PluginWidgetSyncHelper.instance.syncPendingGoalChangesOnStartup();
      // 同步待处理的习惯计时器变更（用户在小组件上完成的计时）
      await PluginWidgetSyncHelper.instance
          .syncPendingHabitTimerChangesOnStartup();
    });
  } catch (e) {
    debugPrint('初始化失败: $e');
  }
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
