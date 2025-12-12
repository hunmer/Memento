import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:Memento/core/js_bridge/js_bridge_manager.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/webview/webview_plugin.dart';

/// JS Bridge Handlers 注册服务
///
/// 通过 flutter_inappwebview 的 JavaScript Handlers 使网页能够调用：
/// - Memento.plugins.<pluginId>.<method>()
/// - Memento.system.*
/// - Memento.plugins.ui.*
/// - Memento.storage.*
class JSBridgeInjector {
  final InAppWebViewController controller;
  final bool enabled;
  BuildContext? _context;

  JSBridgeInjector({
    required this.controller,
    this.enabled = true,
  });

  /// 设置 BuildContext（用于 UI 操作）
  void setContext(BuildContext context) {
    _context = context;
  }

  /// 初始化 JS Bridge Handlers（在 onWebViewCreated 中调用）
  Future<void> initialize() async {
    if (!enabled) return;

    // 注册核心 handler
    _registerCoreHandlers();
  }

  /// 注册核心 JavaScript Handlers
  void _registerCoreHandlers() {
    // Bridge 就绪信号 handler（供网页检测 bridge 是否可用）
    controller.addJavaScriptHandler(
      handlerName: 'Memento_ready',
      callback: (args) {
        debugPrint('[JSBridge] Memento_ready called');
        return true;
      },
    );

    // 插件调用 handler
    controller.addJavaScriptHandler(
      handlerName: 'Memento_plugin_call',
      callback: (args) async {
        if (args.isEmpty) return jsonEncode({'error': 'Missing arguments'});

        try {
          final data = args[0];
          final Map<String, dynamic> params;

          if (data is Map<String, dynamic>) {
            params = data;
          } else if (data is String) {
            params = jsonDecode(data) as Map<String, dynamic>;
          } else {
            return jsonEncode({'error': 'Invalid arguments type'});
          }

          final pluginId = params['pluginId'] as String?;
          final method = params['method'] as String?;
          final methodParams = params['params'] as Map<String, dynamic>? ?? {};

          if (pluginId == null || method == null) {
            return jsonEncode({'error': 'Missing pluginId or method'});
          }

          // 检查 JSBridgeManager 是否已初始化
          if (!JSBridgeManager.instance.isSupported) {
            return jsonEncode({
              'error': 'JS Bridge not initialized. Please wait for the bridge to be ready.',
            });
          }

          // 检查插件是否已注册
          final registeredPlugins = JSBridgeManager.instance.registeredPluginIds;
          if (!registeredPlugins.contains(pluginId)) {
            return jsonEncode({
              'error': 'Plugin "$pluginId" is not registered. Available plugins: ${registeredPlugins.join(", ")}',
            });
          }

          // 构建 JS Bridge 调用代码（必须有 return 语句才能获取返回值）
          final paramsJson = jsonEncode(methodParams);
          final code = 'return Memento_${pluginId}_$method($paramsJson)';

          final result = await JSBridgeManager.instance.evaluate(code);
          if (result.success) {
            return result.result;
          } else {
            return jsonEncode({'error': result.error});
          }
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }
      },
    );

    // 系统 API handler
    controller.addJavaScriptHandler(
      handlerName: 'Memento_system_call',
      callback: (args) async {
        if (args.isEmpty) return jsonEncode({'error': 'Missing arguments'});

        try {
          final data = args[0];
          final Map<String, dynamic> params;

          if (data is Map<String, dynamic>) {
            params = data;
          } else if (data is String) {
            params = jsonDecode(data) as Map<String, dynamic>;
          } else {
            return jsonEncode({'error': 'Invalid arguments type'});
          }

          final method = params['method'] as String?;
          final methodParams = params['params'];

          if (method == null) {
            return jsonEncode({'error': 'Missing method name'});
          }

          final paramsArg = methodParams != null ? jsonEncode(methodParams) : '';
          // 构建 JS Bridge 调用代码（必须有 return 语句才能获取返回值）
          final code = 'return Memento_system_$method($paramsArg)';

          final result = await JSBridgeManager.instance.evaluate(code);
          if (result.success) {
            return result.result;
          } else {
            return jsonEncode({'error': result.error});
          }
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }
      },
    );

    // UI Toast handler
    controller.addJavaScriptHandler(
      handlerName: 'Memento_ui_toast',
      callback: (args) {
        if (args.isEmpty || _context == null) return;

        try {
          final data = args[0];
          final Map<String, dynamic> params;

          if (data is Map<String, dynamic>) {
            params = data;
          } else if (data is String) {
            params = jsonDecode(data) as Map<String, dynamic>;
          } else {
            return;
          }

          final message = params['message'] as String? ?? '';
          ScaffoldMessenger.of(_context!).showSnackBar(
            SnackBar(content: Text(message)),
          );
        } catch (e) {
          debugPrint('Toast error: $e');
        }
      },
    );

    // UI Alert handler
    controller.addJavaScriptHandler(
      handlerName: 'Memento_ui_alert',
      callback: (args) async {
        if (args.isEmpty || _context == null) return false;

        try {
          final data = args[0];
          final Map<String, dynamic> params;

          if (data is Map<String, dynamic>) {
            params = data;
          } else if (data is String) {
            params = jsonDecode(data) as Map<String, dynamic>;
          } else {
            return false;
          }

          final message = params['message'] as String? ?? '';
          final options = params['options'] as Map<String, dynamic>? ?? {};

          final result = await showDialog<bool>(
            context: _context!,
            builder: (ctx) => AlertDialog(
              title: Text(options['title'] as String? ?? '提示'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(options['confirmText'] as String? ?? '确定'),
                ),
              ],
            ),
          );
          return result ?? false;
        } catch (e) {
          debugPrint('Alert error: $e');
          return false;
        }
      },
    );

