import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:Memento/plugins/webview/webview_plugin.dart';

/// 可复用的嵌入式 WebView 组件
///
/// 纯 WebView 实现，不包含额外的 UI 元素
/// 支持完整的 JS Bridge 功能
/// 适合在小组件、对话框等场景中使用
class EmbeddedWebView extends StatefulWidget {
  /// 要加载的 URL
  final String url;

  /// 初始设置（可选）
  final InAppWebViewSettings? initialSettings;

  /// 是否启用 JS Bridge（默认为 true）
  final bool enableJSBridge;

  /// 加载进度回调
  final ValueChanged<double>? onProgressChanged;

  /// 加载状态变化回调
  final ValueChanged<bool>? onLoadingChanged;

  /// URL 变化回调
  final ValueChanged<String>? onUrlChanged;

  /// 标题变化回调
  final ValueChanged<String>? onTitleChanged;

  /// 加载完成回调
  final VoidCallback? onLoadStop;

  /// 加载错误回调
  final void Function(int code, String message)? onLoadError;

  const EmbeddedWebView({
    super.key,
    required this.url,
    this.initialSettings,
    this.enableJSBridge = true,
    this.onProgressChanged,
    this.onLoadingChanged,
    this.onUrlChanged,
    this.onTitleChanged,
    this.onLoadStop,
    this.onLoadError,
  });

  @override
  State<EmbeddedWebView> createState() => _EmbeddedWebViewState();
}

class _EmbeddedWebViewState extends State<EmbeddedWebView> {
  // 保留 controller 引用，以便未来扩展功能（如刷新、导航等）
  // ignore: unused_field
  InAppWebViewController? _controller;
  double _loadingProgress = 0;

  /// 创建 Memento UserScript（在页面加载前注入）
  UserScript _createMementoUserScript() {
    const script = '''
    (function() {
      // 1. 注入基础命名空间
      if (typeof window.Memento !== 'undefined') return;

      window.Memento = {
        version: '1.0.0',
        plugins: {},
        system: {},
        storage: {},
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

      // 2. 注入插件代理
      window.Memento.plugins = new Proxy({}, {
        get: function(target, pluginId) {
          if (pluginId === 'ui' || typeof pluginId === 'symbol') {
            return target[pluginId];
          }

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

      // 3. 注入系统 API 代理
      var systemMethods = [
        'getCurrentTime',
        'getDeviceInfo',
        'getAppInfo',
        'formatDate',
        'getTimestamp',
        'getCustomDate'
      ];

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

      // 4. 注入 UI API 代理
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

      window.Memento.plugins.ui = uiApi;
      window.Memento.ui = uiApi;

      // 5. 注入 Storage API 代理
      var storageApi = {
        read: function(key) {
          return window.flutter_inappwebview.callHandler('Memento_storage_read', {
            key: key
          }).then(function(result) {
            console.log('[Memento Storage] Read key:', key, 'result:', result);
            if (typeof result === 'string') {
              try {
                var parsed = JSON.parse(result);
                if (parsed.error) {
                  console.error('[Memento Storage] Read error:', parsed.error);
                  throw new Error(parsed.error);
                }
                console.log('[Memento Storage] Parsed data:', parsed.data);
                return parsed.data;
              } catch(e) {
                if (e.message && !e.message.includes('JSON')) {
                  throw e;
                }
                return result;
              }
            }
            return result;
          });
        },
        write: function(key, value) {
          return window.flutter_inappwebview.callHandler('Memento_storage_write', {
            key: key,
            value: value
          }).then(function(result) {
            if (typeof result === 'string') {
              try {
                var parsed = JSON.parse(result);
                if (parsed.error) {
                  throw new Error(parsed.error);
                }
                return parsed.success;
              } catch(e) {
                if (e.message && !e.message.includes('JSON')) {
                  throw e;
                }
                return true;
              }
            }
            return result;
          });
        },
        delete: function(key) {
          return window.flutter_inappwebview.callHandler('Memento_storage_delete', {
            key: key
          }).then(function(result) {
            if (typeof result === 'string') {
              try {
                var parsed = JSON.parse(result);
                if (parsed.error) {
                  throw new Error(parsed.error);
                }
                return parsed.success;
              } catch(e) {
                if (e.message && !e.message.includes('JSON')) {
                  throw e;
                }
                return true;
              }
            }
            return result;
          });
        }
      };

      window.Memento.storage = storageApi;

      // 标记准备完成并触发回调
      window.Memento._ready = true;
      if (window.Memento._readyCallbacks) {
        window.Memento._readyCallbacks.forEach(function(cb) {
          try { cb(); } catch(e) { console.error('Memento ready callback error:', e); }
        });
        window.Memento._readyCallbacks = [];
      }

      console.log('[Memento] JS Bridge preloaded successfully');
    })();
    ''';

    return UserScript(
      source: script,
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      forMainFrameOnly: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final plugin = WebViewPlugin.instance;
    final webviewSettings = plugin.webviewSettings;

    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.url)),
      initialSettings: widget.initialSettings ??
          InAppWebViewSettings(
            javaScriptEnabled: webviewSettings.enableJavaScript,
            javaScriptCanOpenWindowsAutomatically:
                !webviewSettings.blockPopups,
            supportZoom: false,
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            allowFileAccessFromFileURLs: true,
            allowUniversalAccessFromFileURLs: true,
            useHybridComposition: true,
            transparentBackground: true,
          ),
      // 使用 UserScript 预加载 JS Bridge
      initialUserScripts: widget.enableJSBridge && webviewSettings.enableJSBridge
          ? UnmodifiableListView<UserScript>([
              _createMementoUserScript(),
            ])
          : null,
      onWebViewCreated: (controller) {
        _controller = controller;
        debugPrint('[EmbeddedWebView] WebView created for: ${widget.url}');
      },
      onProgressChanged: (controller, progress) {
        debugPrint('[EmbeddedWebView] Progress: $progress for: ${widget.url}');
        setState(() {
          _loadingProgress = progress / 100;
        });
        widget.onProgressChanged?.call(_loadingProgress);
        widget.onLoadingChanged?.call(progress < 100);
      },
      onLoadStop: (controller, url) {
        debugPrint('[EmbeddedWebView] Load stopped for: $url');
        widget.onLoadingChanged?.call(false);
        widget.onLoadStop?.call();
      },
      onLoadError: (controller, url, code, message) {
        debugPrint('[EmbeddedWebView] Load error: $code - $message for: $url');
        widget.onLoadingChanged?.call(false);
        widget.onLoadError?.call(code, message);
      },
      onLoadHttpError: (controller, url, statusCode, description) {
        debugPrint('[EmbeddedWebView] HTTP error: $statusCode - $description for: $url');
        widget.onLoadingChanged?.call(false);
        widget.onLoadError?.call(statusCode, description);
      },
      onTitleChanged: (controller, title) {
        widget.onTitleChanged?.call(title ?? '');
      },
      onUpdateVisitedHistory: (controller, url, androidIsReload) {
        widget.onUrlChanged?.call(url?.toString() ?? '');
      },
    );
  }
}
