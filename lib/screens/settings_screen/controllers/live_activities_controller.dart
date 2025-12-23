import 'dart:async';
import 'package:flutter/material.dart';
import 'package:live_activities/live_activities.dart';
import 'package:live_activities/models/activity_update.dart';
import 'package:live_activities/models/url_scheme_data.dart';

// 导出必要的类型供外部使用
export 'package:live_activities/models/activity_update.dart';
export 'package:live_activities/models/url_scheme_data.dart';

/// Live Activities 控制器
///
/// 职责：
/// - 初始化 Live Activities 插件
/// - 提供静态方法供其他模块调用
/// - 管理活动的创建、更新、结束
/// - 监听活动状态变化
class LiveActivitiesController {
  // 单例模式
  static final LiveActivitiesController _instance =
      LiveActivitiesController._internal();

  factory LiveActivitiesController() => _instance;

  LiveActivitiesController._internal();

  // 核心实例
  final LiveActivities _plugin = LiveActivities();

  // 状态
  bool _isInitialized = false;
  bool _isSupported = false;

  // Streams
  StreamSubscription<ActivityUpdate>? _activityUpdateSubscription;
  StreamSubscription<UrlSchemeData>? _urlSchemeSubscription;

  /// 获取插件实例
  LiveActivities get plugin => _plugin;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 是否支持 Live Activities
  bool get isSupported => _isSupported;

  /// 初始化插件
  ///
  /// [appGroupId] - App Group ID (iOS必需)
  /// [urlScheme] - URL Scheme (可选)
  /// [requireNotificationPermission] - 是否需要通知权限 (默认true)
  /// [onActivityUpdate] - 活动状态变化回调
  /// [onUrlScheme] - URL Scheme回调
  Future<bool> init({
    required String appGroupId,
    String urlScheme = 'memento',
    bool requireNotificationPermission = true,
    Function(ActivityUpdate)? onActivityUpdate,
    Function(UrlSchemeData)? onUrlScheme,
  }) async {
    if (_isInitialized) {
      debugPrint('LiveActivitiesController 已初始化，跳过');
      return _isSupported;
    }

    try {
      // 初始化插件
      await _plugin.init(
        appGroupId: appGroupId,
        urlScheme: urlScheme,
        requireNotificationPermission: requireNotificationPermission,
      );

      // 检查设备支持
      _isSupported = await _plugin.areActivitiesEnabled();
      _isInitialized = true;

      debugPrint('LiveActivitiesController 初始化成功');
      debugPrint('设备支持状态: $_isSupported');

      // 设置监听器
      _setupListeners(
        onActivityUpdate: onActivityUpdate,
        onUrlScheme: onUrlScheme,
      );

      return _isSupported;
    } catch (e) {
      debugPrint('LiveActivitiesController 初始化失败: $e');
      _isInitialized = false;
      _isSupported = false;
      return false;
    }
  }

  /// 设置监听器
  void _setupListeners({
    Function(ActivityUpdate)? onActivityUpdate,
    Function(UrlSchemeData)? onUrlScheme,
  }) {
    // 监听活动更新
    _activityUpdateSubscription?.cancel();
    _activityUpdateSubscription = _plugin.activityUpdateStream.listen((event) {
      event.map(
        active: (activity) {
          debugPrint('活动激活: ${activity.activityId}');
          debugPrint('推送令牌: ${activity.activityToken}');
        },
        ended: (activity) {
          debugPrint('活动结束: ${activity.activityId}');
        },
        stale: (activity) {
          debugPrint('活动过期: ${activity.activityId}');
        },
        unknown: (activity) {
          debugPrint('未知活动状态: ${activity.activityId}');
        },
      );

      onActivityUpdate?.call(event);
    });

    // 监听 URL Scheme
    _urlSchemeSubscription?.cancel();
    _urlSchemeSubscription = _plugin.urlSchemeStream().listen((schemeData) {
      debugPrint('收到 URL Scheme: ${schemeData.url}');
      onUrlScheme?.call(schemeData);
    });
  }

