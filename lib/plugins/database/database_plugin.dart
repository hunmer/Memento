import 'dart:convert';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/base_plugin.dart';
import 'package:get/get.dart';
import './models/database_model.dart';
import './services/database_service.dart';
import './widgets/database_list_widget.dart';
import './controllers/database_controller.dart';
import './repositories/client_database_repository.dart';
import 'package:shared_models/shared_models.dart';

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
  late final ClientDatabaseRepository repository;
  late final DatabaseUseCase useCase;

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

    // 初始化 UseCase 架构
    repository = ClientDatabaseRepository(
      service: service,
      controller: controller,
    );
    useCase = DatabaseUseCase(repository);

    // 注册数据选择器
    _registerDataSelectors();
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
    // 插件已在 initialize() 中完成初始化
    // 这里可以添加额外的应用级注册逻辑
  }

  @override
  String? getPluginName(context) {
    return 'database_name'.tr;
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
                    'database_name'.tr,
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
                            'database_totalDatabasesCount'.tr,
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

      // 数据库查找方法
      'findDatabaseBy': _jsFindDatabaseBy,
      'findDatabaseById': _jsFindDatabaseById,
      'findDatabaseByName': _jsFindDatabaseByName,

      // 记录查找方法
      'findRecordBy': _jsFindRecordBy,
      'findRecordById': _jsFindRecordById,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取所有数据库
  /// 支持分页参数: offset, count
  Future<String> _jsGetDatabases(Map<String, dynamic> params) async {
    final result = await useCase.getDatabases(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull);
  }

  /// 创建数据库
  Future<String> _jsCreateDatabase(Map<String, dynamic> params) async {
    final result = await useCase.createDatabase(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull);
  }

  /// 更新数据库
  Future<String> _jsUpdateDatabase(Map<String, dynamic> params) async {
    final result = await useCase.updateDatabase(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull);
  }

  /// 删除数据库
  Future<String> _jsDeleteDatabase(Map<String, dynamic> params) async {
    final result = await useCase.deleteDatabase(params);

    if (result.isFailure) {
      return jsonEncode({'success': false, 'error': result.errorOrNull?.message});
    }

    return jsonEncode({'success': true});
  }

  /// 获取数据库的所有记录
  /// 支持分页参数: offset, count
  Future<String> _jsGetRecords(Map<String, dynamic> params) async {
    final result = await useCase.getRecords(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull);
  }

  /// 创建记录
  Future<String> _jsCreateRecord(Map<String, dynamic> params) async {
    final result = await useCase.createRecord(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull);
  }

  /// 更新记录
  Future<String> _jsUpdateRecord(Map<String, dynamic> params) async {
    final result = await useCase.updateRecord(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull);
  }

  /// 删除记录
  Future<String> _jsDeleteRecord(Map<String, dynamic> params) async {
    final result = await useCase.deleteRecord(params);

    if (result.isFailure) {
      return jsonEncode({'success': false, 'error': result.errorOrNull?.message});
    }

    return jsonEncode({'success': true});
  }

  /// 查询记录
  /// 支持分页参数: offset, count
  Future<String> _jsQuery(Map<String, dynamic> params) async {
    final result = await useCase.searchRecords(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull);
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

  // ==================== 数据库查找方法 ====================

  /// 通用数据库查找
  /// 支持分页参数: offset, count (仅 findAll=true 时有效)
  Future<String> _jsFindDatabaseBy(Map<String, dynamic> params) async {
    try {
      final String? field = params['field'];
      if (field == null || field.isEmpty) {
        return jsonEncode({'error': '缺少必需参数: field'});
      }

      final dynamic value = params['value'];
      if (value == null) {
        return jsonEncode({'error': '缺少必需参数: value'});
      }

      final bool findAll = params['findAll'] ?? false;

      // 使用 UseCase 搜索数据库
      final searchParams = <String, dynamic>{};
      if (field == 'name') {
        searchParams['nameKeyword'] = value.toString();
      }

      final result = await useCase.searchDatabases(searchParams);

      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message});
      }

      var databases = result.dataOrNull as List;
      // 过滤匹配字段
      databases = databases.where((db) {
        final dbMap = db as Map<String, dynamic>;
        return dbMap.containsKey(field) && dbMap[field] == value;
      }).toList();

      if (findAll) {
        return jsonEncode(databases);
      } else {
        return databases.isEmpty
            ? jsonEncode(null)
            : jsonEncode(databases.first);
      }
    } catch (e) {
      return jsonEncode({'error': '查找数据库失败: $e'});
    }
  }

  /// 根据 ID 查找数据库
  Future<String> _jsFindDatabaseById(Map<String, dynamic> params) async {
    final result = await useCase.getDatabaseById(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull);
  }

  /// 根据名称查找数据库
  /// 支持分页参数: offset, count (仅 findAll=true 时有效)
  Future<String> _jsFindDatabaseByName(Map<String, dynamic> params) async {
    try {
      final String? name = params['name'];
      if (name == null || name.isEmpty) {
        return jsonEncode({'error': '缺少必需参数: name'});
      }

      final bool fuzzy = params['fuzzy'] ?? false;
      final bool findAll = params['findAll'] ?? false;

      // 使用 UseCase 搜索数据库
      final searchParams = <String, dynamic>{'nameKeyword': name};

      final result = await useCase.searchDatabases(searchParams);

      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message});
      }

      var databases = result.dataOrNull as List;
      // 如果不是模糊搜索，进一步过滤精确匹配
      if (!fuzzy) {
        databases = databases.where((db) {
          final dbMap = db as Map<String, dynamic>;
          return dbMap['name'] == name;
        }).toList();
      }

      if (findAll) {
        return jsonEncode(databases);
      } else {
        return databases.isEmpty
            ? jsonEncode(null)
            : jsonEncode(databases.first);
      }
    } catch (e) {
      return jsonEncode({'error': '查找数据库失败: $e'});
    }
  }

  // ==================== 记录查找方法 ====================

  /// 通用记录查找
  /// 支持分页参数: offset, count (仅 findAll=true 时有效)
  Future<String> _jsFindRecordBy(Map<String, dynamic> params) async {
    try {
      final String? databaseId = params['databaseId'];
      if (databaseId == null || databaseId.isEmpty) {
        return jsonEncode({'error': '缺少必需参数: databaseId'});
      }

      final String? field = params['field'];
      if (field == null || field.isEmpty) {
        return jsonEncode({'error': '缺少必需参数: field'});
      }

      final dynamic value = params['value'];
      if (value == null) {
        return jsonEncode({'error': '缺少必需参数: value'});
      }

      final bool findAll = params['findAll'] ?? false;

      // 使用 UseCase 搜索记录
      final searchParams = <String, dynamic>{
        'tableId': databaseId,
        'fieldKeyword': value.toString(),
      };

      final result = await useCase.searchRecords(searchParams);

      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message});
      }

      var records = result.dataOrNull as List;
      // 进一步过滤匹配字段
      records = records.where((record) {
        final recordMap = record as Map<String, dynamic>;
        // 检查内置字段
        if (recordMap.containsKey(field) && recordMap[field] == value) {
          return true;
        }
        // 检查自定义字段
        final fields = recordMap['fields'] as Map<String, dynamic>?;
        return fields?.containsKey(field) == true && fields![field] == value;
      }).toList();

      if (findAll) {
        return jsonEncode(records);
      } else {
        return records.isEmpty
            ? jsonEncode(null)
            : jsonEncode(records.first);
      }
    } catch (e) {
      return jsonEncode({'error': '查找记录失败: $e'});
    }
  }

  /// 根据 ID 查找记录
  Future<String> _jsFindRecordById(Map<String, dynamic> params) async {
    final result = await useCase.getRecordById(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull);
  }

  /// 注册数据选择器
  void _registerDataSelectors() {
    // 1. 数据库表选择器（单级）
    pluginDataSelectorService.registerSelector(SelectorDefinition(
      id: 'database.table',
      pluginId: id,
      name: '选择数据库表',
      description: '选择一个数据库表',
      icon: icon,
      color: color,
      steps: [
        SelectorStep(
          id: 'table',
          title: '数据库表列表',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          emptyText: '暂无数据库表，请先创建',
          dataLoader: (_) async {
            final databases = await service.getAllDatabases();
            return databases.map((database) => SelectableItem(
              id: database.id,
              title: database.name,
              subtitle: database.description,
              icon: Icons.storage,
              color: color,
              rawData: database,
            )).toList();
          },
          searchFilter: (items, query) {
            final lowerQuery = query.toLowerCase();
            return items.where((item) =>
              item.title.toLowerCase().contains(lowerQuery) ||
              (item.subtitle?.toLowerCase().contains(lowerQuery) ?? false)
            ).toList();
          },
        ),
      ],
    ));

    // 2. 记录选择器（两级：数据库 → 记录）
    pluginDataSelectorService.registerSelector(SelectorDefinition(
      id: 'database.record',
      pluginId: id,
      name: '选择记录',
      description: '选择一条数据库记录',
      icon: Icons.description,
      color: color,
      steps: [
        // 第一级：选择数据库
        SelectorStep(
          id: 'database',
          title: '选择数据库',
          viewType: SelectorViewType.list,
          isFinalStep: false,
          emptyText: '暂无数据库',
          dataLoader: (_) async {
            final databases = await service.getAllDatabases();
            return databases.map((database) => SelectableItem(
              id: database.id,
              title: database.name,
              subtitle: database.description,
              icon: Icons.storage,
              color: color,
              rawData: database,
            )).toList();
          },
          searchFilter: (items, query) {
            final lowerQuery = query.toLowerCase();
            return items.where((item) =>
              item.title.toLowerCase().contains(lowerQuery)
            ).toList();
          },
        ),
        // 第二级：选择记录
        SelectorStep(
          id: 'record',
          title: '选择记录',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          emptyText: '该数据库暂无记录',
          dataLoader: (previousSelections) async {
            final database = previousSelections['database'] as DatabaseModel;
            // 加载数据库记录
            final records = await controller.getRecords(database.id);
            if (records.isEmpty) return [];

            return records.map((record) {
              // 尝试获取记录的显示标题
              String displayTitle = '未命名';

              // 优先查找名为 'title' 或 'name' 的字段
              if (record.fields.containsKey('title') && record.fields['title'] != null) {
                displayTitle = record.fields['title'].toString();
              } else if (record.fields.containsKey('name') && record.fields['name'] != null) {
                displayTitle = record.fields['name'].toString();
              } else if (record.fields.isNotEmpty) {
                // 如果没有 title/name 字段，使用第一个非空字段
                final firstField = record.fields.entries.firstWhere(
                  (e) => e.value != null && e.value.toString().isNotEmpty,
                  orElse: () => MapEntry('', ''),
                );
                if (firstField.key.isNotEmpty) {
                  displayTitle = '${firstField.key}: ${firstField.value}';
                }
              }

              // 截断过长的标题
              if (displayTitle.length > 50) {
                displayTitle = '${displayTitle.substring(0, 50)}...';
              }

              // 生成副标题（显示记录ID或创建时间）
              String subtitle = 'ID: ${record.id.substring(0, 8)}...';

              return SelectableItem(
                id: record.id,
                title: displayTitle,
                subtitle: subtitle,
                icon: Icons.description,
                rawData: record,
              );
            }).toList();
          },
          searchFilter: (items, query) {
            final lowerQuery = query.toLowerCase();
            return items.where((item) =>
              item.title.toLowerCase().contains(lowerQuery) ||
              (item.subtitle?.toLowerCase().contains(lowerQuery) ?? false)
            ).toList();
          },
        ),
      ],
    ));
  }
}
