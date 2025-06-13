import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/plugins/habits/controllers/habit_controller.dart';
import 'package:Memento/plugins/habits/models/completion_record.dart';

class CompletionRecordController {
  final StorageManager storage;
  final HabitController habitController;
  static const _recordsKey = 'habits_records';

  CompletionRecordController(this.storage, {required this.habitController});

  Future<void> saveCompletionRecord(
    String habitId,
    CompletionRecord record,
  ) async {
    final path = 'habits/records/$habitId.json';
    final data = await storage.readJson(path, []);
    final records =
        List<Map<String, dynamic>>.from(
          data,
        ).map((e) => CompletionRecord.fromMap(e)).toList();
    records.add(record);
    await storage.writeJson(path, records.map((r) => r.toMap()).toList());
  }

  Future<List<CompletionRecord>> getSkillCompletionRecords(
    String skillId,
  ) async {
    final matchingRecords = <CompletionRecord>[];

    // 1. 获取所有属于指定skillId的habitIds
    final habits = await habitController.getHabits();
    final skillHabitIds =
        habits
            .where((habit) => habit.skillId == skillId)
            .map((habit) => habit.id)
            .toList();

    // 2. 获取这些habitIds对应的records
    for (final habitId in skillHabitIds) {
      final path = 'habits/records/$habitId.json';
      if (await storage.fileExists(path)) {
        final data = await storage.readJson(path, []);
        final records =
            List<Map<String, dynamic>>.from(
              data,
            ).map((e) => CompletionRecord.fromMap(e)).toList();
        matchingRecords.addAll(records);
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
    final allRecords = await storage.readJson('habits/records/all.json', {});
    for (final habitId in allRecords.keys) {
      final records = await getSkillCompletionRecords(habitId);
      final updatedRecords = records.where((r) => r.id != recordId).toList();
      await storage.writeJson(
        'habits/records/$habitId.json',
        updatedRecords.map((r) => r.toMap()).toList(),
      );
    }
  }

  Future<void> clearAllCompletionRecords(String habitId) async {
    await storage.writeJson('habits/records/$habitId.json', []);
  }

  Future<List<CompletionRecord>> getHabitCompletionRecords(
    String habitId,
  ) async {
    return List<Map<String, dynamic>>.from(
      await storage.readJson('habits/records/$habitId.json', []),
    ).map((e) => CompletionRecord.fromMap(e)).toList();
  }
}
