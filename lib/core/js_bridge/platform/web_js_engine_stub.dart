import 'js_engine_interface.dart';

/// Web JS 引擎的存根实现（用于非 Web 平台）
/// 这个类在非 Web 平台不会被实例化，只是为了编译通过
class WebJSEngine implements JSEngine {
  @override
  bool get isSupported => false;

  @override
  Future<void> initialize() async {
    throw UnsupportedError('WebJSEngine is only available on web platform');
  }

  @override
  Future<JSResult> evaluate(String code) async {
    throw UnsupportedError('WebJSEngine is only available on web platform');
  }

  @override
  Future<void> evaluateDirect(String code) async {
    throw UnsupportedError('WebJSEngine is only available on web platform');
  }

  @override
  Future<void> setGlobal(String name, dynamic value) async {
    throw UnsupportedError('WebJSEngine is only available on web platform');
  }

  @override
  Future<dynamic> getGlobal(String name) async {
    throw UnsupportedError('WebJSEngine is only available on web platform');
  }

  @override
  Future<void> registerFunction(String name, Function dartFunction) async {
    throw UnsupportedError('WebJSEngine is only available on web platform');
  }

  @override
  Future<void> dispose() async {
    throw UnsupportedError('WebJSEngine is only available on web platform');
  }
}
