import 'dart:convert';
import 'package:flutter/material.dart';
import 'platform/js_engine_interface.dart';
import 'platform/js_engine_factory.dart';
import 'platform/mobile_js_engine.dart';
import 'js_ui_handlers.dart';
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

  /// 注册 UI 处理器（Toast/Alert/Dialog）
  ///
  /// 必须在有 BuildContext 的情况下调用，通常在 UI 组件初始化时调用
  void registerUIHandlers(BuildContext context) {
    if (!_initialized || _engine == null) {
      print('警告: JS Bridge 未初始化，无法注册 UI 处理器');
      return;
    }

    // 只有 MobileJSEngine 需要注册 UI 处理器
    if (_engine is MobileJSEngine) {
      final handlers = JSUIHandlers(context);
      handlers.register(_engine as MobileJSEngine);
      print('✓ UI 处理器已注册 (Toast/Alert/Dialog)');
    } else {
      print('跳过 UI 处理器注册 (Web 平台)');
    }
  }

  /// 注册插件分析处理器（由 OpenAI 插件调用）
  ///
  /// 用于在 JS 中调用 callPluginAnalysis() 时执行插件的数据分析方法
  void registerPluginAnalysisHandler(
    Future<String> Function(String methodName, Map<String, dynamic> params) handler,
  ) {
    if (!_initialized || _engine == null) {
      print('警告: JS Bridge 未初始化，无法注册插件分析处理器');
      return;
    }

    // 只有 MobileJSEngine 支持插件分析
    if (_engine is MobileJSEngine) {
      (_engine as MobileJSEngine).setPluginAnalysisHandler(handler);
      print('✓ 插件分析处理器已注册');
    } else {
      print('跳过插件分析处理器注册 (Web 平台)');
    }
  }

  /// 注册插件的 JS API
  Future<void> registerPlugin(
      PluginBase plugin, Map<String, Function> apis) async {
    if (!_initialized || _engine == null) {
      throw StateError('JS Bridge not initialized');
    }

    _registeredPlugins[plugin.id] = plugin;

    // 为每个插件创建命名空间
    // 使用 globalThis 确保跨平台兼容性（Web/QuickJS）
    await _engine!.evaluateDirect('''
      (function() {
        // 确保全局命名空间存在
        if (typeof globalThis.Memento === 'undefined') {
          globalThis.Memento = {
            version: '1.0.0',
            plugins: {}
          };
        }

        // 创建插件命名空间
        globalThis.Memento.${plugin.id} = {};

        // 兼容浏览器环境
        if (typeof window !== 'undefined') {
          window.Memento = globalThis.Memento;
        }
      })();
    ''');

    // 注册 API
    for (var entry in apis.entries) {
      final apiName = entry.key;
      final dartFunction = entry.value;

      // 包装函数：直接返回原始结果或 Future
      // 不使用 async，让 mobile_js_engine 统一处理异步
      dynamic wrappedFunction(
          [dynamic a, dynamic b, dynamic c, dynamic d, dynamic e]) {
        try {
          final args = [a, b, c, d, e].where((arg) => arg != null).toList();

          // 直接调用 Dart 函数并返回（可能是同步值或 Future）
          final result = Function.apply(dartFunction, args);

          // 如果是 Future，包装为返回序列化结果的 Future
          if (result is Future) {
            return result.then((awaitedResult) {
              return _serializeResult(awaitedResult);
            }).catchError((e) {
              print('JS API Error [${plugin.id}.$apiName]: $e');
              return jsonEncode({'error': e.toString()});
            });
          }

          // 同步结果直接序列化
          return _serializeResult(result);
        } catch (e) {
          print('JS API Error [${plugin.id}.$apiName]: $e');
          return jsonEncode({'error': e.toString()});
        }
      }

      // 注册包装后的函数
      await _engine!
          .registerFunction('Memento_${plugin.id}_$apiName', wrappedFunction);

      // 在插件命名空间下创建代理
      // 直接返回内层 Promise，不使用 await（避免事件循环阻塞）
      await _engine!.evaluateDirect('''
        (function() {
          var namespace = globalThis.Memento;

          // 直接返回 Promise，让调用者处理
          namespace.${plugin.id}.$apiName = function() {
            var args = Array.prototype.slice.call(arguments);
            // 直接返回 Promise（不 await）
            return Memento_${plugin.id}_$apiName.apply(null, args);
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

    // 注册全局命名空间（使用 globalThis 确保跨平台）
    await _engine!.evaluateDirect('''
      (function() {
        // 确保全局命名空间存在
        if (typeof globalThis.Memento === 'undefined') {
          globalThis.Memento = {
            version: '1.0.0',
            plugins: {}
          };
        }

        // 兼容浏览器环境
        if (typeof window !== 'undefined') {
          window.Memento = globalThis.Memento;
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
