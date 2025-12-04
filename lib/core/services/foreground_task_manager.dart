import 'package:memento_foreground_service/memento_foreground_service.dart';

/// 前台任务管理器 - 使用 memento_foreground_service 插件
///
/// 这是对 memento_foreground_service 插件的薄封装层，
/// 保持与原有 API 的兼容性。
class ForegroundTaskManager {
  static final ForegroundTaskManager _instance =
      ForegroundTaskManager._internal();

  factory ForegroundTaskManager() => _instance;

  ForegroundTaskManager._internal() {
    _initialize();
  }

  Future<void> _initialize() async {
    await MementoForegroundService.instance.initialize();
  }

  /// 启动前台服务
  Future<ServiceResult> startService({
    required int serviceId,
    String? notificationIcon,
    List<ServiceNotificationButton>? notificationButtons,
    required String notificationTitle,
    required String notificationText,
    required Function() callback,
    String? notificationInitialRoute,
  }) async {
    return await MementoForegroundService.instance.startService(
      serviceId: serviceId,
      notificationTitle: notificationTitle,
      notificationText: notificationText,
      notificationIcon: notificationIcon ?? 'github.hunmer.memento.service.APP_ICON',
      notificationButtons: notificationButtons,
      notificationInitialRoute: notificationInitialRoute,
      callback: callback,
    );
  }

  /// 停止前台服务
  Future<ServiceResult> stopService() {
    return MementoForegroundService.instance.stopService();
  }

  /// 检查服务是否正在运行
  Future<bool> isServiceRunning() {
    return MementoForegroundService.instance.isRunning;
  }

  /// 添加数据回调
  void addDataCallback(Function(Object) callback) {
    MementoForegroundService.instance.addDataCallback(callback);
  }

  /// 移除数据回调
  void removeDataCallback(Function(Object) callback) {
    MementoForegroundService.instance.removeDataCallback(callback);
  }
}
