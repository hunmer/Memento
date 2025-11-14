import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/event/event_manager.dart';
import '../../../core/storage/storage_manager.dart';
import '../../../core/js_bridge/js_bridge_manager.dart';
import '../../../core/plugin_base.dart';
import '../models/script_execution_result.dart';
import 'script_manager.dart';

/// 脚本执行器服务
///
/// 使用 JSBridgeManager 提供的统一 JS 执行环境
/// 脚本可以直接调用 Memento 的插件 API（如 Memento.chat.sendMessage() 等）
class ScriptExecutor {
  final ScriptManager scriptManager;
  final StorageManager storage;
  final EventManager eventManager;

  /// JS Bridge Manager 实例
  final JSBridgeManager _jsBridge = JSBridgeManager.instance;

  /// 是否已初始化
  bool _isInitialized = false;

  /// 正在执行的脚本栈（用于检测循环调用）
  final Set<String> _executingScripts = {};

  /// 执行超时时间（毫秒）
  final int timeoutMilliseconds;

  /// 日志回调函数
  final Function(String message, String level)? onLog;

  ScriptExecutor({
    required this.scriptManager,
    required this.storage,
    required this.eventManager,
    this.timeoutMilliseconds = 5000,
    this.onLog,
  });

  /// 初始化JS引擎
  Future<void> initialize() async {
    if (_isInitialized) {
      print('⚠️ ScriptExecutor已经初始化过了');
      return;
    }

    try {
      // 确保 JSBridgeManager 已初始化
      if (!_jsBridge.isSupported) {
        throw Exception('JSBridgeManager 未初始化或不支持');
      }

      // 注入脚本中心特有的全局API（runScript 等）
      await _injectScriptCenterAPI();

      _isInitialized = true;
      print('✅ ScriptExecutor初始化成功（使用 JSBridgeManager）');
    } catch (e) {
      print('❌ ScriptExecutor初始化失败: $e');
      rethrow;
    }
  }

  /// 注入脚本中心特有的 API 到 JS 环境
  ///
  /// 注意：Memento 的插件 API（如 Memento.chat.* 等）已由 JSBridgeManager 自动注册
  /// 这里只需要注入脚本中心特有的功能
  Future<void> _injectScriptCenterAPI() async {
    // 创建一个临时的"插件"来注册 runScript API
    // 这样可以利用 JSBridgeManager 的标准 API 注册机制
    final _ScriptExecutorPlugin tempPlugin = _ScriptExecutorPlugin(this);

    final apis = {
      'runScript': _handleRunScript,
    };

    // 使用 JSBridgeManager 的标准 API 注册机制
    await _jsBridge.registerPlugin(tempPlugin, apis);

    // 在全局作用域也提供 runScript（便于脚本使用）
    await _jsBridge.evaluate('''
      (function() {
        // 将 Memento.script_executor.runScript 映射到全局 runScript
        if (typeof globalThis.Memento !== 'undefined' &&
            typeof globalThis.Memento.script_executor !== 'undefined') {
          globalThis.runScript = globalThis.Memento.script_executor.runScript;

          // 兼容浏览器环境
          if (typeof window !== 'undefined') {
            window.runScript = globalThis.runScript;
          }
        }
      })();
    ''');

    print('✅ 脚本中心 API 注入成功');
  }

  /// 处理脚本互调
  ///
  /// 此方法由 JS 环境中的 runScript() 函数调用
  /// 支持真正的异步执行和脚本间调用
  Future<dynamic> _handleRunScript(String scriptId, [dynamic params]) async {
    // 检测循环调用
    if (_executingScripts.contains(scriptId)) {
      print('❌ 检测到循环调用: $scriptId');
      return jsonEncode({
        'success': false,
        'error': '检测到循环调用: $scriptId',
      });
    }

    try {
      print('📞 脚本互调: $scriptId');

      // 准备参数
      final Map<String, dynamic> args = {
        'params': params ?? [],
        'calledFrom': 'runScript',
      };

      // 执行目标脚本
      final result = await execute(scriptId, args: args);

      // 返回结果
      if (result.success) {
        print('✅ 脚本互调成功: $scriptId');
        return result.result;
      } else {
        print('⚠️ 脚本互调失败: $scriptId - ${result.error}');
        return jsonEncode({
          'success': false,
          'error': result.error,
        });
      }
    } catch (e) {
      print('❌ 脚本互调异常: $scriptId - $e');
      return jsonEncode({
        'success': false,
        'error': e.toString(),
      });
    }
  }

