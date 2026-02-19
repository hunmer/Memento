import 'dart:convert';

import 'package:get/get.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/plugin_base.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/core/event/event.dart';
import 'package:Memento/plugins/tracker/models/goal.dart';
import 'package:Memento/plugins/tracker/screens/goal_detail_screen.dart';
import 'package:Memento/plugins/tracker/screens/search_results_screen.dart';
import 'package:Memento/plugins/tracker/widgets/goal_edit_page.dart';
import 'package:provider/provider.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';
import 'package:shared_models/shared_models.dart';
import 'controllers/tracker_controller.dart';
import 'screens/home_screen.dart';
import 'repositories/client_tracker_repository.dart';

export 'models/goal.dart';
export 'models/record.dart';
export 'controllers/tracker_controller.dart';
export 'widgets/goal_card.dart';
export 'widgets/goal_detail_page.dart';
export 'widgets/goal_edit_page.dart';
export 'widgets/record_dialog.dart';
export 'utils/date_utils.dart';
export 'utils/tracker_notification_utils.dart';

part 'tracker_js_api.dart';
part 'tracker_data_selectors.dart';

/// 目标缓存更新事件参数（携带数据，性能优化）
class TrackerCacheUpdatedEventArgs extends EventArgs {
  /// 所有目标列表
  final List<Goal> goals;

  /// 目标数量
  final int count;

  /// 缓存日期
  final DateTime cacheDate;

  TrackerCacheUpdatedEventArgs({
    required this.goals,
    required this.cacheDate,
  }) : count = goals.length,
       super('tracker_cache_updated');
}


class TrackerMainView extends StatefulWidget {
  final String? initialGoalId;

  const TrackerMainView({super.key, this.initialGoalId});

  @override
  State<TrackerMainView> createState() => _TrackerMainViewState();
}

class _TrackerMainViewState extends State<TrackerMainView> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // 如果有 initialGoalId，在初始化后跳转到目标详情
    if (widget.initialGoalId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToGoalDetail(widget.initialGoalId!);
      });
    }
  }

  void _navigateToGoalDetail(String goalId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GoalDetailScreen(goalId: goalId),
      ),
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SuperCupertinoNavigationWrapper(
      title: Text('tracker_goalTracking'.tr),
      largeTitle: 'tracker_goalTracking'.tr,

      enableSearchBar: true,
      searchPlaceholder: 'tracker_searchPlaceholder'.tr,
      onSearchChanged: _onSearchChanged,
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            NavigationHelper.openContainerWithHero(
              context,
              (context) =>
                  GoalEditPage(controller: TrackerPlugin.instance.controller),
            );
          },
          tooltip: '添加目标',
        ),
      ],
      searchBody: ChangeNotifierProvider.value(
        value: TrackerPlugin.instance.controller,
        child: SearchResultsScreen(searchQuery: _searchQuery),
      ),
      body: ChangeNotifierProvider.value(
        value: TrackerPlugin.instance.controller,
        child: const HomeScreen(),
      ),
    );
  }
}

class TrackerPlugin extends PluginBase with ChangeNotifier, JSBridgePlugin {
  static TrackerPlugin? _instance;

  // 构造函数中初始化实例
  TrackerPlugin() {
    _instance = this;
  }

  // 获取插件实例的静态方法
  static TrackerPlugin get instance {
    _instance ??= TrackerPlugin();
    return _instance!;
  }

  late final TrackerController _controller = TrackerController();
  TrackerController get controller => _controller;

  // UseCase 实例
  late final TrackerUseCase _trackerUseCase;
  TrackerUseCase get trackerUseCase => _trackerUseCase;
  @override
  String get id => 'tracker';

  @override
  Color get color => Colors.red;

  @override
  IconData get icon => Icons.track_changes;

  @override
  Future<void> initialize() async {
    // 初始化 UseCase（需要 storage）
    _trackerUseCase = TrackerUseCase(
      ClientTrackerRepository(storage: storage, pluginId: id),
    );

    // 不再在插件初始化时初始化通知系统,改为在开始计时时才初始化
    await _controller.loadInitialData();

    // 注册 JS API（最后一步）
    await registerJSAPI();

    // 注册数据选择器
    _registerDataSelectors();
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 插件已在 initialize() 中完成初始化
    // 这里可以添加额外的应用级注册逻辑
  }

  @override
  Widget buildMainView(BuildContext context) {
    return const TrackerMainView();
  }

  /// 打开目标详情页
  void openGoalDetail(BuildContext context, Goal goal) {
    NavigationHelper.push(
      context,
      ChangeNotifierProvider.value(
        value: _controller,
        child: GoalDetailScreen(goal: goal),
      ),
    );
  }

  // ========== 小组件统计方法 ==========

  /// 获取总目标数量
  int getGoalCount() {
    return _controller.getGoalCount();
  }

  /// 获取进行中的目标数量
  int getActiveGoalCount() {
    return _controller.goals.where((g) => !g.isCompleted).length;
  }

  /// 获取今日新增记录数
  int getTodayRecordCount() {
    return _controller.getTodayRecordCount();
  }

  @override
  String? getPluginName(context) {
    return 'tracker_name'.tr;
  }

  @override
  Widget buildCardView(BuildContext context) {
    final theme = Theme.of(context);
    final controller = TrackerController();

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
                'tracker_name'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 统计信息卡片
          Column(
            children: [
              // 第一行 - 今日完成和本月完成
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 今日完成
                  Column(
                    children: [
                      Text(
                        'tracker_todayComplete'.tr,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        controller.getTodayCompletedGoals().toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  // 本月完成
                  Column(
                    children: [
                      Text(
                        'tracker_thisMonthComplete'.tr,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        controller.getMonthCompletedGoals().toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 目标相关
      'getGoals': _jsGetGoals,
      'getGoal': _jsGetGoal,
      'createGoal': _jsCreateGoal,
      'updateGoal': _jsUpdateGoal,
      'deleteGoal': _jsDeleteGoal,

      // 记录相关
      'recordData': _jsRecordData,
      'getRecords': _jsGetRecords,
      'deleteRecord': _jsDeleteRecord,

      // 统计相关
      'getProgress': _jsGetProgress,
      'getStats': _jsGetStats,
    };
  }
}
