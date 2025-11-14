import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
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
      final result = globalContext.callMethod('eval'.toJS, code.toJS);
      return JSResult.success(_convertJSValue(result));
    } catch (e) {
      return JSResult.error(e.toString());
    }
  }

  @override
  Future<void> evaluateDirect(String code) async {
    // Web 平台直接执行代码，不返回结果
    try {
      globalContext.callMethod('eval'.toJS, code.toJS);
    } catch (e) {
      print('WebJSEngine evaluateDirect error: $e');
    }
  }

  @override
  Future<void> setGlobal(String name, dynamic value) async {
    globalContext.setProperty(name.toJS, _convertDartValue(value));
  }

  @override
  Future<dynamic> getGlobal(String name) async {
    return _convertJSValue(globalContext.getProperty(name.toJS));
  }

  @override
  Future<void> registerFunction(String name, Function dartFunction) async {
    // 创建一个包装函数，接受可变数量的参数
    JSFunction jsFunction = ((
      JSAny? a,
      JSAny? b,
      JSAny? c,
      JSAny? d,
      JSAny? e,
      JSAny? f,
      JSAny? g,
      JSAny? h,
      JSAny? i,
      JSAny? j,
    ) {
      // 收集所有非 null 的参数
      final args = [a, b, c, d, e, f, g, h, i, j]
          .where((arg) => arg != null)
          .map((arg) => _convertJSValue(arg))
          .toList();

      try {
        final result = Function.apply(dartFunction, args);

        // 处理 Future 返回值
        if (result is Future) {
          return result.then((value) => _convertDartValue(value)).toJS;
        }

        return _convertDartValue(result);
      } catch (e) {
        print('JS bridge error: $e');
        rethrow;
      }
    }).toJS;

    globalContext.setProperty(name.toJS, jsFunction);
  }

  @override
  Future<void> dispose() async {
    // Web 平台无需释放
    _initialized = false;
  }

  // 转换 JS 值到 Dart
  dynamic _convertJSValue(JSAny? value) {
    if (value == null) return null;

    // 尝试转换为基本类型
    try {
      // 检查是否是字符串
      if (value.typeofEquals('string')) {
        return (value as JSString).toDart;
      }

      // 检查是否是数字
      if (value.typeofEquals('number')) {
        return (value as JSNumber).toDartDouble;
      }

      // 检查是否是布尔值
      if (value.typeofEquals('boolean')) {
        return (value as JSBoolean).toDart;
      }

      // 对于对象，尝试转换为 JSON 字符串
      final jsonString = globalContext.callMethod(
        'JSON.stringify'.toJS,
        value,
      );
      if (jsonString != null) {
        return (jsonString as JSString).toDart;
      }

      return value.toString();
    } catch (e) {
      return value.toString();
    }
  }

  // 转换 Dart 值到 JS
  JSAny? _convertDartValue(dynamic value) {
    if (value == null) return null;

    if (value is String) return value.toJS;
    if (value is num) return value.toJS;
    if (value is bool) return value.toJS;

    if (value is Map || value is List) {
      try {
        // 先转换为 JSON 字符串，然后解析为 JS 对象
        final jsonString = jsonEncode(value);
        return globalContext.callMethod(
          'JSON.parse'.toJS,
          jsonString.toJS,
        );
      } catch (e) {
        print('Failed to convert Dart value to JS: $e');
        return value.toString().toJS;
      }
    }

    return value.toString().toJS;
  }
}