  /// 执行脚本
  Future<ScriptExecutionResult> execute(
    String scriptId, {
    Map<String, dynamic>? args,
  }) async {
    if (!_isInitialized) {
      return ScriptExecutionResult.failure(
        error: 'ScriptExecutor未初始化',
        duration: Duration.zero,
        scriptId: scriptId,
      );
    }

    final startTime = DateTime.now();

    try {
      // 检查脚本是否存在
      final script = scriptManager.getScriptById(scriptId);
      if (script == null) {
        throw Exception('脚本不存在: $scriptId');
      }

      // 检查脚本是否启用
      if (!script.enabled) {
        throw Exception('脚本未启用: $scriptId');
      }

      // 获取脚本代码
      final code = await scriptManager.getScriptCode(scriptId);
      if (code == null || code.isEmpty) {
        throw Exception('脚本代码为空: $scriptId');
      }

      // 检测循环调用
      if (_executingScripts.contains(scriptId)) {
        throw Exception('检测到循环调用: $scriptId');
      }

      // 标记为正在执行
      _executingScripts.add(scriptId);

      try {
        // 准备参数
        final argsJson = jsonEncode(args ?? {});

        // 包装代码（注入 args 参数和脚本信息）
        final wrappedCode = '''
        (async function() {
          const args = $argsJson;
          const scriptInfo = {
            id: '${script.id}',
            name: '${script.name}',
            version: '${script.version}'
          };

          try {
            // 执行脚本代码
            const result = await (async function() {
              $code
            })();

            return result;
          } catch (error) {
            console.error('[Script Error]', error);
            return {
              success: false,
              error: error.toString(),
              stack: error.stack
            };
          }
        })();
        ''';

        // 使用 JSBridgeManager 执行脚本（带超时控制）
        dynamic result;
        try {
          result = await _executeWithTimeout(wrappedCode);
        } on TimeoutException {
          throw Exception('脚本执行超时（${timeoutMilliseconds}ms）');
        }

        final duration = DateTime.now().difference(startTime);

        // 记录执行日志
        onLog?.call(
          '脚本 ${script.name} 执行成功，耗时 ${duration.inMilliseconds}ms',
          'info',
        );

        return ScriptExecutionResult.success(
          result: result,
          duration: duration,
          scriptId: scriptId,
        );
      } finally {
        // 移除执行标记
        _executingScripts.remove(scriptId);
      }
    } catch (e) {
      final duration = DateTime.now().difference(startTime);

      // 记录错误日志
      onLog?.call(
        '脚本执行失败: $e',
        'error',
      );

      return ScriptExecutionResult.failure(
        error: e.toString(),
        duration: duration,
        scriptId: scriptId,
      );
    }
  }

  /// 带超时的执行
  Future<dynamic> _executeWithTimeout(String code) async {
    return Future.any([
      Future.delayed(
        Duration(milliseconds: timeoutMilliseconds),
        () => throw TimeoutException('执行超时'),
      ),
      Future(() async {
        try {
          // 使用 JSBridgeManager 执行代码
          final jsResult = await _jsBridge.evaluate(code);

          // 处理返回值
          if (!jsResult.success) {
            throw Exception(jsResult.error ?? '未知错误');
          }

          return jsResult.result;
        } catch (e) {
          throw Exception('JS执行错误: $e');
        }
      }),
    ]);
  }

  /// 评估表达式（用于调试）
  Future<String?> evaluateExpression(String expression) async {
    if (!_isInitialized) return null;

    try {
      final result = await _jsBridge.evaluate(expression);
      if (result.success) {
        return result.result?.toString();
      } else {
        return 'Error: ${result.error}';
      }
    } catch (e) {
      print('❌ 表达式评估失败: $e');
      return 'Exception: $e';
    }
  }

  /// 清理资源
  void dispose() {
    _executingScripts.clear();
    _isInitialized = false;
    print('✅ ScriptExecutor已清理');
  }
}

/// 临时插件类，用于向 JSBridgeManager 注册 ScriptExecutor 的 API
///
/// 这是一个轻量级的适配器，使 ScriptExecutor 能够利用 JSBridgeManager 的
/// 标准 API 注册机制来暴露 runScript 等函数
class _ScriptExecutorPlugin extends PluginBase {
  final ScriptExecutor executor;

  _ScriptExecutorPlugin(this.executor);

  @override
  String get id => 'script_executor';

  @override
  IconData? get icon => null;

  @override
  Color? get color => null;

  @override
  Future<void> initialize() async {
    // 无需初始化，ScriptExecutor 已经初始化
  }

  @override
  Widget buildMainView(BuildContext context) {
    // 这个插件不需要 UI
    return Container();
  }
}
