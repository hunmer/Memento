import 'package:Memento/plugins/database/models/database_model.dart';
import 'package:Memento/plugins/base_plugin.dart';

class DatabaseService {
  final BasePlugin plugin;
  final storekey = 'databases/databases';
  DatabaseService(this.plugin);

  /// 获取所有数据库
  Future<List<DatabaseModel>> getAllDatabases() async {
    try {
      final databases = await plugin.storage.readJson(storekey) ?? [];
      if (databases is List) {
        return databases.map((db) => DatabaseModel.fromMap(db)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 创建新数据库
  Future<void> createDatabase(DatabaseModel database) async {
    final databases = await getAllDatabases();
    databases.add(database);
    await plugin.storage.writeJson(
      storekey,
      databases.map((db) => db.toMap()).toList(),
    );
  }

  /// 更新数据库
  Future<void> updateDatabase(DatabaseModel database) async {
    final databases = await getAllDatabases();
    final index = databases.indexWhere((db) => db.id == database.id);
    if (index != -1) {
      databases[index] = database;
      await plugin.storage.writeJson(
        storekey,
        databases.map((db) => db.toMap()).toList(),
      );
    }
  }

  /// 删除数据库
  Future<void> deleteDatabase(String databaseId) async {
    final databases = await getAllDatabases();
    databases.removeWhere((db) => db.id == databaseId);
    await plugin.storage.writeJson(
      storekey,
      databases.map((db) => db.toMap()).toList(),
    );
  }

  /// 初始化默认数据
  Future<void> initializeDefaultData() async {
    try {
      final databases = await getAllDatabases();
      if (databases.isEmpty || !databases.any((db) => db.id == 'default_db')) {
        final defaultDb = DatabaseModel(
          id: 'default_db',
          name: 'Default Database',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await createDatabase(defaultDb);
      }
    } catch (e) {
      // 确保即使出错也有默认数据库
      final defaultDb = DatabaseModel(
        id: 'default_db',
        name: 'Default Database',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await createDatabase(defaultDb);
    }
  }

  /// 获取数据库数量
  Future<int> getDatabaseCount() async {
    try {
      final databases = await getAllDatabases();
      return databases.length;
    } catch (e) {
      return 0;
    }
  }

  /// 获取今日新增记录数（所有数据库）
  Future<int> getTodayRecordCount(dynamic controller) async {
    try {
      final databases = await getAllDatabases();
      int todayCount = 0;
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      for (final db in databases) {
        final records = await controller.getRecords(db.id);
        final filteredRecords = records.where((record) {
          final recordDate = DateTime(
            record.createdAt.year,
            record.createdAt.month,
            record.createdAt.day,
          );
          return recordDate.isAtSameMomentAs(todayDate);
        }).toList();
        todayCount += filteredRecords.length as int;
      }

      return todayCount;
    } catch (e) {
      return 0;
    }
  }

  /// 获取总记录数（所有数据库）
  Future<int> getTotalRecordCount(dynamic controller) async {
    try {
      final databases = await getAllDatabases();
      int totalCount = 0;

      for (final db in databases) {
        final records = await controller.getRecords(db.id);
        totalCount += records.length as int;
      }

      return totalCount;
    } catch (e) {
      return 0;
    }
  }
}
