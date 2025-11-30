import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/core/services/plugin_widget_sync_helper.dart';
import 'package:Memento/plugins/habits/models/habit.dart';
import 'package:Memento/plugins/habits/controllers/timer_controller.dart';
import 'package:flutter/foundation.dart';

typedef TimerModeListener = void Function(String habitId, bool isCountdown);

class HabitController {
  final List<TimerModeListener> _timerModeListeners = [];
  final StorageManager storage;
  final TimerController timerController;
  static const _habitsKey = 'habits/habits';
  List<Habit> _habits = [];
  HabitController(this.storage, {required this.timerController}) {
    loadHabits();
  }

  Future<List<Habit>> loadHabits() async {
    try {
      final data = await storage.readJson(_habitsKey, []);

      List<Map<String, dynamic>> habitMaps = [];
      if (data is List) {
        habitMaps = List<Map<String, dynamic>>.from(
          data.whereType<Map>().where((m) => m.isNotEmpty),
        );
      } else if (data is Map) {
        // 如果数据是Map格式，可能存储结构有问题
        if (data.containsKey('habits')) {
          final habitsData = data['habits'];
          if (habitsData is List) {
            habitMaps = List<Map<String, dynamic>>.from(
              habitsData.whereType<Map>().where((m) => m.isNotEmpty),
            );
          }
        }
      }

      _habits =
          habitMaps
              .map((e) => Habit.fromMap(e))
              .where((h) => h != null)
              .toList();

      return _habits;
    } catch (e) {
      print('Error loading habits: $e');
      return _habits = [];
    }
  }

  List<Habit> getHabits() => _habits;

  Future<void> saveHabit(Habit habit) async {
    final habits = getHabits();
    final index = habits.indexWhere((h) => h.id == habit.id);

    if (index >= 0) {
      habits[index] = habit;
    } else {
      habits.add(habit);
    }

    await storage.writeJson(_habitsKey, habits.map((h) => h.toMap()).toList());

    // 同步到小组件
    await _syncWidget();
  }

  Future<void> deleteHabit(String id) async {
    final habits = getHabits();
    habits.removeWhere((h) => h.id == id);
    await storage.writeJson(_habitsKey, habits.map((h) => h.toMap()).toList());

    // 同步到小组件
    await _syncWidget();
  }

  void addTimerModeListener(TimerModeListener listener) {
    _timerModeListeners.add(listener);
  }

  void removeTimerModeListener(TimerModeListener listener) {
    _timerModeListeners.remove(listener);
  }

  void notifyTimerModeChanged(String habitId, bool isCountdown) {
    for (final listener in _timerModeListeners) {
      listener(habitId, isCountdown);
    }
  }

  // 同步小组件数据
  Future<void> _syncWidget() async {
    await PluginWidgetSyncHelper.instance.syncHabits();
  }
}
