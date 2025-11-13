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

    // 注入全局辅助函数
    await evaluate('''
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
          sendMessage('_dartLog', message);
        },
        error: function() {
          var args = Array.prototype.slice.call(arguments);
          var message = args.map(function(arg) {
            if (typeof arg === 'object') {
              return JSON.stringify(arg);
            }
            return String(arg);
          }).join(' ');
          sendMessage('_dartError', message);
        }
      };

      // 辅助函数：调用 Dart 函数
      function _callDart(funcName, args) {
        var data = JSON.stringify({
          function: funcName,
          arguments: args
        });
        return sendMessage('dart_call', data);
      }
    ''');

    // 设置消息处理器
    _runtime.onMessage('_dartLog', (dynamic message) {
      print('[JS] $message');
      return null;
    });

    _runtime.onMessage('_dartError', (dynamic message) {
      print('[JS Error] $message');
      return null;
    });

    _runtime.onMessage('dart_call', (dynamic args) {
      try {
        final Map<String, dynamic> data = jsonDecode(args);
        final String funcName = data['function'];
        final List<dynamic> funcArgs = data['arguments'] ?? [];

        if (_registeredFunctions.containsKey(funcName)) {
          final result = Function.apply(_registeredFunctions[funcName]!, funcArgs);
          // 如果是 Future，需要等待结果
          if (result is Future) {
            // flutter_js 不支持异步返回，所以我们需要同步返回或者使用回调
            // 这里我们返回一个占位符，实际的异步处理需要通过其他方式
            return 'ASYNC_PENDING';
          }
          return result;
        }
      } catch (e) {
        print('JS bridge error: $e');
      }
      return null;
    });
  }

  @override
  Future<JSResult> evaluate(String code) async {
    try {
      final result = _runtime.evaluate(code);

      // 检查是否有错误
      final stringResult = result.stringResult;

      // 尝试判断结果类型
      // flutter_js 的 JsEvalResult 只提供 stringResult 和 rawResult
      if (stringResult.startsWith('Error:') ||
          stringResult.contains('ReferenceError') ||
          stringResult.contains('TypeError') ||
          stringResult.contains('SyntaxError')) {
        return JSResult.error(stringResult);
      }

      // 返回字符串结果
      return JSResult.success(stringResult);
    } catch (e) {
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

    await evaluate('var $name = $jsValue;');
  }

  @override
  Future<dynamic> getGlobal(String name) async {
    final result = await evaluate(name);
    return result.success ? result.result : null;
  }

  @override
  Future<void> registerFunction(String name, Function dartFunction) async {
    // 保存函数引用
    _registeredFunctions[name] = dartFunction;

    // 在 JS 中创建代理函数
    await evaluate('''
      function $name() {
        var args = Array.prototype.slice.call(arguments);
        return _callDart('$name', args);
      }
    ''');
  }

  @override
  Future<void> dispose() async {
    // flutter_js 不需要显式释放
    _registeredFunctions.clear();
    _initialized = false;
  }
}
