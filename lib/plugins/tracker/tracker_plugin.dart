import 'dart:io';

import 'package:Memento/core/config_manager.dart';
import 'package:Memento/plugins/tracker/l10n/tracker_localizations.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/core/plugin_base.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/plugins/tracker/models/goal.dart';
import 'package:Memento/plugins/tracker/models/record.dart';
import 'package:Memento/plugins/tracker/screens/goal_detail_screen.dart';
import 'package:Memento/plugins/tracker/widgets/goal_edit_page.dart';
import 'package:provider/provider.dart';
import '../../widgets/super_cupertino_navigation_wrapper.dart';
import 'controllers/tracker_controller.dart';
import 'screens/home_screen.dart';

export 'models/goal.dart';
export 'models/record.dart';
export 'controllers/tracker_controller.dart';
export 'widgets/goal_card.dart';
export 'widgets/goal_detail_page.dart';
export 'widgets/goal_edit_page.dart';
export 'widgets/record_dialog.dart';
export 'utils/date_utils.dart';
export 'utils/tracker_notification_utils.dart';
export 'l10n/tracker_localizations.dart';

class TrackerMainView extends StatefulWidget {
  const TrackerMainView({super.key});

  @override
  State<TrackerMainView> createState() => _TrackerMainViewState();
}

