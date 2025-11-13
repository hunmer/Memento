import 'dart:convert';
import 'platform/js_engine_interface.dart';
import 'platform/js_engine_factory.dart';
import '../plugin_base.dart';

/// 全局 JS 桥接管理器
class JSBridgeManager {
  static JSBridgeManager? _instance;
  static JSBridgeManager get instance {
    _instance ??= JSBridgeManager._();
    return _instance!;
  }

  JSBridgeManager._();

  JSEngine? _engine;
  bool _initialized = false;
  final Map<String, PluginBase> _registeredPlugins = {};

  /// 初始化 JS 引擎
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _engine = JSEngineFactory.create();
      await _engine!.initialize();

      // 注册全局 API
      await _registerGlobalAPI();

      _initialized = true;
      print('JS Bridge 初始化成功');
    } catch (e) {
      print('JS Bridge 初始化失败: $e');
      _initialized = false;
    }
  }

  /// 检查是否支持
  bool get isSupported => _initialized && _engine != null;

  /// 注册插件的 JS API
  Future<void> registerPlugin(
      PluginBase plugin, Map<String, Function> apis) async {
    if (!_initialized || _engine == null) {
      throw StateError('JS Bridge not initialized');
    }

    _registeredPlugins[plugin.id] = plugin;

    // 为每个插件创建命名空间
    await _engine!.evaluate('''
      if (typeof window !== 'undefined') {
        window.Memento = window.Memento || {};
        window.Memento.${plugin.id} = {};
      } else {
        var Memento = Memento || {};
        Memento.${plugin.id} = {};
      }
    ''');

    // 注册 API
    for (var entry in apis.entries) {
      final apiName = entry.key;
      final dartFunction = entry.value;

      // 包装函数以处理异步和错误
      Future<String> wrappedFunction(
          [dynamic a, dynamic b, dynamic c, dynamic d, dynamic e]) async {
        try {
          final args = [a, b, c, d, e].where((arg) => arg != null).toList();

          // 调用 Dart 函数
          final result = Function.apply(dartFunction, args);

          // 处理 Future 返回值
          if (result is Future) {
            final awaitedResult = await result;
            return _serializeResult(awaitedResult);
          }

          return _serializeResult(result);
        } catch (e) {
          print('JS API Error [${plugin.id}.$apiName]: $e');
          return jsonEncode({'error': e.toString()});
        }
      }

      // 注册包装后的函数
      await _engine!
          .registerFunction('Memento_${plugin.id}_$apiName', wrappedFunction);

      // 在插件命名空间下创建代理（支持异步）
      await _engine!.evaluate('''
        (function() {
          var namespace = typeof window !== 'undefined' ? window.Memento : Memento;
          namespace.${plugin.id}.$apiName = function() {
            var args = Array.prototype.slice.call(arguments);
            var result = Memento_${plugin.id}_$apiName.apply(null, args);

            // 如果结果是字符串，尝试解析为 JSON
            if (typeof result === 'string') {
              try {
                var parsed = JSON.parse(result);
                if (parsed && parsed.error) {
                  throw new Error(parsed.error);
                }
                return parsed;
              } catch (e) {
                // 如果不是 JSON，返回原始字符串
                if (e.message && e.message.indexOf('Unexpected') === -1) {
                  throw e;
                }
                return result;
              }
            }

            return result;
          };
        })();
      ''');
    }

    print('插件 [${plugin.id}] 注册了 ${apis.length} 个 JS API');
  }

  /// 执行 JS 代码
  Future<JSResult> evaluate(String code) async {
    if (!_initialized || _engine == null) {
      return JSResult.error('JS Bridge not initialized');
    }
    return await _engine!.evaluate(code);
  }

  /// 注册全局 API
  Future<void> _registerGlobalAPI() async {
    if (_engine == null) return;

    // 注册全局命名空间
    await _engine!.evaluate('''
      (function() {
        if (typeof window !== 'undefined') {
          window.Memento = window.Memento || {
            version: '1.0.0',
            plugins: {}
          };
        } else {
          var Memento = Memento || {
            version: '1.0.0',
            plugins: {}
          };
        }
      })();
    ''');
  }

  /// 序列化结果
  String _serializeResult(dynamic result) {
    if (result == null) {
      return 'null';
    } else if (result is String) {
      // 如果已经是 JSON 字符串，直接返回
      try {
        jsonDecode(result);
        return result;
      } catch (e) {
        // 不是 JSON，包装成字符串
        return jsonEncode(result);
      }
    } else if (result is bool || result is num) {
      return result.toString();
    } else {
      // 对象或列表，序列化为 JSON
      try {
        return jsonEncode(result);
      } catch (e) {
        return jsonEncode({'error': 'Failed to serialize result: $e'});
      }
    }
  }

  /// 获取已注册的插件
  PluginBase? getPlugin(String id) => _registeredPlugins[id];

  /// 获取所有已注册的插件 ID
  List<String> get registeredPluginIds => _registeredPlugins.keys.toList();

  /// 释放资源
  Future<void> dispose() async {
    if (_initialized && _engine != null) {
      await _engine!.dispose();
      _registeredPlugins.clear();
      _initialized = false;
      _engine = null;
    }
  }
}