    // UI Dialog handler
    controller.addJavaScriptHandler(
      handlerName: 'Memento_ui_dialog',
      callback: (args) async {
        if (args.isEmpty || _context == null) return null;

        try {
          final data = args[0];
          final Map<String, dynamic> options;

          if (data is Map<String, dynamic>) {
            options = data;
          } else if (data is String) {
            options = jsonDecode(data) as Map<String, dynamic>;
          } else {
            return null;
          }

          final result = await showDialog<bool>(
            context: _context!,
            builder: (ctx) => AlertDialog(
              title: Text(options['title'] as String? ?? ''),
              content: Text(options['content'] as String? ?? ''),
              actions: [
                if (options['showCancel'] != false)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(options['cancelText'] as String? ?? '取消'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(options['confirmText'] as String? ?? '确定'),
                ),
              ],
            ),
          );
          return result;
        } catch (e) {
          debugPrint('Dialog error: $e');
          return null;
        }
      },
    );

    // Storage read handler
    controller.addJavaScriptHandler(
      handlerName: 'Memento_storage_read',
      callback: (args) async {
        if (args.isEmpty) return jsonEncode({'error': 'Missing arguments'});

        try {
          final data = args[0];
          final Map<String, dynamic> params;

          if (data is Map<String, dynamic>) {
            params = data;
          } else if (data is String) {
            params = jsonDecode(data) as Map<String, dynamic>;
          } else {
            return jsonEncode({'error': 'Invalid arguments type'});
          }

          final key = params['key'] as String?;
          if (key == null) {
            return jsonEncode({'error': 'Missing key parameter'});
          }

          // 获取 webview 插件的存储
          final webviewPlugin = PluginManager.instance.getPlugin('webview') as WebViewPlugin?;
          if (webviewPlugin == null) {
            return jsonEncode({'error': 'WebView plugin not found'});
          }

          // 构建存储路径: app_data/webview/<key>
          final storagePath = 'webview/$key';
          final result = await webviewPlugin.storage.read(storagePath);

          if (result == null) {
            return jsonEncode({'success': true, 'data': null});
          }
          return jsonEncode({'success': true, 'data': result});
        } catch (e) {
          debugPrint('Storage read error: $e');
          return jsonEncode({'error': e.toString()});
        }
      },
    );

    // Storage write handler
    controller.addJavaScriptHandler(
      handlerName: 'Memento_storage_write',
      callback: (args) async {
        if (args.isEmpty) return jsonEncode({'error': 'Missing arguments'});

        try {
          final data = args[0];
          final Map<String, dynamic> params;

          if (data is Map<String, dynamic>) {
            params = data;
          } else if (data is String) {
            params = jsonDecode(data) as Map<String, dynamic>;
          } else {
            return jsonEncode({'error': 'Invalid arguments type'});
          }

          final key = params['key'] as String?;
          final value = params['value'];

          if (key == null) {
            return jsonEncode({'error': 'Missing key parameter'});
          }

          // 获取 webview 插件的存储
          final webviewPlugin = PluginManager.instance.getPlugin('webview') as WebViewPlugin?;
          if (webviewPlugin == null) {
            return jsonEncode({'error': 'WebView plugin not found'});
          }

          // 构建存储路径: app_data/webview/<key>
          final storagePath = 'webview/$key';
          await webviewPlugin.storage.write(storagePath, value);

          return jsonEncode({'success': true});
        } catch (e) {
          debugPrint('Storage write error: $e');
          return jsonEncode({'error': e.toString()});
        }
      },
    );

    // Storage delete handler
    controller.addJavaScriptHandler(
      handlerName: 'Memento_storage_delete',
      callback: (args) async {
        if (args.isEmpty) return jsonEncode({'error': 'Missing arguments'});

        try {
          final data = args[0];
          final Map<String, dynamic> params;

          if (data is Map<String, dynamic>) {
            params = data;
          } else if (data is String) {
            params = jsonDecode(data) as Map<String, dynamic>;
          } else {
            return jsonEncode({'error': 'Invalid arguments type'});
          }

          final key = params['key'] as String?;
          if (key == null) {
            return jsonEncode({'error': 'Missing key parameter'});
          }

          // 获取 webview 插件的存储
          final webviewPlugin = PluginManager.instance.getPlugin('webview') as WebViewPlugin?;
          if (webviewPlugin == null) {
            return jsonEncode({'error': 'WebView plugin not found'});
          }

          // 构建存储路径: app_data/webview/<key>
          final storagePath = 'webview/$key';
          await webviewPlugin.storage.delete(storagePath);

          return jsonEncode({'success': true});
        } catch (e) {
          debugPrint('Storage delete error: $e');
          return jsonEncode({'error': e.toString()});
        }
      },
    );
  }
}
