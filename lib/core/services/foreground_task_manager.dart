import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class ForegroundTaskManager {
  static final ForegroundTaskManager _instance =
      ForegroundTaskManager._internal();

  factory ForegroundTaskManager() => _instance;

  ForegroundTaskManager._internal() {
    initCommunicationPort();
    requestPermissions();
    initService();
  }

  // 初始化通信端口
  void initCommunicationPort() {
    FlutterForegroundTask.initCommunicationPort();
  }

  // 请求必要的权限
  Future<void> requestPermissions() async {
    final notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (Platform.isAndroid) {
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }

      if (!await FlutterForegroundTask.canScheduleExactAlarms) {
        await FlutterForegroundTask.openAlarmsAndRemindersSettings();
      }
    }
  }

  // 初始化服务配置
  void initService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  // 启动前台服务
  Future<ServiceRequestResult> startService({
    required int serviceId,
    String? notificationIcon,
    List<NotificationButton>? notificationButtons,
    required String notificationTitle,
    required String notificationText,
    required Function() callback,
    String? notificationInitialRoute,
  }) async {
    if (await isServiceRunning()) {
      return FlutterForegroundTask.restartService();
    }

    return FlutterForegroundTask.startService(
      serviceId: serviceId,
      notificationIcon: const NotificationIcon(
        metaDataName: 'github.hunmer.memento.service.APP_ICON',
        // backgroundColor: Colors.orange,
      ),
      notificationButtons: notificationButtons,
      notificationTitle: notificationTitle,
      notificationText: notificationText,
      notificationInitialRoute: notificationInitialRoute,
      callback: callback,
    );
  }

  // 停止前台服务
  Future<ServiceRequestResult> stopService() {
    return FlutterForegroundTask.stopService();
  }

  // 检查服务是否正在运行
  Future<bool> isServiceRunning() {
    return FlutterForegroundTask.isRunningService;
  }

  // 添加数据回调
  void addDataCallback(Function(Object) callback) {
    FlutterForegroundTask.addTaskDataCallback(callback);
  }

  // 移除数据回调
  void removeDataCallback(Function(Object) callback) {
    FlutterForegroundTask.removeTaskDataCallback(callback);
  }
}
