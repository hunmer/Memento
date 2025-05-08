import 'package:flutter/material.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import 'l10n/activity_localizations.dart';
import 'screens/activity_timeline_screen/activity_timeline_screen.dart';
import 'screens/activity_statistics_screen.dart';
import 'services/activity_service.dart';
import 'controls/prompt_controller.dart';

class ActivityPlugin extends BasePlugin {
  static final ActivityPlugin instance = ActivityPlugin._internal();
  ActivityPlugin._internal();

  late ActivityService _activityService;
  late ActivityPromptController _promptController;
  bool _isInitialized = false;

  // 获取活动服务实例
  ActivityService get activityService {
    if (!_isInitialized) {
      throw StateError('ActivityPlugin has not been initialized');
    }
    return _activityService;
  }

  @override
  final String id = 'activity_plugin';

  @override
  String get name => 'Activity';

  @override
  final String version = '1.0.0';

  @override
  final String pluginDir = 'activity';

  @override
  String get description => '活动记录插件';

  @override
  String get author => 'Zhuanz';

    @override
  IconData get icon => Icons.timeline;

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 初始化插件
    await initialize();

    // 注册插件到插件管理器
    await pluginManager.registerPlugin(this);

    // 保存插件配置
    await configManager.savePluginConfig(id, {
      'version': version,
      'enabled': true,
      'settings': {'theme': 'light'},
    });
  }

  @override
  Future<void> initialize() async {
    // 确保活动记录数据目录存在
    await storage.createDirectory(pluginDir);
    _activityService = ActivityService(storage, pluginDir);
    
    // 初始化Prompt控制器
    _promptController = ActivityPromptController(storage, pluginDir);
    _promptController.initialize();
    
    _isInitialized = true;
  }

  // 获取今日活动数
  Future<int> getTodayActivityCount() async {
    if (!_isInitialized) return 0;
    final now = DateTime.now();
    final activities = await _activityService.getActivitiesForDate(now);
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
    return totalMinutes;
  }

  // 获取今日剩余时间（分钟）
  int getTodayRemainingTime() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59);
    return endOfDay.difference(now).inMinutes;
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
                  color: theme.primaryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                name,
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
                              ActivityLocalizations.of(context)!.todayActivities,
                              style: theme.textTheme.bodyMedium
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
                              ActivityLocalizations.of(context)!.todayDuration ,
                              style: theme.textTheme.bodyMedium
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
                              ActivityLocalizations.of(context)!.remainingTime,
                              style: theme.textTheme.bodyMedium
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
            label: ActivityLocalizations.of(context)?.timeline ?? '时间线'
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart),
            label: ActivityLocalizations.of(context)?.statistics ?? '统计'
          ),
        ],
      ),
    );
  }


}
