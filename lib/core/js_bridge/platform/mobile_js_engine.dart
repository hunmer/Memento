import 'dart:convert';
import 'package:flutter_js/flutter_js.dart';
import 'js_engine_interface.dart';

class MobileJSEngine implements JSEngine {
  late JavascriptRuntime _runtime;
  bool _initialized = false;
  final Map<String, Function> _registeredFunctions = {};

  @override
  bool get isSupported => true; // Android/iOS/Desktop 都支持

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    _runtime = getJavascriptRuntime();
    _initialized = true;

    // 注入全局辅助函数和结果存储（直接执行，不通过 evaluate）
    _runtime.evaluate('''
      // 初始化全局结果存储
      if (!globalThis.__EVAL_RESULTS__) {
        globalThis.__EVAL_RESULTS__ = {};
      }

      // 初始化待处理调用存储（用于不依赖 setTimeout 的 Promise）
      if (!globalThis.__PENDING_CALLS__) {
        globalThis.__PENDING_CALLS__ = {};
      }

      // 定义 console 对象
      var console = {
        log: function() {
          var args = Array.prototype.slice.call(arguments);
          var message = args.map(function(arg) {
            if (typeof arg === 'object') {
              return JSON.stringify(arg);
            }
            return String(arg);
          }).join(' ');
          // 包装成 JSON 对象以避免 FormatException
          sendMessage('_dartLog', JSON.stringify({ message: message }));
          return undefined;  // 明确返回 undefined
        },
        error: function() {
          var args = Array.prototype.slice.call(arguments);
          var message = args.map(function(arg) {
            if (typeof arg === 'object') {
              return JSON.stringify(arg);
            }
            return String(arg);
          }).join(' ');
          // 包装成 JSON 对象以避免 FormatException
          sendMessage('_dartError', JSON.stringify({ message: message }));
          return undefined;  // 明确返回 undefined
        }
      };
    ''');

    // 设置消息处理器（QuickJS 期望返回 undefined 而不是 null）
    _runtime.onMessage('_dartLog', (dynamic data) {
      try {
        // 从 JSON 对象中提取消息
        final message = data is Map ? data['message'] : data.toString();
        print('[JS] $message');
      } catch (e) {
        print('[JS] (解析失败) $data');
      }
      // 不返回任何值（自动返回 undefined）
    });

