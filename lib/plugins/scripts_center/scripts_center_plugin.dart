import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:Memento/plugins/base_plugin.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/event/event_args.dart' as event_args;
import 'package:Memento/core/event/item_event_args.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/core/services/plugin_data_selector/plugin_data_selector_service.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_definition.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_step.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selectable_item.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/utils/file_picker_helper.dart';
import 'services/script_loader.dart';
import 'services/script_manager.dart';
import 'services/script_executor.dart';
import 'models/script_folder.dart';
import 'models/script_input.dart';
import 'screens/scripts_list_screen.dart';
import 'screens/script_edit_screen.dart';
import 'package:get/get.dart';

/// 深度序列化对象为 JSON 兼容的 Map/List/基本类型（异步版本）
Future<dynamic> _deepSerializeAsync(dynamic value) async {
  // null 值
  if (value == null) {
    return null;
  }

  // 基本类型：String, num, bool
  if (value is String || value is num || value is bool) {
    return value;
  }

  // DateTime 转为 ISO 8601 字符串
  if (value is DateTime) {
    return value.toIso8601String();
  }

  // List 类型：递归序列化每个元素
  if (value is List) {
    final results = <dynamic>[];
    for (final item in value) {
      results.add(await _deepSerializeAsync(item));
    }
    return results;
  }

  // Map 类型：递归序列化每个值
  if (value is Map) {
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      result[entry.key.toString()] = await _deepSerializeAsync(entry.value);
    }
    return result;
  }

  // 尝试调用 toJson 方法（如果存在）
  try {
    final dynamic obj = value;
    final jsonResult = obj.toJson();

    // 如果 toJson 返回 Future，等待它
    if (jsonResult is Future) {
      final awaited = await jsonResult;
      return await _deepSerializeAsync(awaited);
    }

    // 递归序列化 toJson 的结果
    return await _deepSerializeAsync(jsonResult);
  } catch (e) {
    // 对象没有 toJson 方法或调用失败，继续尝试其他方法
  }

  // 尝试转换为字符串（最后的兜底方案）
  try {
    return value.toString();
  } catch (e) {
    return '<无法序列化: ${value.runtimeType}>';
  }
}

/// 将 EventArgs 对象序列化为 Map，以便传递给 JavaScript（异步版本）
Future<Map<String, dynamic>> _serializeEventArgsAsync(EventArgs args) async {
  final Map<String, dynamic> result = {
    'eventName': args.eventName,
    'whenOccurred': args.whenOccurred.toIso8601String(),
  };

  // 处理不同类型的 EventArgs 子类
  if (args is ItemEventArgs) {
    result['itemId'] = args.itemId;
    result['title'] = args.title;
    result['action'] = args.action;
  } else if (args is event_args.Value) {
    result['value'] = await _deepSerializeAsync(args.value);
  } else if (args is event_args.Values) {
    result['value1'] = await _deepSerializeAsync(args.value1);
    result['value2'] = await _deepSerializeAsync(args.value2);
  } else if (args is event_args.UpdateEvent) {
    result['version'] = args.version;
    result['forceUpdate'] = args.forceUpdate;
    if (args.changelog != null) {
      result['changelog'] = args.changelog;
    }
  }

  // 深度序列化整个 result，确保所有嵌套对象都被转换
  return await _deepSerializeAsync(result) as Map<String, dynamic>;
}

/// 脚本中心插件
///
/// 提供JS脚本管理、执行和事件触发功能
class ScriptsCenterPlugin extends BasePlugin {
  // 单例模式
  static ScriptsCenterPlugin? _instance;