class _TrackerMainViewState extends State<TrackerMainView> {
  @override
  Widget build(BuildContext context) {
    return SuperCupertinoNavigationWrapper(
      title: Text(TrackerLocalizations.of(context).goalTracking),
      largeTitle: TrackerLocalizations.of(context).goalTracking,
      automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
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
  @override
  String get id => 'tracker';

  @override
  Color get color => Colors.red;

  @override
  IconData get icon => Icons.track_changes;

  @override
  Future<void> initialize() async {
    // 不再在插件初始化时初始化通知系统,改为在开始计时时才初始化
    await _controller.loadInitialData();

    // 注册 JS API（最后一步）
    await registerJSAPI();
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    await initialize();
  }

  @override
  Widget buildMainView(BuildContext context) {
    return const TrackerMainView();
  }

  /// 打开目标详情页
  void openGoalDetail(BuildContext context, Goal goal) {
    NavigationHelper.push(context, ChangeNotifierProvider.value(
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
    return TrackerLocalizations.of(context).name;
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
                TrackerLocalizations.of(context).name,
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
                        TrackerLocalizations.of(context).todayComplete,
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
                        TrackerLocalizations.of(context).thisMonthComplete,
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

  /// 获取所有目标
  /// 支持分页参数: offset, count
  Future<dynamic> _jsGetGoals(Map<String, dynamic> params) async {
    // 提取可选参数
    final String? status = params['status'];
    final String? group = params['group'];

    List<Goal> goals;

    // 根据状态筛选
    if (status != null && status.isNotEmpty) {
      goals = await _controller.getGoalsByStatus(status);
    } else {
      goals = await _controller.getAllGoals();
    }

    // 根据分组筛选
    if (group != null && group.isNotEmpty) {
      goals = goals.where((g) => g.group == group).toList();
    }

    final goalsJson = goals.map((g) => g.toJson()).toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      return _paginate(goalsJson, offset: offset ?? 0, count: count ?? 100);
    }

    // 兼容旧版本：无分页参数时返回全部数据
    return goalsJson;
  }

  /// 获取单个目标详情
  Future<dynamic> _jsGetGoal(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? goalId = params['goalId'];
    if (goalId == null || goalId.isEmpty) {
      return {'error': '缺少必需参数: goalId'};
    }

    final goals = await _controller.getAllGoals();
    final goal = goals.firstWhere(
      (g) => g.id == goalId,
      orElse: () => throw ArgumentError('Goal not found: $goalId'),
    );
    return goal.toJson();
  }

  /// 创建目标
  Future<dynamic> _jsCreateGoal(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? name = params['name'];
    if (name == null || name.isEmpty) {
      return {'error': '缺少必需参数: name'};
    }

    final String? unitType = params['unitType'];
    if (unitType == null || unitType.isEmpty) {
      return {'error': '缺少必需参数: unitType'};
    }

    // 支持 int 和 double 类型
    final targetValueRaw = params['targetValue'];
    if (targetValueRaw == null) {
      return {'error': '缺少必需参数: targetValue'};
    }
    final double targetValue =
        targetValueRaw is int
            ? targetValueRaw.toDouble()
            : targetValueRaw as double;

    // 提取可选参数
    final String? customId = params['id']; // 支持自定义ID
    final String? group = params['group'];
    final String? icon = params['icon'];
    final String? dateType = params['dateType'];

    // 如果提供了自定义ID，使用自定义ID；否则使用UUID生成
    final goalId =
        customId?.isNotEmpty == true
            ? customId!
            : const Uuid().v4();

    // 检查ID是否已存在
    final existingGoals = await _controller.getAllGoals();
    if (existingGoals.any((g) => g.id == goalId)) {
      return {'error': '目标ID已存在: $goalId'};
    }

    final goal = Goal(
      id: goalId,
      name: name,
      icon: icon ?? '57455', // 默认图标代码点
      unitType: unitType,
      targetValue: targetValue,
      currentValue: 0,
      dateSettings: DateSettings(type: dateType ?? 'daily'),
      isLoopReset: true,
      createdAt: DateTime.now(),
      group: group ?? '默认',
    );

    await _controller.addGoal(goal);
    return goal.toJson();
  }

  /// 更新目标
  Future<dynamic> _jsUpdateGoal(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? goalId = params['goalId'];
    if (goalId == null || goalId.isEmpty) {
      return {'error': '缺少必需参数: goalId'};
    }

    final Map<String, dynamic>? updateJson = params['updateJson'];
    if (updateJson == null) {
      return {'error': '缺少必需参数: updateJson'};
    }

    final goals = await _controller.getAllGoals();
    final oldGoal = goals.firstWhere(
      (g) => g.id == goalId,
      orElse: () => throw ArgumentError('Goal not found: $goalId'),
    );

    // 处理数值类型转换（支持 int 和 double）
    double getDoubleValue(String key, double defaultValue) {
      final value = updateJson[key];
      if (value == null) return defaultValue;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return defaultValue;
    }

    // 合并更新
    final newGoal = Goal(
      id: oldGoal.id,
      name: updateJson['name'] ?? oldGoal.name,
      icon: updateJson['icon'] ?? oldGoal.icon,
      iconColor: updateJson['iconColor'] ?? oldGoal.iconColor,
      unitType: updateJson['unitType'] ?? oldGoal.unitType,
      targetValue: getDoubleValue('targetValue', oldGoal.targetValue),
      currentValue: getDoubleValue('currentValue', oldGoal.currentValue),
      dateSettings:
          updateJson['dateSettings'] != null
              ? DateSettings.fromJson(updateJson['dateSettings'])
              : oldGoal.dateSettings,
      reminderTime: updateJson['reminderTime'] ?? oldGoal.reminderTime,
      isLoopReset: updateJson['isLoopReset'] ?? oldGoal.isLoopReset,
      createdAt: oldGoal.createdAt,
      group: updateJson['group'] ?? oldGoal.group,
      imagePath: updateJson['imagePath'] ?? oldGoal.imagePath,
      progressColor: updateJson['progressColor'] ?? oldGoal.progressColor,
    );

    await _controller.updateGoal(goalId, newGoal);
    return newGoal.toJson();
  }

  /// 删除目标
  Future<dynamic> _jsDeleteGoal(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? goalId = params['goalId'];
    if (goalId == null || goalId.isEmpty) {
      return {'success': false, 'error': '缺少必需参数: goalId'};
    }

    try {
      await _controller.deleteGoal(goalId);
      return {'success': true, 'goalId': goalId};
    } catch (e) {
      return {'success': false, 'error': '删除失败: ${e.toString()}'};
    }
  }

  /// 记录数据
  Future<dynamic> _jsRecordData(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? goalId = params['goalId'];
    if (goalId == null || goalId.isEmpty) {
      return {'error': '缺少必需参数: goalId'};
    }

    // 支持 int 和 double 类型
    final valueRaw = params['value'];
    if (valueRaw == null) {
      return {'error': '缺少必需参数: value'};
    }
    final double value =
        valueRaw is int ? valueRaw.toDouble() : valueRaw as double;

    // 提取可选参数
    final String? customId = params['id']; // 支持自定义ID
    final String? note = params['note'];
    final String? dateTime = params['dateTime'];

    final goals = await _controller.getAllGoals();
    final goal = goals.firstWhere(
      (g) => g.id == goalId,
      orElse: () => throw ArgumentError('Goal not found: $goalId'),
    );

    // 如果提供了自定义ID，使用自定义ID；否则使用UUID生成
    final recordId =
        customId?.isNotEmpty == true
            ? customId!
            : const Uuid().v4();

    // 检查ID是否已存在
    final existingRecords = await _controller.getRecordsForGoal(goalId);
    if (existingRecords.any((r) => r.id == recordId)) {
      return {'error': '记录ID已存在: $recordId'};
    }

    final record = Record(
      id: recordId,
      goalId: goalId,
      value: value,
      note: note,
      recordedAt: dateTime != null ? DateTime.parse(dateTime) : DateTime.now(),
    );

    await _controller.addRecord(record, goal);
    return record.toJson();
  }

  /// 获取目标的记录列表
  /// 支持分页参数: offset, count
  Future<dynamic> _jsGetRecords(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? goalId = params['goalId'];
    if (goalId == null || goalId.isEmpty) {
      return {'error': '缺少必需参数: goalId'};
    }

    // 提取可选参数
    final int? limit = params['limit'];
    final int? offset = params['offset'];
    final int? count = params['count'];

    final records = await _controller.getRecordsForGoal(goalId);

    // 按时间倒序排列
    records.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    // 如果指定了 limit，只返回最新的 N 条记录（向后兼容）
    final List<Record> resultRecords =
        limit != null && limit < records.length
            ? records.sublist(0, limit)
            : records;

    final recordsJson = resultRecords.map((r) => r.toJson()).toList();

    // 检查是否需要分页
    if (offset != null || count != null) {
      return _paginate(recordsJson, offset: offset ?? 0, count: count ?? 100);
    }

    // 兼容旧版本：无分页参数时返回全部数据
    return recordsJson;
  }

  /// 删除记录
  Future<dynamic> _jsDeleteRecord(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? recordId = params['recordId'];
    if (recordId == null || recordId.isEmpty) {
      return {'success': false, 'error': '缺少必需参数: recordId'};
    }

    try {
      await _controller.deleteRecord(recordId);
      return {'success': true, 'recordId': recordId};
    } catch (e) {
      return {'success': false, 'error': '删除失败: ${e.toString()}'};
    }
  }

  /// 获取目标进度
  Future<dynamic> _jsGetProgress(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? goalId = params['goalId'];
    if (goalId == null || goalId.isEmpty) {
      return {'error': '缺少必需参数: goalId'};
    }

    final goals = await _controller.getAllGoals();
    final goal = goals.firstWhere(
      (g) => g.id == goalId,
      orElse: () => throw ArgumentError('Goal not found: $goalId'),
    );

    final progress = _controller.calculateProgress(goal);

    return {
      'goalId': goalId,
      'currentValue': goal.currentValue,
      'targetValue': goal.targetValue,
      'progress': progress,
      'percentage': (progress * 100).toStringAsFixed(1),
      'isCompleted': goal.isCompleted,
    };
  }

  /// 获取统计信息
  Future<dynamic> _jsGetStats(Map<String, dynamic> params) async {
    // 提取可选参数
    final String? goalId = params['goalId'];

    if (goalId != null && goalId.isNotEmpty) {
      // 返回单个目标的统计信息
      final goals = await _controller.getAllGoals();
      final goal = goals.firstWhere(
        (g) => g.id == goalId,
        orElse: () => throw ArgumentError('Goal not found: $goalId'),
      );

      final records = await _controller.getRecordsForGoal(goalId);

      return {
        'goalId': goalId,
        'goalName': goal.name,
        'totalRecords': records.length,
        'totalValue': records.fold(0.0, (sum, r) => sum + r.value),
        'currentValue': goal.currentValue,
        'targetValue': goal.targetValue,
        'progress': _controller.calculateProgress(goal),
        'isCompleted': goal.isCompleted,
      };
    } else {
      // 返回全局统计信息
      return {
        'totalGoals': _controller.getGoalCount(),
        'todayCompleted': _controller.getTodayCompletedGoals(),
        'monthCompleted': _controller.getMonthCompletedGoals(),
        'monthAdded': _controller.getMonthAddedGoals(),
        'todayRecords': _controller.getTodayRecordCount(),
        'overallProgress': _controller.calculateOverallProgress(),
        'groups': _controller.getAllGroups(),
      };
    }
  }
}
