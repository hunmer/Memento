import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/activity_record.dart';
import '../services/activity_service.dart';
import 'package:Memento/plugins/tts/tts_plugin.dart';

/// 活动后台播报服务
///
/// 当检测到未记录时间超过指定间隔时，播报提示语音
/// 支持占位符：{date}, {last_activity}, {unrecorded_time}
class ActivityTTSAnnouncementService extends ChangeNotifier {
  /// 活动服务
  final ActivityService activityService;

  /// TTS 插件
  final TTSPlugin ttsPlugin;

  /// 定时检查器
  Timer? _checkTimer;

  /// 是否正在运行
  bool _isActive = false;

  /// 使用的 TTS 服务 ID
  String? _serviceId;

  /// 未记录时间间隔（分钟）
  int _unrecordedIntervalMinutes = 5;

  /// 播报文本模板
  String _textTemplate = '已超过 {unrecorded_time} 未记录活动';

  /// 是否只在工作时间检查
  bool _checkOnlyWorkHours = false;

  /// 工作时间开始（小时）
  int _workHoursStart = 9;

  /// 工作时间结束（小时）
  int _workHoursEnd = 18;

  /// 是否启用震动反馈
  bool _enableHapticFeedback = true;

  /// 最近一次检查时间
  DateTime? _lastCheckTime;

  /// 最后一次播报时间
  DateTime? _lastAnnouncementTime;

  /// 最近的活动记录
  ActivityRecord? _lastActivity;

  /// 是否正在运行
  bool get isActive => _isActive;

  /// 使用的 TTS 服务 ID
  String? get serviceId => _serviceId;

  /// 未记录时间间隔（分钟）
  int get unrecordedIntervalMinutes => _unrecordedIntervalMinutes;

  /// 播报文本模板
  String get textTemplate => _textTemplate;

  /// 是否只在工作时间检查
  bool get checkOnlyWorkHours => _checkOnlyWorkHours;

  /// 工作时间开始（小时）
  int get workHoursStart => _workHoursStart;

  /// 工作时间结束（小时）
  int get workHoursEnd => _workHoursEnd;

  /// 是否启用震动反馈
  bool get enableHapticFeedback => _enableHapticFeedback;

  /// 最近一次检查时间
  DateTime? get lastCheckTime => _lastCheckTime;

  /// 最后一次播报时间
  DateTime? get lastAnnouncementTime => _lastAnnouncementTime;

  /// 最近的未记录时间（分钟）
  int? get unrecordedMinutes {
    if (_lastActivity == null) return null;
    final now = DateTime.now();
    return now.difference(_lastActivity!.endTime).inMinutes;
  }

  ActivityTTSAnnouncementService({
    required this.activityService,
    required this.ttsPlugin,
  });

  /// 启动播报服务
  Future<void> start() async {
    if (_isActive) {
      debugPrint('[ActivityTTSAnnouncement] 服务已在运行');
      return;
    }

    _isActive = true;
    _lastCheckTime = DateTime.now();

    // 启动定时检查器（每分钟检查一次）
    _checkTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkAndAnnounce(),
    );