  static ScriptsCenterPlugin get instance {
    if (_instance == null) {
      _instance =
          PluginManager.instance.getPlugin('scripts_center')
              as ScriptsCenterPlugin?;
      if (_instance == null) {
        throw StateError('ScriptsCenterPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  // 服务实例
  late ScriptLoader _scriptLoader;
  late ScriptManager _scriptManager;
  late ScriptExecutor _scriptExecutor;

  // 事件订阅ID列表
  final List<String> _subscriptionIds = [];

  @override
  String get id => 'scripts_center';

  @override
  Color get color => Colors.deepPurple;

  @override
  IconData get icon => Icons.code;

  @override
  String? getPluginName(context) {
    return 'scripts_center_scriptCenter'.tr;
  }

  // 获取服务实例的访问器
  ScriptManager get scriptManager => _scriptManager;
  ScriptExecutor get scriptExecutor => _scriptExecutor;

  @override
  Future<void> initialize() async {
    print('📦 初始化 ScriptsCenterPlugin...');

    try {
      // 初始化服务层
      _scriptLoader = ScriptLoader(storage);
      _scriptManager = ScriptManager(_scriptLoader);
      _scriptExecutor = ScriptExecutor(
        scriptManager: _scriptManager,
        storage: storage,
        eventManager: EventManager.instance,
      );

      // 初始化JS引擎
      await _scriptExecutor.initialize();

      // 初始化默认文件夹
      await _initializeDefaultFolders();

      // 加载当前文件夹的脚本
      await _scriptManager.loadScripts();

      print('✅ ScriptsCenterPlugin初始化成功');
      print('   - 已加载 ${_scriptManager.scriptCount} 个脚本');
      print('   - 已启用 ${_scriptManager.enabledScriptCount} 个脚本');

      // 注册数据选择器
      _registerDataSelectors();
    } catch (e) {
      print('❌ ScriptsCenterPlugin初始化失败: $e');
      rethrow;
    }
  }

  /// 注册数据选择器
  void _registerDataSelectors() {
    final pluginDataSelectorService = PluginDataSelectorService.instance;

    // 注册脚本选择器
    pluginDataSelectorService.registerSelector(
      SelectorDefinition(
        id: 'scripts_center.script',
        pluginId: id,
        name: 'scripts_center_selectScript'.tr,
        icon: icon,
        color: color,
        searchable: true,
        selectionMode: SelectionMode.single,
        steps: [
          SelectorStep(
            id: 'select_script',
            title: 'scripts_center_selectScript'.tr,
            viewType: SelectorViewType.list,
            isFinalStep: true,
            dataLoader: (_) async {
              // 获取所有启用的脚本
              final scripts = await _scriptManager.loadAllScripts();
              final enabledScripts = scripts.where((s) => s.enabled).toList();

              return enabledScripts.map((script) {
                // 解析图标
                IconData scriptIcon;
                try {
                  scriptIcon = IconData(
                    int.parse(script.icon, radix: 16),
                    fontFamily: 'MaterialIcons',
                  );
                } catch (e) {
                  scriptIcon = Icons.code;
                }

                return SelectableItem(
                  id: script.id,
                  title: script.name,
                  subtitle: script.description.isNotEmpty
                      ? script.description
                      : 'v${script.version}',
                  icon: scriptIcon,
                  rawData: {
                    'id': script.id,
                    'name': script.name,
                    'description': script.description,
                    'icon': script.icon,
                    'version': script.version,
                    'type': script.type,
                    'hasInputs': script.hasInputs,
                  },
                );
              }).toList();
            },
          ),
        ],
      ),
    );

    print('✅ 脚本选择器注册成功');
  }

  /// 初始化默认文件夹
  Future<void> _initializeDefaultFolders() async {
    try {
      final folders = <ScriptFolder>[];

      // 1. 默认脚本文件夹（应用文档目录下的 scripts）
      final defaultScriptsPath = await _scriptLoader.getScriptsDirectory();
      folders.add(
        ScriptFolder(
          id: 'default',
          name: '我的脚本',
          path: defaultScriptsPath,
          isBuiltIn: true,
          enabled: true,
          icon: 'folder',
          description: '默认脚本存储位置',
        ),
      );

      // 初始化文件夹
      await _scriptManager.initializeFolders(folders);

      print('✅ 初始化了 ${folders.length} 个默认文件夹');
    } catch (e) {
      print('❌ 初始化默认文件夹失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 插件已在 initialize() 中完成初始化
    // 这里可以添加额外的应用级注册逻辑

    // 延迟设置触发器和执行自动运行脚本，确保其他插件已初始化
    Future.delayed(const Duration(milliseconds: 500), () {
      _setupTriggers();
      _runAutoRunScripts();
    });

    print('✅ ScriptsCenterPlugin已注册到应用');
  }

  /// 执行自动运行脚本
  void _runAutoRunScripts() async {
    try {
      // 加载所有文件夹的脚本
      final allScripts = await _scriptManager.loadAllScripts();

      // 筛选已启用且开启了自动运行的脚本
      final autoRunScripts = allScripts
          .where((script) => script.enabled && script.autoRun)
          .toList();

      if (autoRunScripts.isEmpty) {
        print('ℹ️ 没有自动运行脚本');
        return;
      }

      print('🚀 执行自动运行脚本...');

      for (var script in autoRunScripts) {
        try {
          print('   ⚡ 执行: ${script.name}');
          final result = await _scriptExecutor.execute(script.id);

          if (!result.success) {
            print('   ⚠️ 脚本执行失败: ${script.name}');
            print('      错误: ${result.error}');
          } else {
            print('   ✅ 脚本执行成功: ${script.name}');
            print('      耗时: ${result.duration.inMilliseconds}ms');
          }
        } catch (e) {
          print('   ❌ 脚本执行异常: ${script.name}, 错误: $e');
        }
      }

      print('✅ 自动运行脚本执行完成');
    } catch (e) {
      print('❌ 执行自动运行脚本失败: $e');
    }
  }

  /// 设置事件触发器
  void _setupTriggers() async {
    try {
      // 加载所有文件夹的脚本
      final allScripts = await _scriptManager.loadAllScripts();
      final enabledScripts = allScripts.where((s) => s.enabled).toList();
      final scriptsWithTriggers =
          enabledScripts.where((script) => script.hasTriggers).toList();

      if (scriptsWithTriggers.isEmpty) {
        print('ℹ️ 没有配置触发器的脚本');
        return;
      }

      print('🔧 设置脚本触发器...');

      for (var script in scriptsWithTriggers) {
        for (var trigger in script.triggers) {
          // 订阅事件
          final subscriptionId = EventManager.instance.subscribe(
            trigger.event,
            (args) async {
              print('🎯 触发事件: ${trigger.event} -> 执行脚本: ${script.name}');

              // 延迟执行
              if (trigger.delay != null && trigger.delay! > 0) {
                await Future.delayed(Duration(milliseconds: trigger.delay!));
              }

              // 执行脚本
              try {
                // 序列化事件数据（异步）
                final eventData = await _serializeEventArgsAsync(args);

                final result = await _scriptExecutor.execute(
                  script.id,
                  args: {'event': trigger.event, 'eventData': eventData},
                );

                if (!result.success) {
                  print('⚠️ 脚本执行失败: ${script.name}');
                  print('   错误: ${result.error}');
                } else {
                  print('✅ 脚本执行成功: ${script.name}');
                  print('   耗时: ${result.duration.inMilliseconds}ms');
                }
              } catch (e) {
                print('❌ 脚本执行异常: ${script.name}, 错误: $e');
              }
            },
          );

          _subscriptionIds.add(subscriptionId);
          print(
            '   ✓ ${script.name}: ${trigger.event} (延迟${trigger.delay ?? 0}ms)',
          );
        }
      }

      print('✅ 触发器设置完成，共 ${_subscriptionIds.length} 个');
    } catch (e) {
      print('❌ 设置触发器失败: $e');
    }
  }

  /// 重新加载脚本并重新设置触发器
  Future<void> reloadScripts() async {
    try {
      // 取消所有现有订阅
      _clearTriggers();

      // 重新加载脚本
      await _scriptManager.loadScripts();

      // 重新设置触发器
      _setupTriggers();

      print('✅ 脚本重新加载成功');
    } catch (e) {
      print('❌ 脚本重新加载失败: $e');
      rethrow;
    }
  }

  /// 清除所有触发器订阅
  void _clearTriggers() {
    for (var subscriptionId in _subscriptionIds) {
      EventManager.instance.unsubscribeById(subscriptionId);
    }
    _subscriptionIds.clear();
    print('🗑️ 已清除所有触发器订阅');
  }

  @override
  Widget buildMainView(BuildContext context) {
    return const ScriptsCenterMainView();
  }

  @override
  Widget? buildCardView(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          PluginManager.instance.openPlugin(context, this);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'scripts_center_scriptCenter'.tr,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    context,
                    '总数',
                    _scriptManager.scriptCount.toString(),
                  ),
                  _buildStatItem(
                    context,
                    '已启用',
                    _scriptManager.enabledScriptCount.toString(),
                  ),
                  _buildStatItem(
                    context,
                    '触发器',
                    _subscriptionIds.length.toString(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  void dispose() {
    _clearTriggers();
    _scriptExecutor.dispose();
    _scriptManager.dispose();
  }
}

/// 脚本中心主视图
class ScriptsCenterMainView extends StatefulWidget {
  const ScriptsCenterMainView({super.key});

  @override
  State<ScriptsCenterMainView> createState() => _ScriptsCenterMainViewState();
}

class _ScriptsCenterMainViewState extends State<ScriptsCenterMainView> {
  late ScriptsCenterPlugin _plugin;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _plugin =
        PluginManager.instance.getPlugin('scripts_center')
            as ScriptsCenterPlugin;
  }

  void _setSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SuperCupertinoNavigationWrapper(
      title: Text('scripts_center_scriptCenter'.tr),
      largeTitle: 'scripts_center_scriptCenter'.tr,
      enableLargeTitle: true,
      enableSearchBar: true,
      searchPlaceholder: 'scripts_center_search'.tr,
      onSearchChanged: _setSearchQuery,
      onSearchSubmitted: _setSearchQuery,

      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.add_circle_outline, size: 24),
          tooltip: 'scripts_center_newScript'.tr,
          onSelected: (value) async {
            if (value == 'new') {
              _showCreateScriptDialog(context);
            } else if (value == 'import') {
              await _showImportScriptDialog(context);
            }
          },
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: 'new',
                  child: Row(
                    children: [
                      const Icon(Icons.add, size: 20),
                      const SizedBox(width: 12),
                      Text('scripts_center_newScript'.tr),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'import',
                  child: Row(
                    children: [
                      const Icon(Icons.file_upload, size: 20),
                      const SizedBox(width: 12),
                      Text('导入JS文件'),
                    ],
                  ),
                ),
              ],
        ),
      ],
      body: ScriptsListScreen(
        scriptManager: _plugin.scriptManager,
        scriptExecutor: _plugin.scriptExecutor,
        searchQuery: _searchQuery,
      ),
    );
  }

  Future<void> _showCreateScriptDialog(BuildContext context) async {
    final result = await NavigationHelper.push<Map<String, dynamic>>(
      context,
      ScriptEditScreen(script: null, scriptManager: _plugin.scriptManager),
    );

    if (result == null) return;

    try {
      // 使用统一的保存方法
      await _plugin.scriptManager.saveScriptFromEditResult(result);

      // 重新设置触发器
      await _plugin.reloadScripts();
      Toast.success('脚本创建成功！');
    } catch (e) {
      Toast.error('操作失败: $e');
    }
  }

  /// 显示导入脚本对话框
  Future<void> _showImportScriptDialog(BuildContext context) async {
    // 选择JS文件
    final files = await FilePickerHelper.pickFiles(multiple: false);
    if (files.isEmpty) return;

    final file = files.first;

    try {
      // 读取JS文件内容
      final jsContent = await file.readAsString();

      // 检查同目录下是否有metadata.json
      Map<String, dynamic>? metadata;
      String? localScriptPath = file.path;

      final metadataFile = File('${file.parent.path}/metadata.json');
      if (await metadataFile.exists()) {
        try {
          final metadataContent = await metadataFile.readAsString();
          metadata = jsonDecode(metadataContent) as Map<String, dynamic>;
        } catch (e) {
          print('读取metadata.json失败: $e');
        }
      }

      // 解析metadata中的数据
      Map<String, dynamic>? initialData;
      if (metadata != null) {
        initialData = {
          'id': metadata['id'], // 添加id字段
          'name': metadata['name'],
          'description': metadata['description'],
          'author': metadata['author'],
          'version': metadata['version'],
          'icon': metadata['icon'],
          'code': jsContent,
          'configFormFields': metadata['configFormFields'],
          'localScriptPath': localScriptPath,
          // 解析inputs
          if (metadata['inputs'] != null)
            'inputs':
                (metadata['inputs'] as List<dynamic>)
                    .map((e) => ScriptInput.fromJson(e as Map<String, dynamic>))
                    .toList(),
          // 解析triggers
          if (metadata['triggers'] != null) 'triggers': metadata['triggers'],
          // 解析config
          if (metadata['config'] != null) 'config': metadata['config'],
        };
      } else {
        initialData = {'code': jsContent, 'localScriptPath': localScriptPath};
      }

      // 跳转到编辑页面，传入初始数据
      final result = await NavigationHelper.push<Map<String, dynamic>>(
        context,
        ScriptEditScreen(
          script: null,
          scriptManager: _plugin.scriptManager,
          initialData: initialData,
        ),
      );

      if (result == null) return;

      // 使用统一的保存方法
      await _plugin.scriptManager.saveScriptFromEditResult(result);

      // 重新设置触发器
      await _plugin.reloadScripts();
      Toast.success('脚本导入成功！');
    } catch (e) {
      Toast.error('导入失败: $e');
    }
  }
}
