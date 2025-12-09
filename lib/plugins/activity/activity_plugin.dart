import 'dart:convert';

import 'package:Memento/core/app_initializer.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:Memento/plugins/base_plugin.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/event/event.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'l10n/activity_localizations.dart';
import 'screens/activity_timeline_screen/activity_timeline_screen.dart';
import 'screens/activity_timeline_screen/controllers/activity_controller.dart';
import 'screens/activity_statistics_screen.dart';
import 'screens/activity_edit_screen.dart';
import 'screens/activity_settings_screen.dart';
import 'services/activity_service.dart';
import 'services/activity_notification_service.dart';
import 'models/activity_record.dart';
import 'dart:io';

class ActivityPlugin extends BasePlugin with JSBridgePlugin {
  static ActivityPlugin? _instance;
  static ActivityPlugin get instance {
    if (_instance == null) {
      _instance =
          PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
      if (_instance == null) {
        throw StateError('ActivityPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  @override
  String? getPluginName(context) {
    return ActivityLocalizations.of(context).name;
  }

  late ActivityService _activityService;
  late ActivityNotificationService _notificationService;
  bool _isInitialized = false;

  // 缓存今日统计数据（用于同步访问）
  int _cachedTodayActivityCount = 0;
  int _cachedTodayActivityDuration = 0;
  DateTime? _cacheDate;

  // 获取活动服务实例
  ActivityService get activityService {
    if (!_isInitialized) {
      throw StateError('ActivityPlugin has not been initialized');
    }
    return _activityService;
  }

  // 获取通知服务实例
  ActivityNotificationService get notificationService {
    if (!_isInitialized) {
      throw StateError('ActivityPlugin has not been initialized');
    }
    return _notificationService;
  }

  @override
  final String id = 'activity';

  @override
  Color get color => Colors.pink;

  @override
  IconData get icon => Icons.timeline;

  @override
  Future<void> registerToApp(
    
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 初始化插件
    // 插件已在 initialize() 中完成初始化
    // 这里可以添加额外的应用级注册逻辑

    // 监听通知点击事件
    eventManager.subscribe(
      'activity_notification_tapped',
      _handleNotificationTapped,
    );
  }

  /// 处理通知点击事件
  void _handleNotificationTapped(EventArgs args) {
    debugPrint('[ActivityPlugin] 收到通知点击事件，正在打开活动编辑界面...');

    // 使用全局导航器打开活动编辑界面
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      navigator.push(NavigationHelper.createRoute(ActivityEditScreen(
                activityService: activityService,
                selectedDate: DateTime.now(),
              ),
        ),
      );
      debugPrint('[ActivityPlugin] 活动编辑界面已打开');
    } else {
      debugPrint('[ActivityPlugin] 导航器未初始化，无法打开界面');
    }
  }

  @override
  Future<void> initialize() async {
    // 确保活动记录数据目录存在
    await storage.createDirectory('activity');
    _activityService = ActivityService(storage, 'activity');

    // 初始化通知服务
    _notificationService = ActivityNotificationService(_activityService);
    await _notificationService.initialize();

    _isInitialized = true;

    // 自动恢复通知栏显示（如果之前是开启的）
    try {
      final settings = await storage.read(
        'activity/notification_settings.json',
      );
      if (settings.isNotEmpty && settings['isEnabled'] == true) {
        debugPrint('[ActivityPlugin] 检测到之前开启了通知栏显示，正在自动恢复...');
        await enableActivityNotification();
      }
    } catch (e) {
      debugPrint('[ActivityPlugin] 恢复通知栏显示失败: $e');
    }

    // 注册 JS API
    await registerJSAPI();
  }

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 活动查询
      'getActivities': _jsGetActivities,

      // 活动管理
      'createActivity': _jsCreateActivity,
      'updateActivity': _jsUpdateActivity,
      'deleteActivity': _jsDeleteActivity,

      // 统计信息
      'getTodayStats': _jsGetTodayStats,

      // 标签管理
      'getTagGroups': _jsGetTagGroups,
      'getRecentTags': _jsGetRecentTags,

      // 通知管理
      'enableNotification': _jsEnableNotification,
      'disableNotification': _jsDisableNotification,
      'getNotificationStatus': _jsGetNotificationStatus,
    };
  }

  // ==================== 分页控制器 ====================

  /// 分页控制器 - 对列表进行分页处理
  /// @param list 原始数据列表
  /// @param offset 起始位置（默认 0）
  /// @param count 返回数量（默认 100）
  /// @return 分页后的数据，包含 data、total、offset、count、hasMore
  Map<String, dynamic> _paginate<T>(
    List<T> list, {
    int offset = 0,
    int count = 100,
  }) {
    final total = list.length;
    final start = offset.clamp(0, total);
    final end = (start + count).clamp(start, total);
    final data = list.sublist(start, end);

    return {
      'data': data,
      'total': total,
      'offset': start,
      'count': data.length,
      'hasMore': end < total,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取指定日期的活动列表
  /// 参数: params - { date?: string, offset?: number, count?: number } (YYYY-MM-DD 格式, 默认今天)
  /// 支持分页参数: offset, count
  Future<String> _jsGetActivities(Map<String, dynamic> params) async {
    try {
      final dateStr = params['date'] as String?;
      final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
      final activities = await _activityService.getActivitiesForDate(date);
      final activitiesJson = activities.map((a) => a.toJson()).toList();

      // 检查是否需要分页
      final int? offset = params['offset'];
      final int? count = params['count'];

      if (offset != null || count != null) {
        final paginated = _paginate(
          activitiesJson,
          offset: offset ?? 0,
          count: count ?? 100,
        );
        return jsonEncode(paginated);
      }

      // 兼容旧版本：无分页参数时返回全部数据
      return jsonEncode(activitiesJson);
    } catch (e) {
      return jsonEncode({'error': '获取活动失败: $e'});
    }
  }

  /// 创建活动
  /// 参数: params - {
  ///   startTime: string (必需, ISO 8601 格式),
  ///   endTime: string (必需, ISO 8601 格式),
  ///   title: string (必需),
  ///   id: string (可选, 自定义ID),
  ///   tags?: Array 或 string,
  ///   description?: string,
  ///   mood?: string
  /// }
  Future<String> _jsCreateActivity(Map<String, dynamic> params) async {
    try {
      // 验证必需参数
      if (!params.containsKey('startTime') ||
          !params.containsKey('endTime') ||
          !params.containsKey('title')) {
        return jsonEncode({
          'success': false,
          'error': '缺少必需参数: startTime, endTime, title',
        });
      }

      final startTimeStr = params['startTime'] as String;
      final endTimeStr = params['endTime'] as String;
      final title = params['title'] as String;
      final String? id = params['id'] as String?;

      final startTime = DateTime.parse(startTimeStr);
      final endTime = DateTime.parse(endTimeStr);

      // 检查自定义ID是否已存在
      if (id != null && id.isNotEmpty) {
        final activities = await _activityService.getActivitiesForDate(
          startTime,
        );
        final existingActivity =
            activities.where((a) => a.id == id).firstOrNull;
        if (existingActivity != null) {
          return jsonEncode({'success': false, 'error': '活动ID已存在: $id'});
        }
      }

      // 解析标签
      final List<String> tags =
          params['tags'] != null ? List<String>.from(params['tags']) : [];

      final description = params['description'] as String?;
      final mood = params['mood'] as String?;

      final activity = ActivityRecord(
        id: (id != null && id.isNotEmpty) ? id : null,
        startTime: startTime,
        endTime: endTime,
        title: title,
        tags: tags,
        description: description,
        mood: mood,
      );

      await _activityService.saveActivity(activity);
      return jsonEncode({'success': true, 'activity': activity.toJson()});
    } catch (e) {
      return jsonEncode({'success': false, 'error': '创建活动失败: $e'});
    }
  }

  /// 更新活动
  /// 参数: params - {
  ///   activityId: string (必需),
  ///   startTime: string (必需, ISO 8601 格式),
  ///   endTime: string (必需, ISO 8601 格式),
  ///   title: string (必需),
  ///   tags?: List or string,
  ///   description?: string,
  ///   mood?: string
  /// }
  Future<String> _jsUpdateActivity(Map<String, dynamic> params) async {
    try {
      // 验证必需参数
      if (!params.containsKey('activityId') ||
          !params.containsKey('startTime') ||
          !params.containsKey('endTime') ||
          !params.containsKey('title')) {
        return jsonEncode({
          'success': false,
          'error': '缺少必需参数: activityId, startTime, endTime, title',
        });
      }

      final activityId = params['activityId'] as String;
      final startTimeStr = params['startTime'] as String;
      final endTimeStr = params['endTime'] as String;
      final title = params['title'] as String;

      final startTime = DateTime.parse(startTimeStr);
      final endTime = DateTime.parse(endTimeStr);

      // 解析标签
      final List<String> tags =
          params['tags'] != null ? List<String>.from(params['tags']) : [];

      final description = params['description'] as String?;
      final mood = params['mood'] as String?;

      // 查找旧活动
      final activities = await _activityService.getActivitiesForDate(startTime);
      final oldActivity = activities.firstWhere(
        (a) => a.id == activityId,
        orElse: () => throw Exception('未找到活动 ID: $activityId'),
      );

      // 创建新活动
      final newActivity = ActivityRecord(
        id: activityId,
        startTime: startTime,
        endTime: endTime,
        title: title,
        tags: tags,
        description: description,
        mood: mood,
      );

      await _activityService.updateActivity(oldActivity, newActivity);
      return jsonEncode({'success': true, 'activity': newActivity.toJson()});
    } catch (e) {
      return jsonEncode({'success': false, 'error': '更新活动失败: $e'});
    }
  }

  /// 删除活动
  /// 参数: params - {
  ///   activityId: string (必需),
  ///   date: string (必需, YYYY-MM-DD 格式)
  /// }
  Future<String> _jsDeleteActivity(Map<String, dynamic> params) async {
    try {
      // 验证必需参数
      if (!params.containsKey('activityId') || !params.containsKey('date')) {
        return jsonEncode({
          'success': false,
          'error': '缺少必需参数: activityId, date',
        });
      }

      final activityId = params['activityId'] as String;
      final dateStr = params['date'] as String;

      final date = DateTime.parse(dateStr);
      final activities = await _activityService.getActivitiesForDate(date);

      final activity = activities.firstWhere(
        (a) => a.id == activityId,
        orElse: () => throw Exception('未找到活动 ID: $activityId'),
      );

      await _activityService.deleteActivity(activity);
      return jsonEncode({'success': true});
    } catch (e) {
      return jsonEncode({'success': false, 'error': '删除活动失败: $e'});
    }
  }

  /// 获取今日统计
  /// 参数: params - {} (无需参数)
  /// 返回: { activityCount, durationMinutes, durationHours, remainingMinutes, remainingHours }
  Future<String> _jsGetTodayStats(Map<String, dynamic> params) async {
    try {
      final activityCount = await getTodayActivityCount();
      final durationMinutes = await getTodayActivityDuration();
      final remainingMinutes = getTodayRemainingTime();

      return jsonEncode({
        'activityCount': activityCount,
        'durationMinutes': durationMinutes,
        'durationHours': (durationMinutes / 60).toStringAsFixed(1),
        'remainingMinutes': remainingMinutes,
        'remainingHours': (remainingMinutes / 60).toStringAsFixed(1),
      });
    } catch (e) {
      return jsonEncode({'error': '获取统计失败: $e'});
    }
  }

  /// 获取标签分组
  /// 参数: params - {} (无需参数)
  Future<String> _jsGetTagGroups(Map<String, dynamic> params) async {
    try {
      final tagGroups = await _activityService.getTagGroups();
      return jsonEncode(
        tagGroups.map((g) => {'name': g.name, 'tags': g.tags}).toList(),
      );
    } catch (e) {
      return jsonEncode({'error': '获取标签分组失败: $e'});
    }
  }

  /// 获取最近使用的标签
  /// 参数: params - {} (无需参数)
  Future<String> _jsGetRecentTags(Map<String, dynamic> params) async {
    try {
      final recentTags = await _activityService.getRecentTags();
      return jsonEncode(recentTags);
    } catch (e) {
      return jsonEncode({'error': '获取最近标签失败: $e'});
    }
  }

  // ==================== 通知相关 API ====================

  /// 启用活动通知
  /// 参数: params - {} (无需参数)
  Future<String> _jsEnableNotification(Map<String, dynamic> params) async {
    try {
      if (!Platform.isAndroid) {
        return jsonEncode({'success': false, 'error': '仅支持Android平台'});
      }

      await _notificationService.enable();
      return jsonEncode({'success': true, 'message': '活动通知已启用'});
    } catch (e) {
      return jsonEncode({'success': false, 'error': '启用通知失败: $e'});
    }
  }

  /// 禁用活动通知
  /// 参数: params - {} (无需参数)
  Future<String> _jsDisableNotification(Map<String, dynamic> params) async {
    try {
      await _notificationService.disable();
      return jsonEncode({'success': true, 'message': '活动通知已禁用'});
    } catch (e) {
      return jsonEncode({'success': false, 'error': '禁用通知失败: $e'});
    }
  }

  /// 获取通知状态
  /// 参数: params - {} (无需参数)
  Future<String> _jsGetNotificationStatus(Map<String, dynamic> params) async {
    try {
      final stats = _notificationService.getStats();
      return jsonEncode({'success': true, 'status': stats});
    } catch (e) {
      return jsonEncode({'success': false, 'error': '获取通知状态失败: $e'});
    }
  }

  // 获取今日活动数
  Future<int> getTodayActivityCount() async {
    if (!_isInitialized) return 0;
    final now = DateTime.now();
    final activities = await _activityService.getActivitiesForDate(now);

    // 更新缓存
    _updateCache(now, activities.length, null);

    return activities.length;
  }

  // 获取今日活动总时长（分钟）
  Future<int> getTodayActivityDuration() async {
    if (!_isInitialized) return 0;
    final now = DateTime.now();
    final activities = await _activityService.getActivitiesForDate(now);

    int totalMinutes = 0;
    for (var activity in activities) {
      totalMinutes += activity.endTime.difference(activity.startTime).inMinutes;
    }

    // 更新缓存
    _updateCache(now, null, totalMinutes);

    return totalMinutes;
  }

  // 获取今日剩余时间（分钟）
  int getTodayRemainingTime() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59);
    return endOfDay.difference(now).inMinutes;
  }

  // 更新缓存
  void _updateCache(DateTime date, int? count, int? duration) {
    final today = DateTime(date.year, date.month, date.day);
    final cachedDay =
        _cacheDate != null
            ? DateTime(_cacheDate!.year, _cacheDate!.month, _cacheDate!.day)
            : null;

    // 如果是新的一天，重置缓存
    if (cachedDay == null || !cachedDay.isAtSameMomentAs(today)) {
      _cachedTodayActivityCount = 0;
      _cachedTodayActivityDuration = 0;
      _cacheDate = today;
    }

    // 更新缓存值
    if (count != null) _cachedTodayActivityCount = count;
    if (duration != null) _cachedTodayActivityDuration = duration;
  }

  // ==================== 通知便捷方法 ====================

  /// 获取最近活动时间（同步方法，用于通知服务）
  DateTime? getLastActivityTimeSync() {
    if (!_isInitialized) return null;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 同步获取今天的数据（如果有缓存的话）
      // 由于我们需要同步访问，这里使用简化逻辑
      // 在实际应用中，通知服务会调用异步方法
      print('同步获取活动时间：${today.toIso8601String()}'); // 使用today变量
      return null; // 占位符，实际由ActivityNotificationService处理
    } catch (e) {
      return null;
    }
  }

