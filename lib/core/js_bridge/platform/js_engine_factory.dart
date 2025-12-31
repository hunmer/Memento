import 'package:flutter/foundation.dart' show kIsWeb;
import 'js_engine_interface.dart';
// 条件导入：默认 Web 平台存根，有 IO 库时（移动/桌面）使用真实实现
import 'mobile_js_engine_stub.dart'
    if (dart.library.io) 'mobile_js_engine.dart';
// 条件导入：默认移动/桌面存根，有 HTML 库时（Web）使用真实实现
import 'web_js_engine_stub.dart'
    if (dart.library.html) 'web_js_engine.dart';

class JSEngineFactory {
  static JSEngine create() {
    if (kIsWeb) {
      return WebJSEngine();
    } else {
      // 移动端和桌面端都使用 flutter_js
      return MobileJSEngine();
    }
  }
}
