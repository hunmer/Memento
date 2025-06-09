import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/plugins/habits/models/completion_record.dart';

class CompletionRecordController {
  final StorageManager storage;
  static const _recordsKey = 'habits_records';

  CompletionRecordController(this.storage);

  Future<Map<String, List<CompletionRecord>>> _getAllRecords() async {
    final data = await storage.read(_recordsKey, {});
    return data.map(
      (parentId, records) => MapEntry(
        parentId,
        (records as List).map((e) => CompletionRecord.fromMap(e)).toList(),
      ),
    );
  }

  Future<List<CompletionRecord>> getRecordsByParent(String parentId) async {
    final allRecords = await _getAllRecords();
    return allRecords[parentId] ?? [];
  }

  Future<void> saveRecord(CompletionRecord record) async {
    final allRecords = await _getAllRecords();
    final records = allRecords[record.parentId] ?? [];
    final index = records.indexWhere((r) => r.id == record.id);

    if (index >= 0) {
      records[index] = record;
    } else {
      records.add(record);
    }

    allRecords[record.parentId] = records;
    await storage.write(
      _recordsKey,
      allRecords.map((k, v) => MapEntry(k, v.map((r) => r.toMap()).toList())),
    );
  }

  Future<void> deleteRecord(String id, String parentId) async {
    final allRecords = await _getAllRecords();
    final records = allRecords[parentId] ?? [];
    records.removeWhere((r) => r.id == id);

    if (records.isEmpty) {
      allRecords.remove(parentId);
    } else {
      allRecords[parentId] = records;
    }

    await storage.write(
      _recordsKey,
      allRecords.map((k, v) => MapEntry(k, v.map((r) => r.toMap()).toList())),
    );
  }

  Future<int> getTotalDuration(String parentId) async {
    final records = await getRecordsByParent(parentId);
    return records.fold<int>(0, (sum, record) => sum + record.durationMinutes);
  }

  Future<int> getCompletionCount(String parentId) async {
    final records = await getRecordsByParent(parentId);
    return records.length;
  }
}
