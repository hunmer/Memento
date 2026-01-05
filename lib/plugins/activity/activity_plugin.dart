import 'dart:convert';
import 'package:get/get.dart';

import 'package:Memento/core/app_initializer.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:flutter/gestures.dart';
import 'package:Memento/core/widgets/custom_bottom_bar.dart';
import 'package:Memento/plugins/base_plugin.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/event/event.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';
import 'screens/activity_timeline_screen/activity_timeline_screen.dart';
import 'screens/activity_timeline_screen/controllers/activity_controller.dart';
import 'screens/activity_statistics_screen.dart';
import 'screens/activity_edit_screen.dart';
import 'screens/activity_settings_screen.dart';
import 'services/activity_service.dart';
import 'services/activity_notification_service.dart';
import 'models/activity_record.dart';
import 'repositories/client_activity_repository.dart';
import 'package:shared_models/shared_models.dart';
import 'package:universal_platform/universal_platform.dart';

part 'activity_js_api.dart';
part 'activity_data_selectors.dart';

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
    return 'activity_name'.tr;
  }

  late ActivityService _activityService;
  late ActivityNotificationService _notificationService;
  late ActivityUseCase _activityUseCase;
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
      navigator.push(
        NavigationHelper.createRoute(const ActivityEditScreen()),
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

    // 初始化默认数据（如果是首次使用）
    await _activityService.initializeDefaultData();

    // 创建 Repository 和 UseCase 实例
    final repository = ClientActivityRepository(activityService: _activityService);
    _activityUseCase = ActivityUseCase(repository);

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

    // 注册数据选择器
    _registerDataSelectors();
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
                'activity_name'.tr,
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
                            'activity_todayActivities'.tr,
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
                            'activity_todayDuration'.tr,
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
                            'activity_remainingTime'.tr,
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
  final Set<int> _visitedTabs = {0}; // 记录已访问的 tab，默认第一个已访问
  final List<Color> _colors = [
    Colors.pink,
    Colors.purple,
    Colors.blue,
    Colors.orange,
  ];
  final GlobalKey _bottomBarKey = GlobalKey(debugLabel: 'activity_bottom_bar');

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    _tabController = TabController(length: 2, vsync: this);

    // 监听 tab 切换动画
    _tabController.animation?.addListener(() {
      final value = _tabController.animation!.value.round();
      if (value != _currentPage && mounted) {
        setState(() {
          _currentPage = value;
          _visitedTabs.add(value); // 记录已访问的 tab
        });
      }
    });

    // 监听 tab 点击事件，立即预加载目标页面
    _tabController.addListener(() {
      if (mounted && _tabController.indexIsChanging) {
        final targetIndex = _tabController.index;
        if (!_visitedTabs.contains(targetIndex)) {
          setState(() {
            _visitedTabs.add(targetIndex); // 立即标记为已访问，触发预加载
          });
        }
      }
    });

    // 预加载统计页面：在首页加载完成后延迟加载统计页面，作为备用方案
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && !_visitedTabs.contains(1)) {
          setState(() {
            _visitedTabs.add(1); // 预加载统计页面
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 构建 FAB
  Widget _buildFab() {
    return FloatingActionButton(
      backgroundColor: ActivityPlugin.instance.color,
      elevation: 4,
      shape: const CircleBorder(),
      onPressed: () {
        if (!context.mounted) return;
        ActivityController.showAddActivityScreen(context);
      },
      child: Icon(
        Icons.add,
        color: ActivityPlugin.instance.color.computeLuminance() > 0.5
            ? Colors.black
            : Colors.white,
        size: 32,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomBar(
      colors: _colors,
      currentIndex: _currentPage,
      tabController: _tabController,
      bottomBarKey: _bottomBarKey,
      body: (context, controller) => TabBarView(
        controller: _tabController,
        dragStartBehavior: DragStartBehavior.down,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const ActivityTimelineScreen(),
          _visitedTabs.contains(1)
              ? ActivityStatisticsScreen(
                  activityService: ActivityPlugin.instance.activityService,
                )
              : const Center(child: CircularProgressIndicator()),
        ],
      ),
      fab: _buildFab(),
      children: [
        Tab(
          icon: const Icon(Icons.timeline),
          text: 'activity_timeline'.tr,
        ),
        Tab(
          icon: const Icon(Icons.bar_chart),
          text: 'activity_statistics'.tr,
        ),
      ],
    );
  }
}