    debugPrint('[ActivityTTSAnnouncement] 服务已启动');
    notifyListeners();
  }

  /// 停止播报服务
  Future<void> stop() async {
    if (!_isActive) return;

    _isActive = false;
    _checkTimer?.cancel();
    _checkTimer = null;

    // 停止当前的 TTS 播放
    try {
      await ttsPlugin.stop();
    } catch (e) {
      debugPrint('[ActivityTTSAnnouncement] 停止 TTS 失败: $e');
    }

    debugPrint('[ActivityTTSAnnouncement] 服务已停止');
    notifyListeners();
  }

  /// 检查并播报
  Future<void> _checkAndAnnounce() async {
    if (!_isActive) return;

    _lastCheckTime = DateTime.now();

    try {
      // 检查是否在工作时间内（如果启用了工作时间限制）
      if (_checkOnlyWorkHours && !_isWorkHours()) {
        debugPrint('[ActivityTTSAnnouncement] 非工作时间，跳过检查');
        return;
      }

      // 获取最近的活动
      await _updateLastActivity();

      // 计算未记录时间（如果没有活动，从今天 0 点开始计算）
      final now = DateTime.now();
      final unrecordedMins =
          _lastActivity == null
              ? now.difference(DateTime(now.year, now.month, now.day)).inMinutes
              : now.difference(_lastActivity!.endTime).inMinutes;

      // 检查是否超过设定间隔
      if (unrecordedMins >= _unrecordedIntervalMinutes) {
        // 替换占位符并播报
        final text = _replacePlaceholders(_textTemplate);
        await _speak(text);

        _lastAnnouncementTime = DateTime.now();
        debugPrint('[ActivityTTSAnnouncement] 播报: $text');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ActivityTTSAnnouncement] 检查失败: $e');
    }
  }

  /// 更新最近的活动记录
  Future<void> _updateLastActivity() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final activities = await activityService.getActivitiesForDate(today);

      if (activities.isNotEmpty) {
        // 按结束时间排序，取最新的
        activities.sort((a, b) => b.endTime.compareTo(a.endTime));
        _lastActivity = activities.first;
      } else {
        // 如果今天没有活动，检查昨天
        final yesterday = today.subtract(const Duration(days: 1));
        final yesterdayActivities = await activityService.getActivitiesForDate(
          yesterday,
        );
        if (yesterdayActivities.isNotEmpty) {
          yesterdayActivities.sort((a, b) => b.endTime.compareTo(a.endTime));
          _lastActivity = yesterdayActivities.first;
        }
      }
    } catch (e) {
      debugPrint('[ActivityTTSAnnouncement] 获取最近活动失败: $e');
    }
  }

  /// 替换文本中的占位符
  String _replacePlaceholders(String template) {
    final now = DateTime.now();
    String result = template;

    // {date} - 当前日期
    result = result.replaceAll('{date}', DateFormat('yyyy年MM月dd日').format(now));

    // {last_activity} - 最近的活动标题或标签
    if (_lastActivity != null) {
      // 如果有标签，优先显示标签
      if (_lastActivity!.tags.isNotEmpty) {
        final tagsStr = _lastActivity!.tags.join('、');
        result = result.replaceAll('{last_activity}', tagsStr);
      } else {
        // 没有标签，显示标题
        result = result.replaceAll('{last_activity}', _lastActivity!.title);
      }
    } else {
      result = result.replaceAll('{last_activity}', '无');
    }

    // {unrecorded_time} - 未记录时间（实时计算，显示小时制）
    String unrecordedTimeStr = _formatDuration(_lastActivity);
    result = result.replaceAll('{unrecorded_time}', unrecordedTimeStr);

    // {time} - 当前时间
    result = result.replaceAll('{time}', DateFormat('HH:mm').format(now));

    // {weekday} - 星期
    final weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    result = result.replaceAll('{weekday}', weekDays[now.weekday - 1]);

    return result;
  }

  /// 格式化时长为小时制文本
  ///
  /// 如果没有活动，从今天 0 点开始计算
  String _formatDuration(ActivityRecord? activity) {
    final now = DateTime.now();
    int minutes;

    if (activity == null) {
      // 没有活动，从今天 0 点开始计算
      final todayStart = DateTime(now.year, now.month, now.day);
      minutes = now.difference(todayStart).inMinutes;
    } else {
      // 有活动，从活动结束时间开始计算
      minutes = now.difference(activity.endTime).inMinutes;
    }

    // 格式化为小时制
    if (minutes < 60) {
      return '$minutes 分钟';
    } else if (minutes < 60 * 24) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins > 0) {
        return '$hours 小时 $mins 分钟';
      } else {
        return '$hours 小时';
      }
    } else {
      final days = minutes ~/ (60 * 24);
      final hours = (minutes % (60 * 24)) ~/ 60;
      if (hours > 0) {
        return '$days 天 $hours 小时';
      } else {
        return '$days 天';
      }
    }
  }

  /// 执行播报
  Future<void> _speak(String text) async {
    try {
      // 震动反馈
      if (_enableHapticFeedback) {
        HapticFeedback.heavyImpact();
      }
      await ttsPlugin.speak(text, serviceId: _serviceId);
    } catch (e) {
      debugPrint('[ActivityTTSAnnouncement] 播报失败: $e');
    }
  }

  /// 更新配置
  Future<void> updateConfig({
    String? serviceId,
    int? unrecordedIntervalMinutes,
    String? textTemplate,
    bool? checkOnlyWorkHours,
    int? workHoursStart,
    int? workHoursEnd,
    bool? enableHapticFeedback,
  }) async {
    bool needRestart = false;

    if (serviceId != null && serviceId != _serviceId) {
      _serviceId = serviceId;
      needRestart = true;
    }

    if (unrecordedIntervalMinutes != null &&
        unrecordedIntervalMinutes != _unrecordedIntervalMinutes) {
      _unrecordedIntervalMinutes = unrecordedIntervalMinutes;
      needRestart = true;
    }

    if (textTemplate != null && textTemplate != _textTemplate) {
      _textTemplate = textTemplate;
    }

    if (checkOnlyWorkHours != null &&
        checkOnlyWorkHours != _checkOnlyWorkHours) {
      _checkOnlyWorkHours = checkOnlyWorkHours;
      needRestart = true;
    }

    if (workHoursStart != null && workHoursStart != _workHoursStart) {
      _workHoursStart = workHoursStart;
      needRestart = true;
    }

    if (workHoursEnd != null && workHoursEnd != _workHoursEnd) {
      _workHoursEnd = workHoursEnd;
      needRestart = true;
    }

    if (enableHapticFeedback != null &&
        enableHapticFeedback != _enableHapticFeedback) {
      _enableHapticFeedback = enableHapticFeedback;
    }

    if (needRestart && _isActive) {
      // 重启服务
      await stop();
      await start();
    }

    notifyListeners();
  }

  /// 手动刷新最近活动
  Future<void> refreshLastActivity() async {
    await _updateLastActivity();
    notifyListeners();
  }

  /// 测试播报一次
  Future<void> testSpeak() async {
    try {
      // 先刷新最近活动
      await _updateLastActivity();

      final text = _replacePlaceholders(_textTemplate);
      await _speak(text);
      debugPrint('[ActivityTTSAnnouncement] 测试播报: $text');
    } catch (e) {
      debugPrint('[ActivityTTSAnnouncement] 测试播报失败: $e');
      rethrow;
    }
  }

  /// 检查当前是否在工作时间内
  bool _isWorkHours() {
    final now = DateTime.now();
    final currentHour = now.hour;

    return currentHour >= _workHoursStart && currentHour < _workHoursEnd;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
