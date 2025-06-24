import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/plugins/habits/models/habit.dart';
import 'package:Memento/plugins/habits/controllers/timer_controller.dart';

typedef TimerModeListener = void Function(String habitId, bool isCountdown);

class HabitController {
  final List<TimerModeListener> _timerModeListeners = [];
  final StorageManager storage;
  final TimerController timerController;
  List<Habit> _habits = [];
  HabitController(this.storage, {required this.timerController}) {
    loadHabits();
  }

  Future<List<Habit>> loadHabits() async {
    try {
      final data = await storage.readJson('habits/habits', []);
      List<Map<String, dynamic>> habitMaps = [];
      if (data is List) {
        habitMaps = List<Map<String, dynamic>>.from(
          data.whereType<Map>().where((m) => m.isNotEmpty),
        );
      }
      _habits =
          habitMaps
              .map((e) => Habit.fromMap(e))
              .where((h) => h != null)
              .toList();
      return _habits;
    } catch (e) {
      print('Error loading habits: $e');
      return [];
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

    await storage.writeJson(
      'habits/habits',
      habits.map((h) => h.toMap()).toList(),
    );
  }

  Future<void> deleteHabit(String id) async {
    final habits = getHabits();
    habits.removeWhere((h) => h.id == id);
    await storage.writeJson(
      'habits/habits',
      habits.map((h) => h.toMap()).toList(),
    );
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
}
