import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/plugins/habits/models/completion_record.dart';

class CompletionRecordController {
  final StorageManager storage;
  static const _recordsKey = 'habits_records';

  CompletionRecordController(this.storage);

  Future<void> saveCompletionRecord(
    String habitId,
    CompletionRecord record,
  ) async {
    final path = 'habits/records/$habitId.json';
    final existingRecords = await getCompletionRecords(habitId);
    existingRecords.add(record);
    await storage.writeJson(
      path,
      existingRecords.map((r) => r.toMap()).toList(),
    );
  }

  Future<List<CompletionRecord>> getCompletionRecords(String habitId) async {
    final path = 'habits/records/$habitId.json';
    final data = await storage.readJson(path, []);
    return List<Map<String, dynamic>>.from(
      data,
    ).map((e) => CompletionRecord.fromMap(e)).toList();
  }

  Future<int> getTotalDuration(String habitId) async {
    final records = await getCompletionRecords(habitId);
    return records.fold<int>(
      0,
      (sum, record) => sum + record.duration.inMinutes,
    );
  }

  Future<int> getCompletionCount(String habitId) async {
    final records = await getCompletionRecords(habitId);
    return records.length;
  }

  Future<void> deleteCompletionRecord(String recordId) async {
    final allRecords = await storage.readJson('habits/records/all.json', {});
    for (final habitId in allRecords.keys) {
      final records = await getCompletionRecords(habitId);
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
}