  /// 获取最近活动内容（同步方法，用于通知服务）
  String? getLastActivityContentSync() {
    if (!_isInitialized) return null;

    // 同步访问的占位符，实际由ActivityNotificationService处理
    return null;
  }

  // ==================== 通知服务便捷方法 ====================

  /// 启用活动通知服务
  Future<void> enableActivityNotification() async {
    try {
      // 加载并应用配置
      final minInterval = await getMinimumReminderInterval();
      final updateInt = await getUpdateInterval();
      _notificationService.updateSettings(
        minimumReminderInterval: minInterval,
        updateInterval: updateInt,
      );

      await _notificationService.enable();
      // 保存设置
      await storage.write('activity/notification_settings.json', {
        'isEnabled': true,
        'minimumReminderInterval': minInterval,
        'updateInterval': updateInt,
      });
      debugPrint('[ActivityPlugin] 通知栏显示已启用并保存');
    } catch (e) {
      debugPrint('[ActivityPlugin] 启用活动通知失败: $e');
      rethrow;
    }
  }

  /// 禁用活动通知服务
  Future<void> disableActivityNotification() async {
    try {
      await _notificationService.disable();
      // 保存设置
      await storage.write('activity/notification_settings.json', {
        'isEnabled': false,
      });
      debugPrint('[ActivityPlugin] 通知栏显示已禁用并保存');
    } catch (e) {
      debugPrint('[ActivityPlugin] 禁用活动通知失败: $e');
      rethrow;
    }
  }

