import 'dart:convert';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:flutter/material.dart';
import '../base_plugin.dart';
import './l10n/database_localizations.dart';
import './models/database_model.dart';
import './models/database_field.dart';
import './models/record.dart';
import './services/database_service.dart';
import './widgets/database_list_widget.dart';
import './controllers/database_controller.dart';

/// 数据库插件主视图
class DatabaseMainView extends StatefulWidget {
  const DatabaseMainView({super.key});
  @override
  State<DatabaseMainView> createState() => _DatabaseMainViewState();
}

class _DatabaseMainViewState extends State<DatabaseMainView> {
  late DatabasePlugin _plugin;
  @override
  Widget build(BuildContext context) {
    _plugin = DatabasePlugin.instance;
    return DatabaseListWidget(service: _plugin.service);
  }
}

class DatabasePlugin extends BasePlugin with JSBridgePlugin {
  late final DatabaseService service = DatabaseService(this);
  late final DatabaseController controller = DatabaseController(service);

  @override
  String get id => 'database';

  @override
  IconData get icon => Icons.storage;

  @override
  Color get color => Colors.deepPurple;

  static DatabasePlugin? _instance;
  static DatabasePlugin get instance {
    if (_instance == null) {
      _instance =
          PluginManager.instance.getPlugin('database') as DatabasePlugin?;
      if (_instance == null) {
        throw StateError('DatabasePlugin has not been initialized');
      }
    }
    return _instance!;
  }

  @override
  Future<void> initialize() async {
    await service.initializeDefaultData();
    // 注册 JS API（最后一步）
    await registerJSAPI();
  }

  @override
  Widget buildMainView(BuildContext context) {
    return DatabaseMainView();
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    await initialize();
  }

  @override
  String? getPluginName(context) {
    return DatabaseLocalizations.of(context).name;
  }

