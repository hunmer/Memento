import 'dart:convert';
import 'dart:js' as js;
import 'js_engine_interface.dart';

class WebJSEngine implements JSEngine {
  bool _initialized = false;

  @override
  bool get isSupported => true;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    // Web 平台无需初始化，但需要确保 console 对象存在
    _initialized = true;
  }

  @override
  Future<JSResult> evaluate(String code) async {
    try {
      final result = js.context.callMethod('eval', [code]);
      return JSResult.success(_convertJSValue(result));
    } catch (e) {
      return JSResult.error(e.toString());
    }
  }

  @override
  Future<void> setGlobal(String name, dynamic value) async {
    js.context[name] = _convertDartValue(value);
  }

  @override
  Future<dynamic> getGlobal(String name) async {
    return _convertJSValue(js.context[name]);
  }

  @override
  Future<void> registerFunction(String name, Function dartFunction) async {
    // 包装函数以处理参数
    js.context[name] = js.allowInterop(([a, b, c, d, e, f, g, h, i, j]) {
      // 收集所有非 null 的参数
      final args = [a, b, c, d, e, f, g, h, i, j]
          .where((arg) => arg != null)
          .map((arg) => _convertJSValue(arg))
          .toList();

      try {
        final result = Function.apply(dartFunction, args);

        // 处理 Future 返回值
        if (result is Future) {
          return result.then((value) => _convertDartValue(value));
        }

        return _convertDartValue(result);
      } catch (e) {
        print('JS bridge error: $e');
        throw e;
      }
    });
  }

  @override
  Future<void> dispose() async {
    // Web 平台无需释放
    _initialized = false;
  }

  // 转换 JS 值到 Dart
  dynamic _convertJSValue(dynamic value) {
    if (value == null) return null;
    if (value is String || value is num || value is bool) return value;

    // 尝试转换对象和数组
    try {
      if (value is js.JsObject) {
        // 尝试将 JS 对象转换为 JSON 字符串
        final jsonString = js.context.callMethod('JSON.stringify', [value]);
        return jsonString;
      }
      return value.toString();
    } catch (e) {
      return value.toString();
    }
  }

  // 转换 Dart 值到 JS
  dynamic _convertDartValue(dynamic value) {
    if (value == null) return null;
    if (value is String || value is num || value is bool) return value;

    if (value is Map || value is List) {
      try {
        // 先转换为 JSON 字符串，然后解析为 JS 对象
        final jsonString = jsonEncode(value);
        return js.context.callMethod('JSON.parse', [jsonString]);
      } catch (e) {
        print('Failed to convert Dart value to JS: $e');
        return value.toString();
      }
    }

    return value;
  }
}