  /// 获取通知服务状态
  bool isNotificationEnabled() {
    return _notificationService.isEnabled;
  }

  /// 获取最小提醒间隔（分钟）
  Future<int> getMinimumReminderInterval() async {
    try {
      final settings = await storage.read(
        'activity/notification_settings.json',
      );
      return settings['minimumReminderInterval'] as int? ?? 30; // 默认30分钟
    } catch (e) {
      debugPrint('[ActivityPlugin] 读取最小提醒间隔失败: $e');
      return 30;
    }
  }

  /// 设置最小提醒间隔（分钟）
  Future<void> setMinimumReminderInterval(int minutes) async {
    try {
      final settings = await storage.read(
        'activity/notification_settings.json',
      );
      settings['minimumReminderInterval'] = minutes;
      await storage.write('activity/notification_settings.json', settings);
      debugPrint('[ActivityPlugin] 最小提醒间隔已设置为 $minutes 分钟');

      // 更新通知服务
      _notificationService.updateSettings(
        minimumReminderInterval: minutes,
      );
    } catch (e) {
      debugPrint('[ActivityPlugin] 设置最小提醒间隔失败: $e');
      rethrow;
    }
  }

  /// 获取通知更新频率（分钟）
  Future<int> getUpdateInterval() async {
    try {
      final settings = await storage.read(
        'activity/notification_settings.json',
      );
      return settings['updateInterval'] as int? ?? 1; // 默认1分钟
    } catch (e) {
      debugPrint('[ActivityPlugin] 读取通知更新频率失败: $e');
      return 1;
    }
  }