  @override
  Widget? buildCardView(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: FutureBuilder<int>(
        future: service.getDatabaseCount(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final dbCount = snapshot.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部图标和标题
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 24, color: color),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    DatabaseLocalizations.of(context).name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 统计信息
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            DatabaseLocalizations.of(
                              context,
                            ).totalDatabasesCount,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '$dbCount',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ==================== JS API 定义 ====================

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 数据库管理
      'getDatabases': _jsGetDatabases,
      'createDatabase': _jsCreateDatabase,
      'updateDatabase': _jsUpdateDatabase,
      'deleteDatabase': _jsDeleteDatabase,

      // 记录管理
      'getRecords': _jsGetRecords,
      'createRecord': _jsCreateRecord,
      'updateRecord': _jsUpdateRecord,
      'deleteRecord': _jsDeleteRecord,

      // 查询功能
      'query': _jsQuery,

      // 统计功能
      'getCount': _jsGetCount,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取所有数据库
  Future<String> _jsGetDatabases(Map<String, dynamic> params) async {
    final databases = await service.getAllDatabases();
    return jsonEncode(databases.map((db) => db.toMap()).toList());
  }

  /// 创建数据库
  Future<String> _jsCreateDatabase(Map<String, dynamic> params) async {
    // 必需参数
    final String? name = params['name'];
    if (name == null) {
      return jsonEncode({'error': '缺少必需参数: name'});
    }

    // 可选参数
    final String? description = params['description'];
    final String? fieldsJson = params['fieldsJson'];

    // 解析字段
    List<DatabaseField> fields = [];
    if (fieldsJson != null && fieldsJson.isNotEmpty) {
      try {
        final fieldsList = jsonDecode(fieldsJson) as List;
        fields = fieldsList
            .map((f) => DatabaseField.fromMap(f as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // 字段解析失败，使用空列表
      }
    }

    final database = DatabaseModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      fields: fields,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await service.createDatabase(database);
    return jsonEncode(database.toMap());
  }

  /// 更新数据库
  Future<String> _jsUpdateDatabase(Map<String, dynamic> params) async {
    // 必需参数
    final String? databaseId = params['databaseId'];
    if (databaseId == null) {
      return jsonEncode({'error': '缺少必需参数: databaseId'});
    }

    // 可选参数
    final String? name = params['name'];
    final String? description = params['description'];
    final String? fieldsJson = params['fieldsJson'];

    final databases = await service.getAllDatabases();
    final database = databases.firstWhere((db) => db.id == databaseId);

    // 解析字段（如果提供）
    List<DatabaseField>? fields;
    if (fieldsJson != null && fieldsJson.isNotEmpty) {
      try {
        final fieldsList = jsonDecode(fieldsJson) as List;
        fields = fieldsList
            .map((f) => DatabaseField.fromMap(f as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // 字段解析失败，保持原字段
      }
    }

    final updatedDatabase = database.copyWith(
      name: name,
      description: description,
      fields: fields,
      updatedAt: DateTime.now(),
    );

    await service.updateDatabase(updatedDatabase);
    return jsonEncode(updatedDatabase.toMap());
  }

  /// 删除数据库
  Future<String> _jsDeleteDatabase(Map<String, dynamic> params) async {
    try {
      // 必需参数
      final String? databaseId = params['databaseId'];
      if (databaseId == null) {
        return jsonEncode({'success': false, 'error': '缺少必需参数: databaseId'});
      }

      await service.deleteDatabase(databaseId);
      return jsonEncode({'success': true, 'databaseId': databaseId});
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// 获取数据库的所有记录
  Future<String> _jsGetRecords(Map<String, dynamic> params) async {
    // 必需参数
    final String? databaseId = params['databaseId'];
    if (databaseId == null) {
      return jsonEncode({'error': '缺少必需参数: databaseId'});
    }

    // 可选参数
    final int? limit = params['limit'];

    var records = await controller.getRecords(databaseId);

    // 如果指定了 limit，只返回最新的 N 条记录
    if (limit != null && limit < records.length) {
      records = records.sublist(records.length - limit);
    }

    return jsonEncode(records.map((r) => r.toMap()).toList());
  }

  /// 创建记录
  Future<String> _jsCreateRecord(Map<String, dynamic> params) async {
    // 必需参数
    final String? databaseId = params['databaseId'];
    final String? fieldsJson = params['fieldsJson'];

    if (databaseId == null) {
      return jsonEncode({'error': '缺少必需参数: databaseId'});
    }
    if (fieldsJson == null) {
      return jsonEncode({'error': '缺少必需参数: fieldsJson'});
    }

    // 可选参数 - 自定义ID
    final String? id = params['id'];

    // 解析字段数据
    Map<String, dynamic> fields;
    try {
      fields = jsonDecode(fieldsJson) as Map<String, dynamic>;
    } catch (e) {
      return jsonEncode({'error': 'Invalid fields JSON: $fieldsJson'});
    }

    // 检查自定义ID是否已存在
    if (id != null && id.isNotEmpty) {
      try {
        final existingRecords = await controller.getRecords(databaseId);
        final existingRecord = existingRecords.where((r) => r.id == id).firstOrNull;
        if (existingRecord != null) {
          return jsonEncode({'success': false, 'error': '记录ID已存在: $id'});
        }
      } catch (e) {
        // 如果获取记录失败，继续创建
      }
    }

    final record = Record(
      id: (id != null && id.isNotEmpty) ? id : DateTime.now().millisecondsSinceEpoch.toString(),
      tableId: databaseId,
      fields: fields,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await controller.createRecord(record);
    return jsonEncode(record.toMap());
  }

  /// 更新记录
  Future<String> _jsUpdateRecord(Map<String, dynamic> params) async {
    // 必需参数
    final String? databaseId = params['databaseId'];
    final String? recordId = params['recordId'];
    final String? fieldsJson = params['fieldsJson'];

    if (databaseId == null) {
      return jsonEncode({'error': '缺少必需参数: databaseId'});
    }
    if (recordId == null) {
      return jsonEncode({'error': '缺少必需参数: recordId'});
    }
    if (fieldsJson == null) {
      return jsonEncode({'error': '缺少必需参数: fieldsJson'});
    }

    final records = await controller.getRecords(databaseId);
    final record = records.firstWhere((r) => r.id == recordId);

    // 解析更新的字段
    Map<String, dynamic> updatedFields;
    try {
      updatedFields = jsonDecode(fieldsJson) as Map<String, dynamic>;
    } catch (e) {
      return jsonEncode({'error': 'Invalid fields JSON: $fieldsJson'});
    }

    // 合并现有字段和更新字段
    final mergedFields = Map<String, dynamic>.from(record.fields);
    mergedFields.addAll(updatedFields);

    final updatedRecord = record.copyWith(
      fields: mergedFields,
      updatedAt: DateTime.now(),
    );

    await controller.updateRecord(updatedRecord);
    return jsonEncode(updatedRecord.toMap());
  }

  /// 删除记录
  Future<String> _jsDeleteRecord(Map<String, dynamic> params) async {
    try {
      // 必需参数
      final String? databaseId = params['databaseId'];
      final String? recordId = params['recordId'];

      if (databaseId == null) {
        return jsonEncode({'success': false, 'error': '缺少必需参数: databaseId'});
      }
      if (recordId == null) {
        return jsonEncode({'success': false, 'error': '缺少必需参数: recordId'});
      }

      // 先加载数据库到 controller
      await controller.loadDatabase(databaseId);
      await controller.deleteRecord(recordId);
      return jsonEncode({'success': true, 'databaseId': databaseId, 'recordId': recordId});
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// 查询记录
  Future<String> _jsQuery(Map<String, dynamic> params) async {
    // 必需参数
    final String? databaseId = params['databaseId'];
    if (databaseId == null) {
      return jsonEncode({'error': '缺少必需参数: databaseId'});
    }

    // 可选参数
    final String? filtersJson = params['filtersJson'];

    var records = await controller.getRecords(databaseId);

    // 如果提供了过滤条件，应用过滤
    if (filtersJson != null && filtersJson.isNotEmpty) {
      try {
        final filters = jsonDecode(filtersJson) as Map<String, dynamic>;

        records = records.where((record) {
          // 检查所有过滤条件是否匹配
          for (var entry in filters.entries) {
            final fieldName = entry.key;
            final expectedValue = entry.value;

            // 如果记录没有该字段，或字段值不匹配，则排除
            if (!record.fields.containsKey(fieldName) ||
                record.fields[fieldName] != expectedValue) {
              return false;
            }
          }
          return true;
        }).toList();
      } catch (e) {
        // 过滤条件解析失败，返回所有记录
      }
    }

    return jsonEncode(records.map((r) => r.toMap()).toList());
  }

  /// 获取数据库或记录数量
  Future<int> _jsGetCount(Map<String, dynamic> params) async {
    // 必需参数
    final String? type = params['type'];
    if (type == null) {
      return 0;
    }

    // 可选参数
    final String? databaseId = params['databaseId'];

    if (type == 'databases') {
      return await service.getDatabaseCount();
    } else if (type == 'records' && databaseId != null) {
      final records = await controller.getRecords(databaseId);
      return records.length;
    }
    return 0;
  }
}
