import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/plugins/habits/controllers/habit_controller.dart';
import 'package:Memento/plugins/habits/controllers/skill_controller.dart';
import 'package:Memento/plugins/habits/models/completion_record.dart';

class CompletionRecordController {
  final StorageManager storage;
  final HabitController habitController;
  final SkillController skillControlle;
  static const _recordsKey = 'habits_records';

  CompletionRecordController(
    this.storage, {
    required this.habitController,
    required this.skillControlle,
  });

  Future<void> saveCompletionRecord(
    String habitId,
    CompletionRecord record,
  ) async {
    final path = 'habits/records/$habitId.json';
    final data = await storage.readJson(path);
    final records = <CompletionRecord>[];

    if (data != null) {
      records.addAll(
        List<Map<String, dynamic>>.from(
          data as Iterable,
        ).map((e) => CompletionRecord.fromMap(e)),
      );
    }

    records.add(record);
    await storage.writeJson(path, records.map((r) => r.toMap()).toList());
  }

  getSkillHabitIds(skillId) async {
    final habits = await habitController.getHabits();
    return habits
        .where((habit) => habit.skillId == skillId)
        .map((habit) => habit.id)
        .toList();
  }

  getHabitIds() {
    final habits = habitController.getHabits();
    return habits.map((habit) => habit.id).toList();
  }

  Future<List<CompletionRecord>> getSkillCompletionRecords(
    String skillId,
  ) async {
    final matchingRecords = <CompletionRecord>[];

    // 1. 获取所有属于指定skillId的habitIds
    final skillHabitIds = await getSkillHabitIds(skillId);

    // 2. 获取这些habitIds对应的records
    for (final habitId in skillHabitIds) {
      final path = 'habits/records/$habitId.json';
      if (await storage.fileExists(path)) {
        final data = await storage.readJson(path);
        if (data != null) {
          matchingRecords.addAll(
            List<Map<String, dynamic>>.from(
              data as Iterable,
            ).map((e) => CompletionRecord.fromMap(e)),
          );
        }
      }
    }

    return matchingRecords;
  }

  Future<int> getTotalDuration(String habitId) async {
    final records = await getSkillCompletionRecords(habitId);
    return records.fold<int>(
      0,
      (sum, record) => sum + record.duration.inMinutes,
    );
  }

  Future<int> getCompletionCount(String habitId) async {
    final records = await getSkillCompletionRecords(habitId);
    return records.length;
  }

  Future<void> deleteCompletionRecord(String recordId) async {
    for (final habitId in getHabitIds()) {
      final records = await getHabitCompletionRecords(habitId);
      records.removeWhere((record) => record.id == recordId);
      await storage.writeJson(
        'habits/records/$habitId.json',
        records.map((r) => r.toMap()).toList(),
      );
    }
  }

  Future<void> clearAllCompletionRecords(String habitId) async {
    await storage.writeJson('habits/records/$habitId.json', []);
  }

  Future<List<CompletionRecord>> getHabitCompletionRecords(
    String habitId,
  ) async {
    final data = await storage.readJson('habits/records/$habitId.json');
    if (data == null) return [];

    return List<Map<String, dynamic>>.from(
      data as Iterable,
    ).map((e) => CompletionRecord.fromMap(e)).toList();
  }
}
