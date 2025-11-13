import 'package:flutter/foundation.dart' show kIsWeb;
import 'js_engine_interface.dart';
import 'mobile_js_engine.dart';
// 条件导入：Web 平台使用真实实现，非 Web 平台使用存根
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
