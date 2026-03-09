import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/core/app_initializer.dart';
import '../models/reminder.dart';

/// 提醒管理服务
/// 负责提醒的 CRUD 操作和数据持久化
class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  static const String _storageKey = 'reminders.json';

  List<Reminder> _reminders = [];

  List<Reminder> get reminders => List.unmodifiable(_reminders);

  /// 初始化服务，从存储加载数据
  Future<void> initialize() async {
    await _loadReminders();
  }

  /// 加载提醒数据
  Future<void> _loadReminders() async {
    try {
      final pluginPath = 'reminder/$_storageKey';
      final data = await globalStorage.readJson(pluginPath);
      if (data != null && data.containsKey('reminders')) {
        _reminders =
            (data['reminders'] as List)
                .map((json) => Reminder.fromJson(json as Map<String, dynamic>))
                .toList();
      }
    } catch (e) {
      debugPrint('[ReminderService] 加载提醒失败: $e');
      _reminders = [];
    }
  }

  /// 保存提醒数据
  Future<void> _saveReminders() async {
    try {
      final pluginPath = 'reminder/$_storageKey';
      final data = {'reminders': _reminders.map((r) => r.toJson()).toList()};
      await globalStorage.writeJson(pluginPath, data);
    } catch (e) {
      debugPrint('[ReminderService] 保存提醒失败: $e');
      rethrow;
    }
  }

  /// 添加提醒
  Future<Reminder> addReminder({
    required String title,
    required String content,
    String? imageUrl,
    required ReminderFrequency frequency,
    List<int> selectedDays = const [],
    required TimeOfDay time,
    ReminderPushMethod pushMethod = ReminderPushMethod.localNotification,
    String? groupId,
    int priority = 0,
  }) async {
    final reminder = Reminder(
      id: const Uuid().v4(),
      title: title,
      content: content,
      imageUrl: imageUrl,
      frequency: frequency,
      selectedDays: selectedDays,
      time: time,
      pushMethod: pushMethod,
      createdAt: DateTime.now(),
      nextTriggerAt: null, // 将在 scheduler 中计算
      groupId: groupId,
      priority: priority,
    );

    // 计算下次触发时间
    reminder.nextTriggerAt = reminder.calculateNextTriggerTime();

    _reminders.add(reminder);
    await _saveReminders();

    return reminder;
  }

  /// 更新提醒
  Future<void> updateReminder(Reminder reminder) async {
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      // 重新计算下次触发时间
      reminder.nextTriggerAt = reminder.calculateNextTriggerTime();
      _reminders[index] = reminder;
      await _saveReminders();
    }
  }

  /// 删除提醒
  Future<void> deleteReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    await _saveReminders();
  }

  /// 切换启用状态
  Future<void> toggleReminder(String id) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reminders[index] = _reminders[index].copyWith(
        isEnabled: !_reminders[index].isEnabled,
      );
      await _saveReminders();
    }
  }

  /// 获取启用的提醒列表
  List<Reminder> getEnabledReminders() {
    return _reminders.where((r) => r.isEnabled).toList();
  }

  /// 标记提醒已触发
  Future<void> markTriggered(String id) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      final reminder = _reminders[index];
      _reminders[index] = reminder.copyWith(
        lastTriggeredAt: DateTime.now(),
        nextTriggerAt: reminder.calculateNextTriggerTime(),
      );
      await _saveReminders();
    }
  }

  /// 根据 ID 获取提醒
  Reminder? getReminderById(String id) {
    try {
      return _reminders.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 刷新数据（重新加载）
  Future<void> refresh() async {
    await _loadReminders();
  }
}
