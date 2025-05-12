
import 'dart:async';

import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../models/record.dart';
import '../utils/date_utils.dart' as tracker_date_utils;
import '../tracker_plugin.dart';

class TrackerController with ChangeNotifier {
  List<Goal> _goals = [];
  List<Record> _records = [];

  Future<void> loadInitialData() async {
    final plugin = TrackerPlugin.instance;
    try {
      final savedGoals = await plugin.storage?.read('goals.json') ?? {};
      if (savedGoals.containsKey('goals')) {
        _goals = (savedGoals['goals'] as List).map((g) => Goal.fromJson(g)).toList();
      }
    } catch (e) {
      debugPrint('加载目标数据失败: $e');
    }

    try {
      final savedRecords = await plugin.storage?.read('records.json') ?? {};
      if (savedRecords.containsKey('records')) {
        _records = (savedRecords['records'] as List).map((r) => Record.fromJson(r)).toList();
      }
    } catch (e) {
      debugPrint('加载记录数据失败: $e');
    }
  }

  Future<void> _saveGoals() async {
    final plugin = TrackerPlugin.instance;
    try {
      await plugin.storage?.write('goals.json', {
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
      await plugin.storage?.write('records.json', {
        'records': _records.map((r) => r.toJson()).toList(),
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('保存记录数据失败: $e');
    }
  }

  List<Goal> get goals => _goals;
  List<Record> get records => _records;

  // 目标管理
  Future<void> addGoal(Goal goal) async {
    _validateGoalDates(goal);
    _goals.add(goal);
    await _saveGoals();
    notifyListeners();
  }

  Future<void> updateGoal(String id, Goal newGoal) async {
    final index = _goals.indexWhere((g) => g.id == id);
    if (index != -1) {
      _validateGoalDates(newGoal);
      _goals[index] = newGoal;
      await _saveGoals();
      notifyListeners();
    }
  }

  Future<void> toggleGoalCompletion(String id) async {
    final index = _goals.indexWhere((g) => g.id == id);
    if (index != -1) {
      final goal = _goals[index];
      _goals[index] = goal.copyWith(
        currentValue: !goal.isCompleted ? goal.targetValue : 0
      );
      await _saveGoals();
      notifyListeners();
    }
  }

  Future<void> deleteGoal(String id) async {
    _goals.removeWhere((g) => g.id == id);
    _records.removeWhere((r) => r.goalId == id);
    await _saveGoals();
    await _saveRecords();
    notifyListeners();
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
    return _records.where((r) => 
      r.recordedAt.isAfter(today)
    ).length;
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
    return Stream.fromFuture(Future.value(_records.where((r) => r.goalId == goalId).toList()))
      .asyncExpand((_) {
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
    return _goals.where((g) => 
      g.isCompleted && 
      g.createdAt.isAfter(today)
    ).length;
  }

  // 获取本月完成的目标数
  int getMonthCompletedGoals() {
    final firstDayOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    return _goals.where((g) => 
      g.isCompleted && 
      g.createdAt.isAfter(firstDayOfMonth)
    ).length;
  }

  // 获取本月新增的目标数
  int getMonthAddedGoals() {
    final firstDayOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    return _goals.where((g) => 
      g.createdAt.isAfter(firstDayOfMonth)
    ).length;
  }

  // 清空特定目标的所有记录
  Future<void> clearRecordsForGoal(String goalId) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    _records.removeWhere((r) => r.goalId == goalId);
    await _saveRecords();
    // 重置目标当前值
    await updateGoal(goalId, goal.copyWith(currentValue: 0));
    notifyListeners();
  }

  // 删除单条记录
  Future<void> deleteRecord(String recordId) async {
    final record = _records.firstWhere((r) => r.id == recordId);
    final goal = _goals.firstWhere((g) => g.id == record.goalId);
    _records.removeWhere((r) => r.id == recordId);
    await _saveRecords();
    // 更新目标当前值
    await updateGoal(goal.id, goal.copyWith(
      currentValue: goal.currentValue - record.value
    ));
    notifyListeners();
  }

  // 添加记录并更新目标值
  Future<void> addRecord(Record record, Goal goal) async {
    Record.validate(record, goal);
    _records.add(record);
    await _saveRecords();
    // 更新目标当前值
    final updatedGoal = goal.copyWith(
      currentValue: goal.currentValue + record.value
    );
    await updateGoal(goal.id, updatedGoal);
    notifyListeners();
  }
}
