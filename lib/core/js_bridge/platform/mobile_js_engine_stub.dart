import 'js_engine_interface.dart';

/// Mobile JS 引擎的存根实现（用于 Web 平台）
/// 这个类在 Web 平台不会被实例化，只是为了编译通过
class MobileJSEngine implements JSEngine {
  @override
  bool get isSupported => false;

  @override
  Future<void> initialize() async {
    throw UnsupportedError('MobileJSEngine is only available on mobile/desktop platforms');
  }

  @override
  Future<JSResult> evaluate(String code) async {
    throw UnsupportedError('MobileJSEngine is only available on mobile/desktop platforms');
  }

  @override
  Future<void> evaluateDirect(String code) async {
    throw UnsupportedError('MobileJSEngine is only available on mobile/desktop platforms');
  }

  @override
  Future<void> setGlobal(String name, dynamic value) async {
    throw UnsupportedError('MobileJSEngine is only available on mobile/desktop platforms');
  }

  @override
  Future<dynamic> getGlobal(String name) async {
    throw UnsupportedError('MobileJSEngine is only available on mobile/desktop platforms');
  }

  @override
  Future<void> registerFunction(String name, Function dartFunction) async {
    throw UnsupportedError('MobileJSEngine is only available on mobile/desktop platforms');
  }

  @override
  Future<void> dispose() async {
    throw UnsupportedError('MobileJSEngine is only available on mobile/desktop platforms');
  }
}
