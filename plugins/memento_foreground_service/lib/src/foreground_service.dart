import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'foreground_service_config.dart';
import 'service_result.dart';

/// Memento 前台服务管理器
///
/// 封装 flutter_foreground_task，提供简洁的前台服务 API。
/// 用于管理前台服务的初始化、启动、停止和数据通信。
class MementoForegroundService {
  static final MementoForegroundService _instance =
      MementoForegroundService._internal();

  /// 单例实例
  static MementoForegroundService get instance => _instance;

  MementoForegroundService._internal();

  bool _isInitialized = false;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 初始化前台服务
  ///
  /// [config] 服务配置，如果不传则使用默认配置
  ///
  /// 此方法会自动请求必要的权限（通知权限、电池优化豁免、精确闹钟权限）
  Future<void> initialize({ForegroundServiceConfig? config}) async {
    if (_isInitialized) return;

    final cfg = config ?? const ForegroundServiceConfig();

    // 初始化通信端口
    FlutterForegroundTask.initCommunicationPort();

    // 请求必要的权限
    await _requestPermissions();

    // 初始化服务配置
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: cfg.channelId,
        channelName: cfg.channelName,
        channelDescription: cfg.channelDescription,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: IOSNotificationOptions(
        showNotification: cfg.iosShowNotification,
        playSound: cfg.iosPlaySound,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(cfg.eventIntervalMs),
        autoRunOnBoot: cfg.autoRunOnBoot,
        autoRunOnMyPackageReplaced: cfg.autoRunOnMyPackageReplaced,
        allowWakeLock: cfg.allowWakeLock,
        allowWifiLock: cfg.allowWifiLock,
      ),
    );

    _isInitialized = true;
    debugPrint('[MementoForegroundService] 初始化完成');
  }

  /// 请求必要的权限
  Future<void> _requestPermissions() async {
    // 请求通知权限
    final notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    // Android 特定权限
    if (Platform.isAndroid) {
      // 请求电池优化豁免
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }

      // 请求精确闹钟权限
      if (!await FlutterForegroundTask.canScheduleExactAlarms) {
        await FlutterForegroundTask.openAlarmsAndRemindersSettings();
      }
    }
  }

  /// 启动前台服务
  ///
  /// [serviceId] 服务唯一标识
  /// [notificationTitle] 通知标题
  /// [notificationText] 通知内容
  /// [notificationIcon] 通知图标元数据名称
  /// [notificationButtons] 通知按钮列表
  /// [notificationInitialRoute] 点击通知时的初始路由
  /// [callback] 前台任务回调
  Future<ServiceResult> startService({
    required int serviceId,
    required String notificationTitle,
    required String notificationText,
    String? notificationIcon,
    List<ServiceNotificationButton>? notificationButtons,
    String? notificationInitialRoute,
    required Function() callback,
  }) async {
    try {
      if (await isRunning) {
        await FlutterForegroundTask.restartService();
        return ServiceResult.success();
      }

      // 转换按钮配置
      final buttons = notificationButtons
          ?.map((b) => NotificationButton(id: b.key, text: b.label))
          .toList();

      await FlutterForegroundTask.startService(
        serviceId: serviceId,
        notificationIcon: notificationIcon != null
            ? NotificationIcon(metaDataName: notificationIcon)
            : null,
        notificationButtons: buttons,
        notificationTitle: notificationTitle,
        notificationText: notificationText,
        notificationInitialRoute: notificationInitialRoute,
        callback: callback,
      );

      return ServiceResult.success();
    } catch (e) {
      return ServiceResult.failure('启动服务异常: $e');
    }
  }

  /// 停止前台服务
  Future<ServiceResult> stopService() async {
    try {
      await FlutterForegroundTask.stopService();
      return ServiceResult.success();
    } catch (e) {
      return ServiceResult.failure('停止服务异常: $e');
    }
  }

  /// 更新通知内容
  Future<void> updateNotification({
    required String title,
    required String text,
  }) async {
    await FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: text,
    );
  }

  /// 检查服务是否正在运行
  Future<bool> get isRunning => FlutterForegroundTask.isRunningService;

  /// 添加数据回调
  void addDataCallback(Function(Object) callback) {
    FlutterForegroundTask.addTaskDataCallback(callback);
  }

  /// 移除数据回调
  void removeDataCallback(Function(Object) callback) {
    FlutterForegroundTask.removeTaskDataCallback(callback);
  }

  /// 发送数据到前台任务
  void sendDataToTask(Object data) {
    FlutterForegroundTask.sendDataToTask(data);
  }

  /// 检查通知权限
  Future<bool> checkNotificationPermission() async {
    final permission = await FlutterForegroundTask.checkNotificationPermission();
    return permission == NotificationPermission.granted;
  }

  /// 请求通知权限
  Future<bool> requestNotificationPermission() async {
    final permission = await FlutterForegroundTask.requestNotificationPermission();
    return permission == NotificationPermission.granted;
  }

  /// 检查是否忽略电池优化
  Future<bool> get isIgnoringBatteryOptimizations =>
      FlutterForegroundTask.isIgnoringBatteryOptimizations;

  /// 请求忽略电池优化
  Future<bool> requestIgnoreBatteryOptimization() =>
      FlutterForegroundTask.requestIgnoreBatteryOptimization();

  /// 检查是否可以调度精确闹钟
  Future<bool> get canScheduleExactAlarms =>
      FlutterForegroundTask.canScheduleExactAlarms;

  /// 打开闹钟和提醒设置
  Future<bool> openAlarmsAndRemindersSettings() =>
      FlutterForegroundTask.openAlarmsAndRemindersSettings();
}