    _runtime.onMessage('_dartError', (dynamic data) {
      try {
        // 从 JSON 对象中提取消息
        final message = data is Map ? data['message'] : data.toString();
        print('[JS Error] $message');
      } catch (e) {
        print('[JS Error] (解析失败) $data');
      }
      // 不返回任何值（自动返回 undefined）
    });
  }

  @override
  Future<void> evaluateDirect(String code) async {
    // 直接执行代码，不包装，不等待结果（用于注册函数等操作）
    _runtime.evaluate(code);
  }

  @override
  Future<JSResult> evaluate(String code) async {
    try {
      print('[JS Debug] ========== 开始执行代码 ==========');

      // 生成唯一的执行 ID
      final executionId = DateTime.now().millisecondsSinceEpoch.toString() +
          '_${DateTime.now().microsecond}';

      // 包装用户代码：提供 setResult 函数并自动捕获返回值
      final wrappedCode = '''
        (async function() {
          console.log('[Wrapper] 开始执行包装代码');

          // 定义 setResult 函数，用户可以显式设置返回值
          globalThis.setResult = function(value) {
            console.log('[setResult] 被调用，值类型:', typeof value);
            if (typeof value === 'object' && value !== null) {
              globalThis.__EVAL_RESULTS__['$executionId'] = JSON.stringify(value);
            } else if (value === undefined) {
              globalThis.__EVAL_RESULTS__['$executionId'] = 'undefined';
            } else {
              globalThis.__EVAL_RESULTS__['$executionId'] = String(value);
            }
            console.log('[setResult] 结果已保存到 $executionId');
          };

          try {
            // 执行用户代码并等待完成
            console.log('[Wrapper] 执行用户代码...');
            var result = await (async function() {
              ${code}
            })();

            console.log('[Wrapper] 用户代码执行完成，结果类型:', typeof result);

            // 如果用户没有调用 setResult，自动设置结果
            if (!globalThis.__EVAL_RESULTS__['$executionId']) {
              console.log('[Wrapper] 自动调用 setResult');
              globalThis.setResult(result);
            } else {
              console.log('[Wrapper] 用户已调用 setResult，跳过自动设置');
            }
          } catch (error) {
            console.error('[Wrapper] 执行错误:', error);
            // 保存错误信息
            globalThis.__EVAL_RESULTS__['$executionId'] = 'Error: ' + error.toString();
          } finally {
            console.log('[Wrapper] 清理 setResult 函数');
            // 清理 setResult 函数
            delete globalThis.setResult;
          }
        })();
      ''';

      // 执行包装后的代码
      await _runtime.evaluateAsync(wrappedCode);
      print('[JS Debug] 代码已提交执行，等待结果...');

      // 初始处理：密集执行微任务并处理待处理调用
      print('[JS Debug] 初始密集处理微任务...');
      for (int i = 0; i < 50; i++) {
        // 处理待处理的 Promise 调用
        _runtime.evaluate('''
          (function() {
            var keys = Object.keys(globalThis.__PENDING_CALLS__ || {});
            for (var i = 0; i < keys.length; i++) {
              var key = keys[i];
              var pending = globalThis.__PENDING_CALLS__[key];

              if (globalThis.__DART_RESULTS__[key]) {
                var resultJson = globalThis.__DART_RESULTS__[key];
                delete globalThis.__DART_RESULTS__[key];
                delete globalThis.__PENDING_CALLS__[key];

                try {
                  var parsed = JSON.parse(resultJson);
                  if (parsed && parsed.error) {
                    pending.reject(new Error(parsed.error));
                  } else {
                    pending.resolve(parsed);
                  }
                } catch (e) {
                  pending.resolve(resultJson);
                }
              }
            }
          })();
        ''');

        _runtime.executePendingJob();
        await Future.delayed(Duration(milliseconds: 10));
      }

      // 轮询结果（最多等待 5 秒）
      String? resultStr;
      int retryCount = 0;
      const maxRetries = 100; // 100 * 50ms = 5 秒

      while (retryCount < maxRetries) {
        // 1. 处理待处理的 Promise 调用（不依赖 setTimeout）
        _runtime.evaluate('''
          (function() {
            var keys = Object.keys(globalThis.__PENDING_CALLS__ || {});
            for (var i = 0; i < keys.length; i++) {
              var key = keys[i];
              var pending = globalThis.__PENDING_CALLS__[key];

              // 检查 Dart 是否已返回结果
              if (globalThis.__DART_RESULTS__[key]) {
                var resultJson = globalThis.__DART_RESULTS__[key];
                delete globalThis.__DART_RESULTS__[key];
                delete globalThis.__PENDING_CALLS__[key];

                try {
                  var parsed = JSON.parse(resultJson);
                  if (parsed && parsed.error) {
                    pending.reject(new Error(parsed.error));
                  } else {
                    pending.resolve(parsed);
                  }
                } catch (e) {
                  pending.resolve(resultJson);
                }
              }
            }
          })();
        ''');

        // 2. 持续处理微任务队列
        for (int i = 0; i < 20; i++) {
          _runtime.executePendingJob();
        }

        // 3. 给 Dart 事件循环时间
        await Future.delayed(Duration(milliseconds: 50));

        // 4. 检查用户代码的结果是否已准备好
        try {
          // 先检查键是否存在
          final existsCode = "'$executionId' in globalThis.__EVAL_RESULTS__";
          final existsResult = _runtime.evaluate(existsCode);
          final exists = existsResult.stringResult;

          if (exists == 'true') {
            // 键存在，读取值
            final checkCode = "globalThis.__EVAL_RESULTS__['$executionId']";
            final checkResult = _runtime.evaluate(checkCode);
            resultStr = checkResult.stringResult;
            print('[JS Debug] 第 ${retryCount + 1} 次轮询，获取到结果');
            break;
          }

          // 每 10 次输出调试信息
          if (retryCount % 10 == 0 && retryCount > 0) {
            print('[JS Debug] 第 $retryCount 次轮询，结果尚未准备好...');
          }
        } catch (e) {
          // 结果还未准备好，继续等待
          if (retryCount % 20 == 0 && retryCount > 0) {
            print('[JS Debug] 轮询异常: $e');
          }
        }

        retryCount++;
      }

      // 清理结果存储
      try {
        _runtime.evaluate("delete globalThis.__EVAL_RESULTS__['$executionId'];");
      } catch (e) {
        // 忽略清理错误
      }

      print('[JS Debug] ========== 最终结果 ==========');
      print('[JS Debug] 轮询次数: ${retryCount + 1}');
      print('[JS Debug] 结果内容: $resultStr');
      print('[JS Debug] ====================================');

      // 处理超时
      if (resultStr == null) {
        return JSResult.error('执行超时：代码未在 5 秒内返回结果');
      }

      // 检查错误
      if (resultStr.startsWith('Error:')) {
        return JSResult.error(resultStr);
      }

      // 处理 undefined
      if (resultStr == 'undefined') {
        return JSResult.success(null);
      }

      // 尝试解析 JSON
      try {
        final decoded = jsonDecode(resultStr);
        return JSResult.success(decoded);
      } catch (e) {
        // 不是 JSON，返回原始字符串
        return JSResult.success(resultStr);
      }
    } catch (e) {
      print('[JS Debug] !!!!! evaluate 异常 !!!!!: $e');
      return JSResult.error(e.toString());
    }
  }

  @override
  Future<void> setGlobal(String name, dynamic value) async {
    String jsValue;
    if (value is String) {
      jsValue = "'${value.replaceAll("'", "\\'")}'";
    } else if (value is Map || value is List) {
      jsValue = jsonEncode(value);
    } else {
      jsValue = value.toString();
    }

    await evaluateDirect('globalThis.$name = $jsValue;');
  }

  @override
  Future<dynamic> getGlobal(String name) async {
    final result = await evaluate(name);
    return result.success ? result.result : null;
  }

  @override
  Future<void> registerFunction(String name, Function dartFunction) async {
    _registeredFunctions[name] = dartFunction;

    // flutter_js 的 sendMessage/onMessage 不支持异步返回值
    // 使用回调模式：JS 调用 Dart → Dart 处理 → Dart 通过另一个 sendMessage 返回结果

    // 为每个函数创建唯一的回调频道
    String callbackChannel = '${name}_callback';

    // 注册 JS 函数（返回 Promise）
    // 注意：__DART_RESULTS__ 已在 initialize 中创建
    // QuickJS 的 setTimeout 不可靠，改用标记 + 外部轮询
    final code = '''
      var $name = function() {
        var args = Array.prototype.slice.call(arguments);

        // 生成唯一 ID（使用整数避免小数点）
        var callId = Date.now() + '_' + Math.floor(Math.random() * 1000000);
        var resultKey = '${callbackChannel}_' + callId;

        // 调用 Dart 函数（立即触发）
        sendMessage('$name', JSON.stringify({ callId: callId, args: args }));

        // 标记此 Promise 正在等待，供外部轮询
        if (!globalThis.__PENDING_CALLS__) {
          globalThis.__PENDING_CALLS__ = {};
        }
        globalThis.__PENDING_CALLS__[resultKey] = {
          resolve: null,
          reject: null,
          timestamp: Date.now()
        };

        // 返回 Promise（resolve/reject 由外部轮询触发）
        return new Promise(function(resolve, reject) {
          globalThis.__PENDING_CALLS__[resultKey].resolve = resolve;
          globalThis.__PENDING_CALLS__[resultKey].reject = reject;
        });
      };
    ''';

    // 使用 evaluateDirect 注册函数（不需要等待结果）
    await evaluateDirect(code);

    // 注册 Dart 端处理器
    _runtime.onMessage(name, (dynamic data) {
      try {
        print('[JS Bridge] 调用函数: $name, 数据: $data');

        final callId = data['callId'];
        final args = data['args'] as List<dynamic>?;

        // 调用 Dart 函数
        final result = Function.apply(dartFunction, args ?? []);
        print('[JS Bridge] 结果类型: ${result.runtimeType}');

        // 辅助函数：将结果写入全局变量
        void setJsResult(String jsonResult) {
          // 转义 JSON 字符串中的特殊字符
          final escapedJson = jsonResult
              .replaceAll('\\', '\\\\')  // 反斜杠
              .replaceAll("'", "\\'")    // 单引号
              .replaceAll('\n', '\\n')   // 换行
              .replaceAll('\r', '\\r');  // 回车

          // 将结果写入全局变量
          final resultKey = '${callbackChannel}_${callId}';
          final jsCode = "globalThis.__DART_RESULTS__['$resultKey'] = '$escapedJson';";
          print('[JS Bridge] 设置结果: $jsCode');
          _runtime.evaluate(jsCode);  // 使用 _runtime.evaluate 避免创建新上下文
        }

        // 处理结果（同步或异步）
        if (result is Future) {
          result.then((value) {
            final jsonResult = value is String ? value : jsonEncode(value);
            print('[JS Bridge] Future 结果: $jsonResult');
            setJsResult(jsonResult);
          }).catchError((e) {
            print('[JS Bridge] Future 错误: $e');
            final errorJson = jsonEncode({'error': e.toString()});
            setJsResult(errorJson);
          });
        } else {
          final jsonResult = result is String ? result : jsonEncode(result);
          print('[JS Bridge] 同步结果: $jsonResult');
          setJsResult(jsonResult);
        }
      } catch (e) {
        print('[JS Bridge] 错误: $e');
        // 发送错误给 JS
        final errorJson = jsonEncode({'error': e.toString()});
        final callId = data['callId'];
        final resultKey = '${callbackChannel}_${callId}';

        final escapedJson = errorJson
            .replaceAll('\\', '\\\\')
            .replaceAll("'", "\\'")
            .replaceAll('\n', '\\n')
            .replaceAll('\r', '\\r');

        _runtime.evaluate("globalThis.__DART_RESULTS__['$resultKey'] = '$escapedJson';");
      }
    });
  }

  @override
  Future<void> dispose() async {
    // flutter_js 不需要显式释放
    _registeredFunctions.clear();
    _initialized = false;
  }
}
