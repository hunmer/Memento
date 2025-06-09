import '../models/database_model.dart';
import '../../base_plugin.dart';

class DatabaseService {
  final BasePlugin plugin;

  DatabaseService(this.plugin);

  /// 获取所有数据库
  Future<List<DatabaseModel>> getAllDatabases() async {
    try {
      final databases = await plugin.storage.readJson('databases') ?? [];
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
      'databases',
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
        'databases',
        databases.map((db) => db.toMap()).toList(),
      );
    }
  }

  /// 删除数据库
  Future<void> deleteDatabase(String databaseId) async {
    final databases = await getAllDatabases();
    databases.removeWhere((db) => db.id == databaseId);
    await plugin.storage.writeJson(
      'databases',
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
}
