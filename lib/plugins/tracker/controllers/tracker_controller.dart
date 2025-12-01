import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/event/event.dart';
import '../../../core/services/plugin_widget_sync_helper.dart';
import '../utils/date_utils.dart' as tracker_date_utils;
import '../tracker_plugin.dart';

class TrackerController with ChangeNotifier {
  List<Goal> _goals = [];
  List<Record> _records = [];

  Future<void> loadInitialData() async {
    final plugin = TrackerPlugin.instance;
    try {
      final savedGoals = await plugin.storage.read('tracker/goals.json') ?? {};
      if (savedGoals.containsKey('goals')) {
        _goals =
            (savedGoals['goals'] as List).map((g) => Goal.fromJson(g)).toList();
      }
    } catch (e) {
      debugPrint('加载目标数据失败: $e');
    }

    try {
      final savedRecords =
          await plugin.storage.read('tracker/records.json') ?? {};
      if (savedRecords.containsKey('records')) {
        _records =
            (savedRecords['records'] as List)
                .map((r) => Record.fromJson(r))
                .toList();
      }
    } catch (e) {
      debugPrint('加载记录数据失败: $e');
    }

    // 如果没有数据，插入默认数据
    if (_goals.isEmpty) {
      await _insertDefaultData();
    }
  }

  /// 插入默认数据
  Future<void> _insertDefaultData() async {
    final now = DateTime.now();
    final today = tracker_date_utils.DateUtils.startOfDay(now);

    // 创建默认目标
    final defaultGoals = [
      Goal(
        id: now.millisecondsSinceEpoch.toString(),
        name: '每日阅读',
        icon: '57455', // book icon
        iconColor: 0xFF2196F3, // 蓝色
        unitType: '分钟',
        targetValue: 30,
        currentValue: 15,
        dateSettings: DateSettings(type: 'daily'),
        reminderTime: '09:00',
        isLoopReset: true,
        createdAt: today,
        group: '学习',
        progressColor: 0xFF2196F3,
      ),
      Goal(
        id: (now.millisecondsSinceEpoch + 1).toString(),
        name: '每日运动',
        icon: '58718', // fitness icon
        iconColor: 0xFF4CAF50, // 绿色
        unitType: '分钟',
        targetValue: 30,
        currentValue: 0,
        dateSettings: DateSettings(type: 'daily'),
        reminderTime: '18:00',
        isLoopReset: true,
        createdAt: today,
        group: '健康',
        progressColor: 0xFF4CAF50,
      ),
      Goal(
        id: (now.millisecondsSinceEpoch + 2).toString(),
        name: '每日喝水',
        icon: '59817', // water drop icon
        iconColor: 0xFF00BCD4, // 青色
        unitType: '杯',
        targetValue: 8,
        currentValue: 3,
        dateSettings: DateSettings(type: 'daily'),
        isLoopReset: true,
        createdAt: today,
        group: '健康',
        progressColor: 0xFF00BCD4,
      ),
      Goal(
        id: (now.millisecondsSinceEpoch + 3).toString(),
        name: '每周跑步',
        icon: '58718', // directions run icon
        iconColor: 0xFFFF9800, // 橙色
        unitType: '公里',
        targetValue: 10,
        currentValue: 3.5,
        dateSettings: DateSettings(
          type: 'weekly',
          selectedDays: ['Monday', 'Wednesday', 'Friday'],
        ),
        isLoopReset: true,
        createdAt: today,
        group: '健康',
        progressColor: 0xFFFF9800,
      ),
    ];

    _goals = defaultGoals;

    // 创建默认记录
    final defaultRecords = [
      // 阅读记录
      Record(
        id: now.millisecondsSinceEpoch.toString(),
        goalId: defaultGoals[0].id,
        value: 15,
        note: '阅读技术文档',
        recordedAt: today.add(const Duration(hours: 9, minutes: 30)),
      ),
      // 喝水记录
      Record(
        id: (now.millisecondsSinceEpoch + 1).toString(),
        goalId: defaultGoals[2].id,
        value: 1,
        note: '早晨第一杯水',
        recordedAt: today.add(const Duration(hours: 7)),
      ),
      Record(
        id: (now.millisecondsSinceEpoch + 2).toString(),
        goalId: defaultGoals[2].id,
        value: 1,
        recordedAt: today.add(const Duration(hours: 10)),
      ),
      Record(
        id: (now.millisecondsSinceEpoch + 3).toString(),
        goalId: defaultGoals[2].id,
        value: 1,
        recordedAt: today.add(const Duration(hours: 14)),
      ),
      // 跑步记录
      Record(
        id: (now.millisecondsSinceEpoch + 4).toString(),
        goalId: defaultGoals[3].id,
        value: 3.5,
        note: '晨跑',
        recordedAt: today.add(const Duration(hours: 6, minutes: 30)),
        durationSeconds: 1800, // 30分钟
      ),
    ];

    _records = defaultRecords;

    // 保存到存储
    await _saveGoals();
    await _saveRecords();

    debugPrint('已插入默认数据: ${_goals.length} 个目标, ${_records.length} 条记录');
  }

