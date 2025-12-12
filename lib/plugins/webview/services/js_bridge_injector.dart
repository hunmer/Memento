import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:Memento/core/js_bridge/js_bridge_manager.dart';

/// JS Bridge 注入服务
///
/// 将 Memento 命名空间注入到 WebView 中，使网页能够调用：
/// - Memento.plugins.<pluginId>.<method>()
/// - Memento.system.*
/// - Memento.plugins.ui.*
class JSBridgeInjector {
  final InAppWebViewController controller;
  final bool enabled;
  BuildContext? _context;
  final Set<String> _injectedPages = {};

  JSBridgeInjector({
    required this.controller,
    this.enabled = true,
  });

  /// 设置 BuildContext（用于 UI 操作）
  void setContext(BuildContext context) {
    _context = context;
  }

  /// 重置注入状态（在新页面加载时调用）
  void reset() {
    _injectedPages.clear();
  }

  /// 初始化 JS Bridge（在 onWebViewCreated 中调用）
  Future<void> initialize() async {
    if (!enabled) return;

    // 注册核心 handler
    _registerCoreHandlers();
  }

  /// 注入 JS Bridge（在 onLoadStop 中调用）
  Future<void> inject(String? currentUrl) async {
    if (!enabled) return;

    // 防止重复注入同一页面
    if (currentUrl != null && _injectedPages.contains(currentUrl)) {
      return;
    }

    // 1. 注入基础命名空间
    await _injectBaseNamespace();

    // 2. 注入插件代理
    await _injectPluginProxies();

    // 3. 注入系统 API 代理
    await _injectSystemAPIs();

    // 4. 注入 UI API 代理
    await _injectUIAPIs();

    // 标记该页面已注入
    if (currentUrl != null) {
      _injectedPages.add(currentUrl);
    }
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
  }

  /// 注入基础命名空间
  Future<void> _injectBaseNamespace() async {
    const script = '''
    (function() {
      if (typeof window.Memento !== 'undefined') return;

      window.Memento = {
        version: '1.0.0',
        plugins: {},
        system: {},
        _ready: false,
        _readyCallbacks: []
      };

      window.Memento.ready = function(callback) {
        if (window.Memento._ready) {
          try { callback(); } catch(e) { console.error('Memento ready callback error:', e); }
        } else {
          window.Memento._readyCallbacks.push(callback);
        }
      };

      console.log('[Memento] JS Bridge namespace initialized');
    })();
    ''';

    await controller.evaluateJavascript(source: script);
  }

  /// 注入插件代理
  Future<void> _injectPluginProxies() async {
    const script = '''
    (function() {
      if (!window.Memento) return;

      // 使用 Proxy 动态代理所有插件调用
      window.Memento.plugins = new Proxy({}, {
        get: function(target, pluginId) {
          // 跳过内置属性
          if (pluginId === 'ui' || typeof pluginId === 'symbol') {
            return target[pluginId];
          }

          // 为每个插件创建代理
          if (!target[pluginId]) {
            target[pluginId] = new Proxy({}, {
              get: function(_, methodName) {
                if (typeof methodName === 'symbol') return undefined;

                return function(params) {
                  return window.flutter_inappwebview.callHandler('Memento_plugin_call', {
                    pluginId: pluginId,
                    method: methodName,
                    params: params || {}
                  }).then(function(result) {
                    if (typeof result === 'string') {
                      try {
                        return JSON.parse(result);
                      } catch(e) {
                        return result;
                      }
                    }
                    return result;
                  });
                };
              }
            });
          }
          return target[pluginId];
        }
      });

      console.log('[Memento] Plugin proxies initialized');
    })();
    ''';

    await controller.evaluateJavascript(source: script);
  }

  /// 注入系统 API 代理
  Future<void> _injectSystemAPIs() async {
    const script = '''
    (function() {
      if (!window.Memento) return;

      var systemMethods = [
        'getCurrentTime',
        'getDeviceInfo',
        'getAppInfo',
        'formatDate',
        'getTimestamp',
        'getCustomDate'
      ];

      window.Memento.system = {};

      systemMethods.forEach(function(methodName) {
        window.Memento.system[methodName] = function(params) {
          return window.flutter_inappwebview.callHandler('Memento_system_call', {
            method: methodName,
            params: params
          }).then(function(result) {
            if (typeof result === 'string') {
              try {
                return JSON.parse(result);
              } catch(e) {
                return result;
              }
            }
            return result;
          });
        };
      });

      console.log('[Memento] System APIs initialized');
    })();
    ''';

    await controller.evaluateJavascript(source: script);
  }

  /// 注入 UI API 代理
  Future<void> _injectUIAPIs() async {
    const script = '''
    (function() {
      if (!window.Memento || !window.Memento.plugins) return;

      // 定义 UI API
      var uiApi = {
        toast: function(message, options) {
          return window.flutter_inappwebview.callHandler('Memento_ui_toast', {
            message: message,
            options: options || {}
          });
        },

        alert: function(message, options) {
          return window.flutter_inappwebview.callHandler('Memento_ui_alert', {
            message: message,
            options: options || {}
          });
        },

        dialog: function(options) {
          return window.flutter_inappwebview.callHandler('Memento_ui_dialog', options || {});
        }
      };

      // 同时支持 Memento.plugins.ui 和 Memento.ui 两种调用方式
      window.Memento.plugins.ui = uiApi;
      window.Memento.ui = uiApi;

      // 标记准备完成并触发回调
      window.Memento._ready = true;
      if (window.Memento._readyCallbacks) {
        window.Memento._readyCallbacks.forEach(function(cb) {
          try { cb(); } catch(e) { console.error('Memento ready callback error:', e); }
        });
        window.Memento._readyCallbacks = [];
      }

      console.log('[Memento] UI APIs initialized, bridge ready');
    })();
    ''';

    await controller.evaluateJavascript(source: script);
  }
}
