import '../models/database_model.dart';
import '../models/record.dart';
import '../services/database_service.dart';

class DatabaseController {
  final DatabaseService service;
  DatabaseModel? currentDatabase;

  DatabaseController(this.service);

  Future<void> loadDatabase(String databaseId) async {
    final databases = await service.getAllDatabases();
    currentDatabase = databases.firstWhere((db) => db.id == databaseId);
  }

  Future<void> updateDatabase(DatabaseModel database) async {
    await service.updateDatabase(database);
    currentDatabase = database;
  }

  Future<void> createDatabase(DatabaseModel database) async {
    await service.createDatabase(database);
  }

  Future<void> deleteDatabase() async {
    if (currentDatabase != null) {
      await service.deleteDatabase(currentDatabase!.id);
      currentDatabase = null;
    }
  }

  Future<List<Record>> getRecords(String databaseId) async {
    try {
      final records =
          await service.plugin.storage.readJson('records_$databaseId') ?? [];
      if (records is List) {
        return records.map((r) => Record.fromMap(r)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> createRecord(Record record) async {
    final records = await getRecords(record.tableId);
    records.add(record);
    await _saveRecords(record.tableId, records);
  }

  Future<void> updateRecord(Record record) async {
    final records = await getRecords(record.tableId);
    final index = records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      records[index] = record;
      await _saveRecords(record.tableId, records);
    }
  }

  Future<void> deleteRecord(String recordId) async {
    if (currentDatabase == null) return;
    final records = await getRecords(currentDatabase!.id);
    records.removeWhere((r) => r.id == recordId);
    await _saveRecords(currentDatabase!.id, records);
  }

  Future<void> _saveRecords(String databaseId, List<Record> records) async {
    await service.plugin.storage.writeJson(
      'records_$databaseId',
      records.map((r) => r.toMap()).toList(),
    );
  }
}
