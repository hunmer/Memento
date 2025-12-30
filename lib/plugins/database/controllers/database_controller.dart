import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/event/item_event_args.dart';
import 'package:Memento/plugins/database/models/database_model.dart';
import 'package:Memento/plugins/database/models/record.dart';
import 'package:Memento/plugins/database/services/database_service.dart';

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
    _notifyDatabaseEvent('updated', database);
  }

  Future<void> createDatabase(DatabaseModel database) async {
    await service.createDatabase(database);
    _notifyDatabaseEvent('added', database);
  }

  Future<void> deleteDatabase() async {
    if (currentDatabase != null) {
      final db = currentDatabase!;
      await service.deleteDatabase(currentDatabase!.id);
      _notifyDatabaseEvent('deleted', db);
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
    _notifyRecordEvent('added', record);
  }

  Future<void> updateRecord(Record record) async {
    final records = await getRecords(record.tableId);
    final index = records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      records[index] = record;
      await _saveRecords(record.tableId, records);
      _notifyRecordEvent('updated', record);
    }
  }

  Future<void> deleteRecord(String recordId) async {
    if (currentDatabase == null) return;
    final records = await getRecords(currentDatabase!.id);
    final index = records.indexWhere((r) => r.id == recordId);
    if (index != -1) {
      final record = records[index];
      records.removeWhere((r) => r.id == recordId);
      await _saveRecords(currentDatabase!.id, records);
      _notifyRecordEvent('deleted', record);
    }
  }

  Future<void> _saveRecords(String databaseId, List<Record> records) async {
    await service.plugin.storage.writeJson(
      'records_$databaseId',
      records.map((r) => r.toMap()).toList(),
    );
  }

  // 触发数据库事件
  void _notifyDatabaseEvent(String action, DatabaseModel database) {
    final eventArgs = ItemEventArgs(
      eventName: 'database_$action',
      itemId: database.id,
      title: database.name,
      action: action,
    );
    EventManager.instance.broadcast('database_$action', eventArgs);
  }

  // 触发记录事件
  void _notifyRecordEvent(String action, Record record) {
    // 从字段中获取标题，优先使用 title/name 字段
    String title = '未命名';
    if (record.fields.containsKey('title')) {
      title = record.fields['title']?.toString() ?? '未命名';
    } else if (record.fields.containsKey('name')) {
      title = record.fields['name']?.toString() ?? '未命名';
    }

    final eventArgs = ItemEventArgs(
      eventName: 'database_record_$action',
      itemId: record.id,
      title: title,
      action: action,
    );
    EventManager.instance.broadcast('database_record_$action', eventArgs);
  }
}
