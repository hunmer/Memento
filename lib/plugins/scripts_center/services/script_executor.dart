import 'dart:async';
import 'dart:convert';
import 'package:flutter_js/flutter_js.dart';
import '../../../core/event/event_manager.dart';
import '../../../core/storage/storage_manager.dart';
import '../models/script_execution_result.dart';
import 'script_manager.dart';

/// 脚本执行器服务
///
/// 封装flutter_js引擎，提供安全的JavaScript执行环境
class ScriptExecutor {
  final ScriptManager scriptManager;
  final StorageManager storage;
  final EventManager eventManager;

  /// JavaScriptRuntime实例
  late JavascriptRuntime _jsRuntime;

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
      // 创建JS运行时
      _jsRuntime = getJavascriptRuntime();

      // 注入全局API
      _injectGlobalAPI();

      _isInitialized = true;
      print('✅ ScriptExecutor初始化成功');
    } catch (e) {
      print('❌ ScriptExecutor初始化失败: $e');
      rethrow;
    }
  }

  /// 注入全局API到JS环境
  void _injectGlobalAPI() {
    // 注入全局对象
    final globalAPIs = '''
    // 全局日志函数
    function log(message, level) {
      level = level || 'info';
      sendMessage('log', JSON.stringify({ message: message, level: level }));
    }

    // 全局存储对象
    const storage = {
      get: async function(key) {
        const result = sendMessage('storage.get', key);
        return JSON.parse(result || 'null');
      },
      set: async function(key, value) {
        sendMessage('storage.set', JSON.stringify({ key: key, value: value }));
      },
      remove: async function(key) {
        sendMessage('storage.remove', key);
      }
    };

    // 全局事件触发函数
    function emit(eventName, data) {
      sendMessage('emit', JSON.stringify({ event: eventName, data: data }));
    }

    // 全局脚本调用函数
    async function runScript(scriptId, ...params) {
      const argsJson = JSON.stringify({ scriptId: scriptId, params: params });
      const result = sendMessage('runScript', argsJson);
      return JSON.parse(result || 'null');
    }

    // 工具函数
    const utils = {
      sleep: function(ms) {
        const start = Date.now();
        while (Date.now() - start < ms) {}
      },
      formatDate: function(date, format) {
        // 简单的日期格式化
        const d = new Date(date);
        format = format || 'YYYY-MM-DD';
        return format
          .replace('YYYY', d.getFullYear())
          .replace('MM', String(d.getMonth() + 1).padStart(2, '0'))
          .replace('DD', String(d.getDate()).padStart(2, '0'))
          .replace('HH', String(d.getHours()).padStart(2, '0'))
          .replace('mm', String(d.getMinutes()).padStart(2, '0'))
          .replace('ss', String(d.getSeconds()).padStart(2, '0'));
      }
    };
    ''';

    try {
      _jsRuntime.evaluate(globalAPIs);
      print('✅ 全局API注入成功');
    } catch (e) {
      print('❌ 全局API注入失败: $e');
    }
  }

  /// 处理JS发送的消息
  String? _handleMessage(String channel, String message) {
    try {
      switch (channel) {
        case 'log':
          final data = jsonDecode(message) as Map<String, dynamic>;
          _handleLog(data['message'] as String, data['level'] as String);
          return null;

        case 'storage.get':
          return _handleStorageGet(message);

        case 'storage.set':
          final data = jsonDecode(message) as Map<String, dynamic>;
          _handleStorageSet(
            data['key'] as String,
            data['value'],
          );
          return null;

        case 'storage.remove':
          _handleStorageRemove(message);
          return null;

        case 'emit':
          final data = jsonDecode(message) as Map<String, dynamic>;
          _handleEmit(
            data['event'] as String,
            data['data'],
          );
          return null;

        case 'runScript':
          final data = jsonDecode(message) as Map<String, dynamic>;
          return _handleRunScript(
            data['scriptId'] as String,
            data['params'] as List,
          );

        default:
          print('⚠️ 未知的消息通道: $channel');
          return null;
      }
    } catch (e) {
      print('❌ 处理消息失败 [$channel]: $e');
      return null;
    }
  }

  /// 处理日志
  void _handleLog(String message, String level) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] [$level] $message');

    // 调用外部日志回调
    onLog?.call(message, level);
  }

  /// 处理存储读取
  String? _handleStorageGet(String key) {
    // 由于flutter_js不支持真正的异步，这里使用同步方式
    // 实际应用中可能需要预加载数据
    try {
      // 这里需要使用同步读取或者预加载的缓存
      // 简化实现：返回null，实际应该从缓存读取
      return null;
    } catch (e) {
      print('❌ 存储读取失败: $e');
      return null;
    }
  }

  /// 处理存储写入
  void _handleStorageSet(String key, dynamic value) {
    storage.write(key, value).catchError((e) {
      print('❌ 存储写入失败: $e');
    });
  }

  /// 处理存储删除
  void _handleStorageRemove(String key) {
    storage.delete(key).catchError((e) {
      print('❌ 存储删除失败: $e');
    });
  }

  /// 处理事件触发
  void _handleEmit(String eventName, dynamic data) {
    try {
      eventManager.broadcast(eventName, EventArgs(eventName));
      print('📡 触发事件: $eventName');
    } catch (e) {
      print('❌ 触发事件失败: $e');
    }
  }

  /// 处理脚本调用
  String? _handleRunScript(String scriptId, List params) {
    // 检测循环调用
    if (_executingScripts.contains(scriptId)) {
      print('❌ 检测到循环调用: $scriptId');
      return jsonEncode({
        'success': false,
        'error': '检测到循环调用: $scriptId',
      });
    }

    // 由于flutter_js的限制，这里无法实现真正的脚本互调
    // 实际应用中需要使用队列或者其他异步机制
    print('⚠️ runScript功能需要异步支持，当前版本暂不支持');
    return jsonEncode({
      'success': false,
      'error': 'runScript功能暂不支持（需要异步支持）',
    });
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

        // 包装代码（注入args参数）
        final wrappedCode = '''
        (function() {
          const args = $argsJson;
          try {
            return $code
          } catch (error) {
            log('脚本执行错误: ' + error.toString(), 'error');
            return { success: false, error: error.toString() };
          }
        })();
        ''';

        // 执行脚本（带超时控制）
        dynamic result;
        try {
          result = await _executeWithTimeout(wrappedCode);
        } on TimeoutException {
          throw Exception('脚本执行超时（${timeoutMilliseconds}ms）');
        }

        final duration = DateTime.now().difference(startTime);

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
      Future(() {
        try {
          // 执行JS代码
          final jsResult = _jsRuntime.evaluate(code);

          // 处理返回值
          if (jsResult.isError) {
            throw Exception(jsResult.stringResult);
          }

          // 解析返回值
          final resultStr = jsResult.stringResult;
          if (resultStr == 'undefined' || resultStr == 'null') {
            return null;
          }

          // 尝试解析JSON
          try {
            return jsonDecode(resultStr);
          } catch (e) {
            // 如果不是JSON，直接返回字符串
            return resultStr;
          }
        } catch (e) {
          throw Exception('JS执行错误: $e');
        }
      }),
    ]);
  }

  /// 评估表达式（用于调试）
  String? evaluateExpression(String expression) {
    if (!_isInitialized) return null;

    try {
      final result = _jsRuntime.evaluate(expression);
      return result.stringResult;
    } catch (e) {
      print('❌ 表达式评估失败: $e');
      return null;
    }
  }

  /// 清理资源
  void dispose() {
    _executingScripts.clear();
    _isInitialized = false;
    print('✅ ScriptExecutor已清理');
  }
}
