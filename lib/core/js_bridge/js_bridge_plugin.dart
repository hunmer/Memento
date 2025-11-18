import 'package:flutter/foundation.dart';
import '../plugin_base.dart';
import 'js_bridge_manager.dart';

/// 插件 JS 桥接能力 Mixin
///
/// 使用方法：
/// ```dart
/// class MyPlugin extends BasePlugin with JSBridgePlugin {
///   @override
///   Map<String, Function> defineJSAPI() {
///     return {
///       'getData': _jsGetData,
///       'setData': _jsSetData,
///     };
///   }
///
///   @override
///   Future<void> initialize() async {
///     // ... 其他初始化代码 ...
///
///     // 注册 JS API（最后一步）
///     await registerJSAPI();
///   }
/// }
/// ```
mixin JSBridgePlugin on PluginBase {
  /// 定义插件的 JS API
  ///
  // ignore: unintended_html_in_doc_comment
  /// 返回 Map<API名称, Dart函数>
  ///
  /// 示例：
  /// ```dart
  /// @override
  /// Map<String, Function> defineJSAPI() {
  ///   return {
  ///     'getChannels': _jsGetChannels,
  ///     'sendMessage': _jsSendMessage,
  ///   };
  /// }
  ///
  /// Future<String> _jsGetChannels(Map<String, dynamic> params) async {
  ///   final channels = await getChannels();
  ///   return jsonEncode(channels.map((c) => c.toJson()).toList());
  /// }
  /// ```
  Map<String, Function> defineJSAPI();

  /// 注册 JS API（在 initialize 中调用）
  ///
  /// 注意：这个方法应该在插件初始化的最后一步调用
  @protected
  Future<void> registerJSAPI() async {
    try {
      if (!JSBridgeManager.instance.isSupported) {
        print('[$id] JS Bridge 不支持，跳过 API 注册');
        return;
      }

      final apis = defineJSAPI();
      if (apis.isEmpty) {
        print('[$id] 没有定义 JS API');
        return;
      }

      await JSBridgeManager.instance.registerPlugin(this, apis);
      print('[$id] 成功注册 ${apis.length} 个 JS API');
    } catch (e) {
      print('[$id] JS API 注册失败: $e');
    }
  }

  /// 执行 JS 代码
  ///
  /// 用于插件内部执行 JS 代码（不常用）
  @protected
  Future<dynamic> evaluateJS(String code) async {
    final result = await JSBridgeManager.instance.evaluate(code);
    if (!result.success) {
      throw Exception('JS Error: ${result.error}');
    }
    return result.result;
  }
}