  /// 创建活动
  ///
  /// [activityId] - 活动唯一标识
  /// [data] - 活动数据，必须包含 Swift ContentState 定义的字段
  ///
  /// 返回创建的活动ID，失败返回null
  Future<String?> createActivity(
    String activityId,
    Map<String, dynamic> data,
  ) async {
    if (!_isInitialized) {
      debugPrint('创建活动失败: 控制器未初始化');
      return null;
    }

    if (!_isSupported) {
      debugPrint('创建活动失败: 设备不支持 Live Activities');
      return null;
    }

    try {
      final id = await _plugin.createActivity(activityId, data);
      debugPrint('活动创建成功: $id');
      return id;
    } catch (e) {
      debugPrint('创建活动失败: $e');
      return null;
    }
  }

  /// 更新活动
  ///
  /// [activityId] - 活动ID
  /// [data] - 更新的数据
  Future<bool> updateActivity(
    String activityId,
    Map<String, dynamic> data,
  ) async {
    if (!_isInitialized) {
      debugPrint('更新活动失败: 控制器未初始化');
      return false;
    }

    try {
      await _plugin.updateActivity(activityId, data);
      debugPrint('活动更新成功: $activityId');
      return true;
    } catch (e) {
      debugPrint('更新活动失败: $e');
      return false;
    }
  }

  /// 结束活动
  ///
  /// [activityId] - 活动ID
  Future<bool> endActivity(String activityId) async {
    if (!_isInitialized) {
      debugPrint('结束活动失败: 控制器未初始化');
      return false;
    }

    try {
      await _plugin.endActivity(activityId);
      debugPrint('活动结束成功: $activityId');
      return true;
    } catch (e) {
      debugPrint('结束活动失败: $e');
      return false;
    }
  }

  /// 获取所有活动
  Future<List<String>> getAllActivities() async {
    if (!_isInitialized) {
      debugPrint('获取活动列表失败: 控制器未初始化');
      return [];
    }

    try {
      final activities = await _plugin.getAllActivitiesIds();
      debugPrint('当前活动数量: ${activities.length}');
      return activities;
    } catch (e) {
      debugPrint('获取活动列表失败: $e');
      return [];
    }
  }

  /// 结束所有活动
  Future<void> endAllActivities() async {
    if (!_isInitialized) {
      debugPrint('结束所有活动失败: 控制器未初始化');
      return;
    }

    try {
      await _plugin.endAllActivities();
      debugPrint('所有活动已结束');
    } catch (e) {
      debugPrint('结束所有活动失败: $e');
    }
  }

  /// 清理资源
  void dispose() {
    _activityUpdateSubscription?.cancel();
    _urlSchemeSubscription?.cancel();
    debugPrint('LiveActivitiesController 资源已释放');
  }

  // ============ 静态方法区 ============

  /// 全局实例访问
  static LiveActivitiesController get instance => _instance;

  /// 快速创建任务进度活动
  ///
  /// [title] - 任务标题
  /// [subtitle] - 任务副标题
  /// [progress] - 进度 (0.0-1.0)
  /// [status] - 状态文本
  static Future<String?> createTaskActivity({
    required String title,
    String subtitle = '',
    double progress = 0.0,
    String status = '准备开始',
  }) async {
    final activityId = 'task_${DateTime.now().millisecondsSinceEpoch}';

    final data = {
      'title': title,
      'subtitle': subtitle,
      'progress': progress,
      'status': status,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    return await _instance.createActivity(activityId, data);
  }

  /// 快速更新任务进度
  ///
  /// [activityId] - 活动ID
  /// [progress] - 新进度 (0.0-1.0)
  /// [status] - 新状态文本
  static Future<bool> updateTaskProgress(
    String activityId, {
    double? progress,
    String? status,
  }) async {
    // 先获取当前活动数据（这里简化处理，实际可能需要缓存）
    final data = <String, dynamic>{
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    if (progress != null) data['progress'] = progress;
    if (status != null) data['status'] = status;

    return await _instance.updateActivity(activityId, data);
  }

  /// 完成任务
  ///
  /// [activityId] - 活动ID
  static Future<bool> completeTask(String activityId) async {
    // 先更新为完成状态
    await updateTaskProgress(
      activityId,
      progress: 1.0,
      status: '任务完成',
    );

    // 延迟结束，让用户看到完成状态
    await Future.delayed(const Duration(seconds: 2));

    return await _instance.endActivity(activityId);
  }
}
