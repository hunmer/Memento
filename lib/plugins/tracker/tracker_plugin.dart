import 'package:get/get.dart';
import 'dart:io';

import 'package:Memento/core/config_manager.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/plugin_base.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
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

class TrackerMainView extends StatefulWidget {
  const TrackerMainView({super.key});

  @override
  State<TrackerMainView> createState() => _TrackerMainViewState();
}

class _TrackerMainViewState extends State<TrackerMainView> {
  String _searchQuery = '';

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
      automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
      enableSearchBar: true,
      searchPlaceholder: 'tracker_searchPlaceholder'.tr,
      onSearchChanged: _onSearchChanged,
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            NavigationHelper.openContainerWithHero(
              context,
              (context) => GoalEditPage(controller: TrackerPlugin.instance.controller),
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

  // ==================== 辅助方法 ====================

  /// 分页控制器 - 对列表进行分页处理
  /// @param list 原始数据列表
  /// @param offset 起始位置（默认 0）
  /// @param count 返回数量（默认 100）
  /// @return 分页后的数据，包含 data、total、offset、count、hasMore
  // ignore: unused_element
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

  /// 获取所有目标
  /// 支持分页参数: offset, count
  Future<dynamic> _jsGetGoals(Map<String, dynamic> params) async {
    // 提取可选参数
    final String? status = params['status'];
    final String? group = params['group'];

    // 构建参数（UseCase 不直接支持 group 筛选，需要在结果后处理）
    final useCaseParams = <String, dynamic>{
      if (status != null && status.isNotEmpty) 'status': status,
      if (params['offset'] != null) 'offset': params['offset'],
      if (params['count'] != null) 'count': params['count'],
    };

    final result = await _trackerUseCase.getGoals(useCaseParams);

    if (result.isFailure) {
      final failure = result.errorOrNull;
      return {'error': failure?.message ?? 'Unknown error'};
    }

    var goalsJson = result.dataOrNull;

    // 如果需要按分组筛选，在结果上处理
    if (group != null && group.isNotEmpty && goalsJson is List) {
      goalsJson = goalsJson.where((g) => g['group'] == group).toList();
    }

    // 如果有分页参数，UseCase 已经处理了分页
    // 如果没有分页参数，直接返回数据
    return goalsJson;
  }

  /// 获取单个目标详情
  Future<dynamic> _jsGetGoal(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? goalId = params['goalId'];
    if (goalId == null || goalId.isEmpty) {
      return {'error': '缺少必需参数: goalId'};
    }

    final result = await _trackerUseCase.getGoalById({'id': goalId});

    if (result.isFailure) {
      final failure = result.errorOrNull;
      return {'error': failure?.message ?? 'Unknown error'};
    }

    return result.dataOrNull;
  }

  /// 创建目标
  Future<dynamic> _jsCreateGoal(Map<String, dynamic> params) async {
    // 转换参数格式以适配 UseCase
    final useCaseParams = <String, dynamic>{};

    // 提取必需参数
    if (params['name'] != null) useCaseParams['name'] = params['name'];
    if (params['icon'] != null) useCaseParams['icon'] = params['icon'];
    if (params['unitType'] != null)
      useCaseParams['unitType'] = params['unitType'];
    if (params['targetValue'] != null)
      useCaseParams['targetValue'] = params['targetValue'];

    // 提取可选参数
    if (params['id'] != null) useCaseParams['id'] = params['id'];
    if (params['group'] != null) useCaseParams['group'] = params['group'];
    if (params['iconColor'] != null)
      useCaseParams['iconColor'] = params['iconColor'];
    if (params['imagePath'] != null)
      useCaseParams['imagePath'] = params['imagePath'];
    if (params['progressColor'] != null)
      useCaseParams['progressColor'] = params['progressColor'];
    if (params['reminderTime'] != null)
      useCaseParams['reminderTime'] = params['reminderTime'];
    if (params['isLoopReset'] != null)
      useCaseParams['isLoopReset'] = params['isLoopReset'];

    // 处理日期设置
    final dateType = params['dateType'] ?? 'daily';
    useCaseParams['dateSettings'] = {
      'type': dateType,
      'startDate': params['startDate'],
      'endDate': params['endDate'],
      'selectedDays': params['selectedDays'],
      'monthDay': params['monthDay'],
    };

    final result = await _trackerUseCase.createGoal(useCaseParams);

    if (result.isFailure) {
      final failure = result.errorOrNull;
      return {'error': failure?.message ?? 'Unknown error'};
    }

    return result.dataOrNull;
  }

  /// 更新目标
  Future<dynamic> _jsUpdateGoal(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? goalId = params['goalId'];
    if (goalId == null || goalId.isEmpty) {
      return {'error': '缺少必需参数: goalId'};
    }

    // 转换参数格式以适配 UseCase
    final useCaseParams = <String, dynamic>{'id': goalId};

    // 从 updateJson 中提取所有可更新字段
    final updateJson = params['updateJson'] as Map<String, dynamic>? ?? {};

    // 添加所有可能的更新字段
    if (updateJson['name'] != null) useCaseParams['name'] = updateJson['name'];
    if (updateJson['icon'] != null) useCaseParams['icon'] = updateJson['icon'];
    if (updateJson['iconColor'] != null)
      useCaseParams['iconColor'] = updateJson['iconColor'];
    if (updateJson['unitType'] != null)
      useCaseParams['unitType'] = updateJson['unitType'];
    if (updateJson['targetValue'] != null)
      useCaseParams['targetValue'] = updateJson['targetValue'];
    if (updateJson['group'] != null)
      useCaseParams['group'] = updateJson['group'];
    if (updateJson['imagePath'] != null)
      useCaseParams['imagePath'] = updateJson['imagePath'];
    if (updateJson['progressColor'] != null)
      useCaseParams['progressColor'] = updateJson['progressColor'];
    if (updateJson['reminderTime'] != null)
      useCaseParams['reminderTime'] = updateJson['reminderTime'];
    if (updateJson['isLoopReset'] != null)
      useCaseParams['isLoopReset'] = updateJson['isLoopReset'];

    // 处理日期设置
    if (updateJson['dateSettings'] != null) {
      useCaseParams['dateSettings'] = updateJson['dateSettings'];
    }

    final result = await _trackerUseCase.updateGoal(useCaseParams);

    if (result.isFailure) {
      final failure = result.errorOrNull;
      return {'error': failure?.message ?? 'Unknown error'};
    }

    return result.dataOrNull;
  }

  /// 删除目标
  Future<dynamic> _jsDeleteGoal(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? goalId = params['goalId'];
    if (goalId == null || goalId.isEmpty) {
      return {'success': false, 'error': '缺少必需参数: goalId'};
    }

    final result = await _trackerUseCase.deleteGoal({'id': goalId});

    if (result.isFailure) {
      final failure = result.errorOrNull;
      return {'success': false, 'error': failure?.message ?? 'Unknown error'};
    }

    final data = result.dataOrNull;
    return {'success': true, if (data != null) ...data};
  }

  /// 记录数据
  Future<dynamic> _jsRecordData(Map<String, dynamic> params) async {
    // 转换参数格式以适配 UseCase
    final useCaseParams = <String, dynamic>{};

    // 提取必需参数
    if (params['goalId'] != null) useCaseParams['goalId'] = params['goalId'];
    if (params['value'] != null) useCaseParams['value'] = params['value'];

    // 提取可选参数
    if (params['id'] != null) useCaseParams['id'] = params['id'];
    if (params['note'] != null) useCaseParams['note'] = params['note'];
    if (params['durationSeconds'] != null)
      useCaseParams['durationSeconds'] = params['durationSeconds'];

    // 处理记录时间
    final dateTime = params['dateTime'];
    if (dateTime != null) {
      useCaseParams['recordedAt'] = dateTime;
    } else {
      useCaseParams['recordedAt'] = DateTime.now().toIso8601String();
    }

    final result = await _trackerUseCase.addRecord(useCaseParams);

    if (result.isFailure) {
      final failure = result.errorOrNull;
      return {'error': failure?.message ?? 'Unknown error'};
    }

    return result.dataOrNull;
  }

  /// 获取目标的记录列表
  /// 支持分页参数: offset, count
  Future<dynamic> _jsGetRecords(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? goalId = params['goalId'];
    if (goalId == null || goalId.isEmpty) {
      return {'error': '缺少必需参数: goalId'};
    }

    // 构建参数（limit 参数不直接支持，需要在结果后处理）
    final useCaseParams = <String, dynamic>{
      'goalId': goalId,
      if (params['offset'] != null) 'offset': params['offset'],
      if (params['count'] != null) 'count': params['count'],
    };

    final result = await _trackerUseCase.getRecordsForGoal(useCaseParams);

    if (result.isFailure) {
      final failure = result.errorOrNull;
      return {'error': failure?.message ?? 'Unknown error'};
    }

    var recordsJson = result.dataOrNull;

    // 处理 limit 参数（向后兼容）
    final limit = params['limit'] as int?;
    if (limit != null && recordsJson is List && recordsJson.length > limit) {
      recordsJson = recordsJson.sublist(0, limit);
    }

    return recordsJson;
  }

  /// 删除记录
  Future<dynamic> _jsDeleteRecord(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? recordId = params['recordId'];
    if (recordId == null || recordId.isEmpty) {
      return {'success': false, 'error': '缺少必需参数: recordId'};
    }

    final result = await _trackerUseCase.deleteRecord({'recordId': recordId});

    if (result.isFailure) {
      final failure = result.errorOrNull;
      return {'success': false, 'error': failure?.message ?? 'Unknown error'};
    }

    final data = result.dataOrNull;
    return {'success': true, if (data != null) ...data};
  }

  /// 获取目标进度
  Future<dynamic> _jsGetProgress(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? goalId = params['goalId'];
    if (goalId == null || goalId.isEmpty) {
      return {'error': '缺少必需参数: goalId'};
    }

    // 先获取目标详情
    final goalResult = await _trackerUseCase.getGoalById({'id': goalId});

    if (goalResult.isFailure) {
      final failure = goalResult.errorOrNull;
      return {'error': failure?.message ?? 'Unknown error'};
    }

    final goalJson = goalResult.dataOrNull as Map<String, dynamic>;
    final currentValue = (goalJson['currentValue'] as num).toDouble();
    final targetValue = (goalJson['targetValue'] as num).toDouble();

    // 计算进度
    final progress =
        targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

    return {
      'goalId': goalId,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'progress': progress,
      'percentage': (progress * 100).toStringAsFixed(1),
      'isCompleted': currentValue >= targetValue,
    };
  }

  /// 获取统计信息
  Future<dynamic> _jsGetStats(Map<String, dynamic> params) async {
    // 提取可选参数
    final String? goalId = params['goalId'];

    if (goalId != null && goalId.isNotEmpty) {
      // 返回单个目标的统计信息
      // 先获取目标详情
      final goalResult = await _trackerUseCase.getGoalById({'id': goalId});

      if (goalResult.isFailure) {
        final failure = goalResult.errorOrNull;
        return {'error': failure?.message ?? 'Unknown error'};
      }

      final goalJson = goalResult.dataOrNull as Map<String, dynamic>;

      // 获取记录列表
      final recordsResult = await _trackerUseCase.getRecordsForGoal({
        'goalId': goalId,
      });

      if (recordsResult.isFailure) {
        final failure = recordsResult.errorOrNull;
        return {'error': failure?.message ?? 'Unknown error'};
      }

      final records = recordsResult.dataOrNull as List;
      final totalValue = records.fold<double>(
        0.0,
        (sum, r) =>
            sum + ((r as Map<String, dynamic>)['value'] as num).toDouble(),
      );
      final currentValue = (goalJson['currentValue'] as num).toDouble();
      final targetValue = (goalJson['targetValue'] as num).toDouble();
      final progress =
          targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

      return {
        'goalId': goalId,
        'goalName': goalJson['name'],
        'totalRecords': records.length,
        'totalValue': totalValue,
        'currentValue': currentValue,
        'targetValue': targetValue,
        'progress': progress,
        'isCompleted': currentValue >= targetValue,
      };
    } else {
      // 返回全局统计信息
      final result = await _trackerUseCase.getStats({});

      if (result.isFailure) {
        final failure = result.errorOrNull;
        return {'error': failure?.message ?? 'Unknown error'};
      }

      final stats = result.dataOrNull as Map<String, dynamic>;
      return stats;
    }
  }

  /// 注册数据选择器
  void _registerDataSelectors() {
    pluginDataSelectorService.registerSelector(
      SelectorDefinition(
        id: 'tracker.goal',
        pluginId: id,
        name: '选择追踪目标',
        icon: icon,
        color: color,
        searchable: true,
        selectionMode: SelectionMode.single,
        steps: [
          SelectorStep(
            id: 'goal',
            title: '选择目标',
            viewType: SelectorViewType.list,
            isFinalStep: true,
            dataLoader: (_) async {
              final goals = await _controller.getAllGoals();
              return goals.map((goal) {
                // 构建副标题：显示进度和分组信息
                final progress = _controller.calculateProgress(goal);
                final progressText =
                    '${(progress * 100).toStringAsFixed(1)}% (${goal.currentValue}/${goal.targetValue} ${goal.unitType})';
                final subtitle = '${goal.group} • $progressText';

                return SelectableItem(
                  id: goal.id,
                  title: goal.name,
                  subtitle: subtitle,
                  icon: Icons.track_changes,
                  rawData: goal,
                );
              }).toList();
            },
            searchFilter: (items, query) {
              if (query.isEmpty) return items;
              final lowerQuery = query.toLowerCase();
              return items.where((item) {
                final goal = item.rawData as Goal;
                return item.title.toLowerCase().contains(lowerQuery) ||
                    goal.group.toLowerCase().contains(lowerQuery) ||
                    goal.unitType.toLowerCase().contains(lowerQuery);
              }).toList();
            },
          ),
        ],
      ),
    );
  }
}