  /// 设置通知更新频率（分钟）
  Future<void> setUpdateInterval(int minutes) async {
    try {
      final settings = await storage.read(
        'activity/notification_settings.json',
      );
      settings['updateInterval'] = minutes;
      await storage.write('activity/notification_settings.json', settings);
      debugPrint('[ActivityPlugin] 通知更新频率已设置为 $minutes 分钟');

      // 更新通知服务
      _notificationService.updateSettings(
        updateInterval: minutes,
      );
    } catch (e) {
      debugPrint('[ActivityPlugin] 设置通知更新频率失败: $e');
      rethrow;
    }
  }

  // 同步获取今日活动数（从缓存）
  int getTodayActivityCountSync() {
    if (!_isInitialized) return 0;

    // 检查缓存是否是今天的
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cachedDay =
        _cacheDate != null
            ? DateTime(_cacheDate!.year, _cacheDate!.month, _cacheDate!.day)
            : null;

    if (cachedDay != null && cachedDay.isAtSameMomentAs(today)) {
      return _cachedTodayActivityCount;
    }

    // 如果缓存不可用，异步刷新缓存（不等待）
    getTodayActivityCount();

    return 0;
  }

  // 同步获取今日活动总时长（分钟，从缓存）
  int getTodayActivityDurationSync() {
    if (!_isInitialized) return 0;

    // 检查缓存是否是今天的
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cachedDay =
        _cacheDate != null
            ? DateTime(_cacheDate!.year, _cacheDate!.month, _cacheDate!.day)
            : null;

    if (cachedDay != null && cachedDay.isAtSameMomentAs(today)) {
      return _cachedTodayActivityDuration;
    }

    // 如果缓存不可用，异步刷新缓存（不等待）
    getTodayActivityDuration();

    return 0;
  }

