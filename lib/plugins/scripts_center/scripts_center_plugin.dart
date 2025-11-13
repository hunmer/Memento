import 'package:flutter/material.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../../core/event/event_manager.dart';
import 'services/script_loader.dart';
import 'services/script_manager.dart';
import 'services/script_executor.dart';
import 'screens/scripts_list_screen.dart';

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
        timeoutMilliseconds: 10000, // 10秒超时
      );

      // 初始化JS引擎
      await _scriptExecutor.initialize();

      // 加载所有脚本
      await _scriptManager.loadScripts();

      print('✅ ScriptsCenterPlugin初始化成功');
      print('   - 已加载 ${_scriptManager.scriptCount} 个脚本');
      print('   - 已启用 ${_scriptManager.enabledScriptCount} 个脚本');
    } catch (e) {
      print('❌ ScriptsCenterPlugin初始化失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    await initialize();

    // 延迟设置触发器，确保其他插件已初始化
    Future.delayed(const Duration(milliseconds: 500), () {
      _setupTriggers();
    });

    print('✅ ScriptsCenterPlugin已注册到应用');
  }

  /// 设置事件触发器
  void _setupTriggers() {
    try {
      final enabledScripts = _scriptManager.getEnabledScripts();
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
                final result = await _scriptExecutor.execute(
                  script.id,
                  args: {'event': trigger.event, 'eventArgs': args.eventName},
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
    return ScriptsListScreen(
      scriptManager: _scriptManager,
      scriptExecutor: _scriptExecutor,
    );
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
                      '脚本中心',
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

  @override
  void dispose() {
    _clearTriggers();
    _scriptExecutor.dispose();
    _scriptManager.dispose();
    // super.dispose();
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

  @override
  void initState() {
    super.initState();
    _plugin =
        PluginManager.instance.getPlugin('scripts_center')
            as ScriptsCenterPlugin;
  }

  @override
  Widget build(BuildContext context) {
    return ScriptsListScreen(
      scriptManager: _plugin.scriptManager,
      scriptExecutor: _plugin.scriptExecutor,
    );
  }
}
