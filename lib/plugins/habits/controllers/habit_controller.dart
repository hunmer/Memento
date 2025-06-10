import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/plugins/habits/models/habit.dart';

class HabitController {
  final StorageManager storage;

  HabitController(this.storage);

  Future<List<Habit>> getHabits() async {
    final data = await storage.readJson('habits/habits', []);
    return List<Map<String, dynamic>>.from(
      data,
    ).map((e) => Habit.fromMap(e)).toList();
  }

  Future<void> saveHabit(Habit habit) async {
    final habits = await getHabits();
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
    final habits = await getHabits();
    habits.removeWhere((h) => h.id == id);
    await storage.writeJson(
      'habits/habits',
      habits.map((h) => h.toMap()).toList(),
    );
  }
}