  @override
  Widget? buildCardView(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部图标和标题
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                ActivityLocalizations.of(context).name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 统计信息卡片
          FutureBuilder<List<int>>(
            future: Future.wait([
              getTodayActivityCount(),
              getTodayActivityDuration(),
              Future.value(getTodayRemainingTime()),
            ]),
            builder: (context, snapshot) {
              final data = snapshot.data ?? [0, 0, 0];
              final activityCount = data[0];
              final activityDuration = data[1];
              final remainingTime = data[2];

              return Column(
                children: [
                  // 第一行 - 两个统计项
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // 今日活动数
                      Column(
                        children: [
                          Text(
                            ActivityLocalizations.of(context).todayActivities,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '$activityCount',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  activityCount > 0
                                      ? theme.colorScheme.primary
                                      : null,
                            ),
                          ),
                        ],
                      ),

                      // 今日活动时长
                      Column(
                        children: [
                          Text(
                            ActivityLocalizations.of(context).todayDuration,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '${(activityDuration / 60).toStringAsFixed(1)}H',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 第二行 - 剩余时间
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            ActivityLocalizations.of(context).remainingTime,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '${(remainingTime / 60).toStringAsFixed(1)}H',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  remainingTime < 120
                                      ? theme.colorScheme.error
                                      : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget buildMainView(BuildContext context) {
    return const ActivityMainView();
  }

  @override
  Widget buildSettingsView(BuildContext context) {
    return const ActivitySettingsScreen();
  }
}

/// 活动插件主视图
class ActivityMainView extends StatefulWidget {
  const ActivityMainView({super.key});

  @override
  State<ActivityMainView> createState() => _ActivityMainViewState();
}

class _ActivityMainViewState extends State<ActivityMainView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _currentPage;
  final List<Color> _colors = [
    Colors.pink,
    Colors.purple,
    Colors.blue,
    Colors.orange,
  ];
  static const double _bottomBarOffset = 12.0;
  final GlobalKey _bottomBarKey = GlobalKey(debugLabel: 'activity_bottom_bar');
  double _bottomBarHeight = kBottomNavigationBarHeight + _bottomBarOffset * 2;

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.animation?.addListener(() {
      final value = _tabController.animation!.value.round();
      if (value != _currentPage && mounted) {
        setState(() {
          _currentPage = value;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _scheduleBottomBarHeightMeasurement() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderObject = _bottomBarKey.currentContext?.findRenderObject();
      if (renderObject is RenderBox) {
        final safeAreaBottom = MediaQuery.of(context).padding.bottom;
        final newHeight =
            renderObject.size.height + _bottomBarOffset * 2 + safeAreaBottom;
        if ((newHeight - _bottomBarHeight).abs() > 0.5) {
          setState(() {
            _bottomBarHeight = newHeight;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleBottomBarHeightMeasurement();
    final Color unselectedColor =
        _colors[_currentPage].computeLuminance() < 0.5
            ? Colors.black.withOpacity(0.6)
            : Colors.white.withOpacity(0.6);
    final Color bottomAreaColor = Theme.of(context).scaffoldBackgroundColor;
    final mediaQuery = MediaQuery.of(context);

    return BottomBar(
      fit: StackFit.expand,
      icon:
          (width, height) => Center(
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                // 滚动到顶部功能
                if (_tabController.indexIsChanging) return;

                // 这里可以添加滚动到顶部的逻辑
                // 由于我们使用的是TabBarView，可以考虑切换到第一个tab
                if (_currentPage != 0) {
                  _tabController.animateTo(0);
                }
              },
              icon: Icon(
                Icons.keyboard_arrow_up,
                color: _colors[_currentPage],
                size: width,
              ),
            ),
          ),
      borderRadius: BorderRadius.circular(25),
      duration: const Duration(milliseconds: 300),
      curve: Curves.decelerate,
      showIcon: true,
      width: mediaQuery.size.width * 0.85,
      barColor:
          _colors[_currentPage].computeLuminance() > 0.5
              ? Colors.black
              : Colors.white,
      start: 2,
      end: 0,
      offset: _bottomBarOffset,
      barAlignment: Alignment.bottomCenter,
      iconHeight: 35,
      iconWidth: 35,
      reverse: false,
      barDecoration: BoxDecoration(
        color: _colors[_currentPage].withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: _colors[_currentPage].withOpacity(0.3),
          width: 1,
        ),
      ),
      iconDecoration: BoxDecoration(
        color: _colors[_currentPage].withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _colors[_currentPage].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      hideOnScroll: true,
      scrollOpposite: false,
      onBottomBarHidden: () {},
      onBottomBarShown: () {},
      body:
          (context, controller) => Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(bottom: _bottomBarHeight),
                  child: TabBarView(
                    controller: _tabController,
                    dragStartBehavior: DragStartBehavior.down,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      const ActivityTimelineScreen(),
                      ActivityStatisticsScreen(
                        activityService:
                            ActivityPlugin.instance.activityService,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: _bottomBarHeight,
                  color: bottomAreaColor,
                ),
              ),
            ],
          ),
      child: Stack(
        key: _bottomBarKey,
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            indicatorPadding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                color:
                    _currentPage < 2 ? _colors[_currentPage] : unselectedColor,
                width: 4,
              ),
              insets: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            ),
            labelColor:
                _currentPage < 2 ? _colors[_currentPage] : unselectedColor,
            unselectedLabelColor: unselectedColor,
            tabs: [
              Tab(
                icon: const Icon(Icons.timeline),
                text: ActivityLocalizations.of(context).timeline,
              ),
              Tab(
                icon: const Icon(Icons.bar_chart),
                text: ActivityLocalizations.of(context).statistics,
              ),
            ],
          ),
          Positioned(
            top: -25,
            child: FloatingActionButton(
              backgroundColor: ActivityPlugin.instance.color,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 32),
              onPressed: () async {
                final activityService = ActivityPlugin.instance.activityService;
                final today = DateTime.now();

                if (!context.mounted) return;

                // 创建控制器实例并调用 addActivity 方法
                final controller = ActivityController(
                  activityService: activityService,
                  onActivitiesChanged: () {},
                );

                await controller.addActivity(
                  context,
                  today,
                  null,
                  null,
                  (tags) async {
                    await activityService.saveRecentTags(tags);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
