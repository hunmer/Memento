import 'dart:convert';
import 'package:flutter/material.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../../core/js_bridge/js_bridge_plugin.dart';
import 'l10n/activity_localizations.dart';
import 'screens/activity_timeline_screen/activity_timeline_screen.dart';
import 'screens/activity_statistics_screen.dart';
import 'services/activity_service.dart';
import 'controls/prompt_controller.dart';
import 'models/activity_record.dart';

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
  late ActivityPromptController _promptController;
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
    await initialize();
  }

  @override
  Future<void> initialize() async {
    // 确保活动记录数据目录存在
    await storage.createDirectory('activity');
    _activityService = ActivityService(storage, 'activity');

    _isInitialized = true;

    // 注册 JS API
    await registerJSAPI();

    // 初始化Prompt控制器（必须在 jsAPI 注册之后）
    _promptController = ActivityPromptController(this);
    _promptController.initialize();
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
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取指定日期的活动列表
  /// 参数: params - { date?: string } (YYYY-MM-DD 格式, 默认今天)
  Future<String> _jsGetActivities(Map<String, dynamic> params) async {
    try {
      final dateStr = params['date'] as String?;
      final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
      final activities = await _activityService.getActivitiesForDate(date);
      return jsonEncode(activities.map((a) => a.toJson()).toList());
    } catch (e) {
      return jsonEncode({'error': '获取活动失败: $e'});
    }
  }

  /// 创建活动
  /// 参数: params - {
  ///   startTime: string (必需, ISO 8601 格式),
  ///   endTime: string (必需, ISO 8601 格式),
  ///   title: string (必需),
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
          'error': '缺少必需参数: startTime, endTime, title'
        });
      }

      final startTimeStr = params['startTime'] as String;
      final endTimeStr = params['endTime'] as String;
      final title = params['title'] as String;

      final startTime = DateTime.parse(startTimeStr);
      final endTime = DateTime.parse(endTimeStr);

      // 解析标签
      final List<String> tags = params['tags'] != null
          ? List<String>.from(params['tags'])
          : [];

      final description = params['description'] as String?;
      final mood = params['mood'] as String?;

      final activity = ActivityRecord(
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
          'error': '缺少必需参数: activityId, startTime, endTime, title'
        });
      }

      final activityId = params['activityId'] as String;
      final startTimeStr = params['startTime'] as String;
      final endTimeStr = params['endTime'] as String;
      final title = params['title'] as String;

      final startTime = DateTime.parse(startTimeStr);
      final endTime = DateTime.parse(endTimeStr);

      // 解析标签
      final List<String> tags = params['tags'] != null
          ? List<String>.from(params['tags'])
          : [];

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
          'error': '缺少必需参数: activityId, date'
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
    final cachedDay = _cacheDate != null
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

  // 同步获取今日活动数（从缓存）
  int getTodayActivityCountSync() {
    if (!_isInitialized) return 0;

    // 检查缓存是否是今天的
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cachedDay = _cacheDate != null
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
    final cachedDay = _cacheDate != null
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
}

/// 活动插件主视图
class ActivityMainView extends StatefulWidget {
  const ActivityMainView({super.key});

  @override
  State<ActivityMainView> createState() => _ActivityMainViewState();
}

class _ActivityMainViewState extends State<ActivityMainView> {
  int _selectedIndex = 0;

  // 页面列表
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const ActivityTimelineScreen(),
      ActivityStatisticsScreen(
        activityService: ActivityPlugin.instance.activityService,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.timeline),
            label: ActivityLocalizations.of(context).timeline,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart),
            label: ActivityLocalizations.of(context).statistics,
          ),
        ],
      ),
    );
  }
}