  Future<void> _saveGoals() async {
    final plugin = TrackerPlugin.instance;
    try {
      await plugin.storage.write('tracker/goals.json', {
        'goals': _goals.map((g) => g.toJson()).toList(),
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('保存目标数据失败: $e');
    }
  }

  Future<void> _saveRecords() async {
    final plugin = TrackerPlugin.instance;
    try {
      await plugin.storage.write('tracker/records.json', {
        'records': _records.map((r) => r.toJson()).toList(),
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('保存记录数据失败: $e');
    }
  }

  List<Goal> get goals => _goals;
  List<Record> get records => _records;

  // 获取所有分组
  List<String> getAllGroups() {
    final groups = _goals.map((goal) => goal.group).toSet().toList();
    groups.sort(); // 排序
    return groups;
  }

  // 目标管理
  Future<void> addGoal(Goal goal) async {
    _validateGoalDates(goal);
    _goals.add(goal);
    await _saveGoals();
    notifyListeners();

    // 同步小组件数据
    await PluginWidgetSyncHelper.instance.syncTracker();
  }

  Future<void> updateGoal(String id, Goal newGoal) async {
    final index = _goals.indexWhere((g) => g.id == id);
    if (index != -1) {
      _validateGoalDates(newGoal);
      _goals[index] = newGoal;
      await _saveGoals();
      notifyListeners();

      // 同步小组件数据
      await PluginWidgetSyncHelper.instance.syncTracker();
    }
  }

  Future<void> toggleGoalCompletion(String id) async {
    final index = _goals.indexWhere((g) => g.id == id);
    if (index != -1) {
      final goal = _goals[index];
      _goals[index] = goal.copyWith(
        currentValue: !goal.isCompleted ? goal.targetValue : 0,
      );
      await _saveGoals();
      notifyListeners();

      // 同步小组件数据
      await PluginWidgetSyncHelper.instance.syncTracker();
    }
  }

  Future<void> deleteGoal(String id) async {
    // 检查目标是否存在
    final goalExists = _goals.any((g) => g.id == id);
    if (!goalExists) {
      throw ArgumentError('目标不存在: $id');
    }

    _goals.removeWhere((g) => g.id == id);
    _records.removeWhere((r) => r.goalId == id);
    await _saveGoals();
    await _saveRecords();
    notifyListeners();

    // 同步小组件数据
    await PluginWidgetSyncHelper.instance.syncTracker();
  }

  // 进度计算
  double calculateProgress(Goal goal) {
    return goal.currentValue / goal.targetValue;
  }

  // 日期验证
  void _validateGoalDates(Goal goal) {
    final settings = goal.dateSettings;
    if (settings.type == 'range' &&
        settings.startDate != null &&
        settings.endDate != null &&
        settings.startDate!.isAfter(settings.endDate!)) {
      throw ArgumentError('End date must be after start date');
    }
    // 其他验证规则...
  }

  // 获取今日记录数
  int getTodayRecordCount() {
    final today = tracker_date_utils.DateUtils.startOfDay(DateTime.now());
    return _records.where((r) => r.recordedAt.isAfter(today)).length;
  }

  // 获取所有目标
  Future<List<Goal>> getAllGoals() async {
    return _goals;
  }

  // 按状态筛选目标
  Future<List<Goal>> getGoalsByStatus(String status) async {
    switch (status) {
      case 'active':
        return _goals.where((g) => !g.isCompleted).toList();
      case 'completed':
        return _goals.where((g) => g.isCompleted).toList();
      default:
        return _goals;
    }
  }

  // 计算总体进度
  double calculateOverallProgress() {
    if (_goals.isEmpty) return 0;

    final completedGoals = _goals.where((g) => g.isCompleted).length;
    return completedGoals / _goals.length;
  }

  // 获取目标总数
  int getGoalCount() {
    return _goals.length;
  }

  // 获取特定目标的记录流
  Stream<List<Record>> watchRecordsForGoal(String goalId) {
    return Stream.fromFuture(
      Future.value(_records.where((r) => r.goalId == goalId).toList()),
    ).asyncExpand((_) {
      final controller = StreamController<List<Record>>();
      void update() {
        controller.add(_records.where((r) => r.goalId == goalId).toList());
      }

      addListener(update);
      controller.onCancel = () => removeListener(update);
      return controller.stream;
    });
  }

  // 获取特定目标的记录
  Future<List<Record>> getRecordsForGoal(String goalId) async {
    return _records.where((r) => r.goalId == goalId).toList();
  }

  // 获取今日完成的目标数
  int getTodayCompletedGoals() {
    final today = tracker_date_utils.DateUtils.startOfDay(DateTime.now());
    return _goals
        .where((g) => g.isCompleted && g.createdAt.isAfter(today))
        .length;
  }

  // 获取本月完成的目标数
  int getMonthCompletedGoals() {
    final firstDayOfMonth = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      1,
    );
    return _goals
        .where((g) => g.isCompleted && g.createdAt.isAfter(firstDayOfMonth))
        .length;
  }

  // 获取本月新增的目标数
  int getMonthAddedGoals() {
    final firstDayOfMonth = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      1,
    );
    return _goals.where((g) => g.createdAt.isAfter(firstDayOfMonth)).length;
  }

  // 清空特定目标的所有记录
  Future<void> clearRecordsForGoal(String goalId) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    _records.removeWhere((r) => r.goalId == goalId);
    await _saveRecords();
    // 重置目标当前值
    await updateGoal(goalId, goal.copyWith(currentValue: 0));
    notifyListeners();

    // 同步小组件数据（updateGoal 已经调用了同步，这里不需要重复调用）
  }

  // 删除单条记录
  Future<void> deleteRecord(String recordId) async {
    final record = _records.firstWhere(
      (r) => r.id == recordId,
      orElse: () => throw ArgumentError('记录不存在: $recordId'),
    );
    final goal = _goals.firstWhere(
      (g) => g.id == record.goalId,
      orElse: () => throw ArgumentError('目标不存在: ${record.goalId}'),
    );
    _records.removeWhere((r) => r.id == recordId);
    await _saveRecords();
    // 更新目标当前值
    await updateGoal(
      goal.id,
      goal.copyWith(currentValue: goal.currentValue - record.value),
    );
    notifyListeners();

    // 同步小组件数据（updateGoal 已经调用了同步，这里不需要重复调用）
  }

  // 添加记录并更新目标值
  Future<void> addRecord(Record record, Goal goal) async {
    Record.validate(record, goal);
    _records.add(record);
    await _saveRecords();
    // 更新目标当前值
    final updatedGoal = goal.copyWith(
      currentValue: goal.currentValue + record.value,
    );
    await updateGoal(goal.id, updatedGoal);

    // 广播记录添加事件
    eventManager.broadcast('onRecordAdded', Value<Record>(record));

    notifyListeners();

    // 同步小组件数据（updateGoal 已经调用了同步，这里不需要重复调用）
  }
}
