import 'dart:convert';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/plugins/tracker/l10n/tracker_localizations.dart';
import 'package:Memento/plugins/tracker/utils/tracker_notification_utils.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_base.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/plugins/tracker/models/goal.dart';
import 'package:Memento/plugins/tracker/models/record.dart';
import 'package:Memento/plugins/tracker/screens/goal_detail_screen.dart';
import 'package:provider/provider.dart';
import 'controllers/tracker_controller.dart';
import 'screens/home_screen.dart';
import 'controls/prompt_controller.dart';

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
    return ChangeNotifierProvider.value(
      value: TrackerPlugin.instance.controller,
      child: const HomeScreen(),
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
  late TrackerPromptController _promptController;
  @override
  String get id => 'tracker';

  @override
  Color get color => Colors.red;

  @override
  IconData get icon => Icons.track_changes;

  @override
  Future<void> initialize() async {
    await TrackerNotificationUtils.initialize();
    await _controller.loadInitialData();

    // 初始化 Prompt 控制器
    _promptController = TrackerPromptController(this);
    _promptController.initialize();

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
    return ChangeNotifierProvider.value(
      value: _controller,
      child: const TrackerMainView(),
    );
  }

  /// 打开目标详情页
  void openGoalDetail(BuildContext context, Goal goal) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => ChangeNotifierProvider.value(
              value: _controller,
              child: GoalDetailScreen(goal: goal),
            ),
      ),
    );
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

  // ==================== JS API 实现 ====================

  /// 获取所有目标
  Future<String> _jsGetGoals(Map<String, dynamic> params) async {
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

    return jsonEncode(goals.map((g) => g.toJson()).toList());
  }

  /// 获取单个目标详情
  Future<String> _jsGetGoal(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? goalId = params['goalId'];
    if (goalId == null || goalId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: goalId'});
    }

    final goals = await _controller.getAllGoals();
    final goal = goals.firstWhere(
      (g) => g.id == goalId,
      orElse: () => throw ArgumentError('Goal not found: $goalId'),
    );
    return jsonEncode(goal.toJson());
  }

  /// 创建目标
  Future<String> _jsCreateGoal(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? name = params['name'];
    if (name == null || name.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: name'});
    }

    final String? unitType = params['unitType'];
    if (unitType == null || unitType.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: unitType'});
    }

    final double? targetValue = params['targetValue'];
    if (targetValue == null) {
      return jsonEncode({'error': '缺少必需参数: targetValue'});
    }

    // 提取可选参数
    final String? group = params['group'];
    final String? icon = params['icon'];
    final String? dateType = params['dateType'];

    final goal = Goal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      icon: icon ?? '57455', // 默认图标代码点
      unitType: unitType,
      targetValue: targetValue,
      currentValue: 0,
      dateSettings: DateSettings(
        type: dateType ?? 'daily',
      ),
      isLoopReset: true,
      createdAt: DateTime.now(),
      group: group ?? '默认',
    );

    await _controller.addGoal(goal);
    return jsonEncode(goal.toJson());
  }

  /// 更新目标
  Future<String> _jsUpdateGoal(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? goalId = params['goalId'];
    if (goalId == null || goalId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: goalId'});
    }

    final Map<String, dynamic>? updateJson = params['updateJson'];
    if (updateJson == null) {
      return jsonEncode({'error': '缺少必需参数: updateJson'});
    }

    final goals = await _controller.getAllGoals();
    final oldGoal = goals.firstWhere(
      (g) => g.id == goalId,
      orElse: () => throw ArgumentError('Goal not found: $goalId'),
    );

    // 合并更新
    final newGoal = Goal(
      id: oldGoal.id,
      name: updateJson['name'] ?? oldGoal.name,
      icon: updateJson['icon'] ?? oldGoal.icon,
      iconColor: updateJson['iconColor'] ?? oldGoal.iconColor,
      unitType: updateJson['unitType'] ?? oldGoal.unitType,
      targetValue: updateJson['targetValue'] ?? oldGoal.targetValue,
      currentValue: updateJson['currentValue'] ?? oldGoal.currentValue,
      dateSettings: updateJson['dateSettings'] != null
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
    return jsonEncode(newGoal.toJson());
  }

  /// 删除目标
  Future<String> _jsDeleteGoal(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? goalId = params['goalId'];
    if (goalId == null || goalId.isEmpty) {
      return jsonEncode({'success': false, 'error': '缺少必需参数: goalId'});
    }

    try {
      await _controller.deleteGoal(goalId);
      return jsonEncode({'success': true, 'goalId': goalId});
    } catch (e) {
      return jsonEncode({'success': false, 'error': '删除失败: ${e.toString()}'});
    }
  }

  /// 记录数据
  Future<String> _jsRecordData(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? goalId = params['goalId'];
    if (goalId == null || goalId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: goalId'});
    }

    final double? value = params['value'];
    if (value == null) {
      return jsonEncode({'error': '缺少必需参数: value'});
    }

    // 提取可选参数
    final String? note = params['note'];
    final String? dateTime = params['dateTime'];

    final goals = await _controller.getAllGoals();
    final goal = goals.firstWhere(
      (g) => g.id == goalId,
      orElse: () => throw ArgumentError('Goal not found: $goalId'),
    );

    final record = Record(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      goalId: goalId,
      value: value,
      note: note,
      recordedAt: dateTime != null ? DateTime.parse(dateTime) : DateTime.now(),
    );

    await _controller.addRecord(record, goal);
    return jsonEncode(record.toJson());
  }

  /// 获取目标的记录列表
  Future<String> _jsGetRecords(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? goalId = params['goalId'];
    if (goalId == null || goalId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: goalId'});
    }

    // 提取可选参数
    final int? limit = params['limit'];

    final records = await _controller.getRecordsForGoal(goalId);

    // 按时间倒序排列
    records.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    // 如果指定了 limit，只返回最新的 N 条记录
    final List<Record> resultRecords = limit != null && limit < records.length
        ? records.sublist(0, limit)
        : records;

    return jsonEncode(resultRecords.map((r) => r.toJson()).toList());
  }

  /// 删除记录
  Future<String> _jsDeleteRecord(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? recordId = params['recordId'];
    if (recordId == null || recordId.isEmpty) {
      return jsonEncode({'success': false, 'error': '缺少必需参数: recordId'});
    }

    try {
      await _controller.deleteRecord(recordId);
      return jsonEncode({'success': true, 'recordId': recordId});
    } catch (e) {
      return jsonEncode({'success': false, 'error': '删除失败: ${e.toString()}'});
    }
  }

  /// 获取目标进度
  Future<String> _jsGetProgress(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? goalId = params['goalId'];
    if (goalId == null || goalId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: goalId'});
    }

    final goals = await _controller.getAllGoals();
    final goal = goals.firstWhere(
      (g) => g.id == goalId,
      orElse: () => throw ArgumentError('Goal not found: $goalId'),
    );

    final progress = _controller.calculateProgress(goal);

    return jsonEncode({
      'goalId': goalId,
      'currentValue': goal.currentValue,
      'targetValue': goal.targetValue,
      'progress': progress,
      'percentage': (progress * 100).toStringAsFixed(1),
      'isCompleted': goal.isCompleted,
    });
  }

  /// 获取统计信息
  Future<String> _jsGetStats(Map<String, dynamic> params) async {
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

      return jsonEncode({
        'goalId': goalId,
        'goalName': goal.name,
        'totalRecords': records.length,
        'totalValue': records.fold(0.0, (sum, r) => sum + r.value),
        'currentValue': goal.currentValue,
        'targetValue': goal.targetValue,
        'progress': _controller.calculateProgress(goal),
        'isCompleted': goal.isCompleted,
      });
    } else {
      // 返回全局统计信息
      return jsonEncode({
        'totalGoals': _controller.getGoalCount(),
        'todayCompleted': _controller.getTodayCompletedGoals(),
        'monthCompleted': _controller.getMonthCompletedGoals(),
        'monthAdded': _controller.getMonthAddedGoals(),
        'todayRecords': _controller.getTodayRecordCount(),
        'overallProgress': _controller.calculateOverallProgress(),
        'groups': _controller.getAllGroups(),
      });
    }
  }
}
