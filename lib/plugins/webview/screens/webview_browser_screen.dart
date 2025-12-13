import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../webview_plugin.dart';
import '../models/webview_tab.dart';
import '../models/webview_card.dart';
import '../services/tab_manager.dart';
import '../services/js_bridge_injector.dart';
import 'tab_manager_screen.dart';

/// WebView 浏览器界面
class WebViewBrowserScreen extends StatefulWidget {
  final String? initialUrl;
  final String? initialTitle;
  final String? cardId;

  const WebViewBrowserScreen({
    super.key,
    this.initialUrl,
    this.initialTitle,
    this.cardId,
  });

  @override
  State<WebViewBrowserScreen> createState() => _WebViewBrowserScreenState();
}

class _WebViewBrowserScreenState extends State<WebViewBrowserScreen> {
  final TextEditingController _urlController = TextEditingController();

  WebViewTab? _currentTab;
  bool _isUrlBarFocused = false;

  @override
  void initState() {
    super.initState();
    _initializeTab();
  }

  Future<void> _initializeTab() async {
    final plugin = WebViewPlugin.instance;

    // 如果有初始 URL，创建新标签页
    if (widget.initialUrl != null) {
      // 自动转换 file:// URL（Windows 平台）
      final convertedUrl = plugin.convertUrlIfNeeded(widget.initialUrl!);

      final tab = await plugin.tabManager.createTab(
        url: convertedUrl,
        title: widget.initialTitle ?? '新标签页',
        setActive: true,
        cardId: widget.cardId,
      );
      setState(() {
        _currentTab = tab;
        _urlController.text = tab.url;
      });
    } else if (plugin.tabManager.activeTab != null) {
      // 使用现有的活动标签页
      setState(() {
        _currentTab = plugin.tabManager.activeTab;
        _urlController.text = _currentTab?.url ?? '';
      });
    } else {
      // 创建空白标签页
      final tab = await plugin.tabManager.createTab(
        url: 'about:blank',
        title: '新标签页',
        setActive: true,
      );
      setState(() {
        _currentTab = tab;
        _urlController.text = '';
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    // 保存标签页状态
    WebViewPlugin.instance.saveTabs();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plugin = WebViewPlugin.instance;

    return ChangeNotifierProvider.value(
      value: plugin.tabManager,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // 顶部地址栏和导航
              _buildAddressBar(context),

              // WebView 内容区域
              Expanded(
                child: Consumer<TabManager>(
                  builder: (context, tabManager, child) {
                    if (tabManager.tabs.isEmpty) {
                      return Center(child: Text('webview_no_tabs'.tr));
                    }

                    // 使用 IndexedStack 保持标签页状态
                    return IndexedStack(
                      index:
                          tabManager.activeTab != null
                              ? tabManager.getTabIndex(tabManager.activeTabId!)
                              : 0,
                      children:
                          tabManager.tabs.map((tab) {
                            return _WebViewTabContent(
                              key: ValueKey(tab.id),
                              tab: tab,
                              onUrlChanged: (url) {
                                if (tab.id == tabManager.activeTabId) {
                                  _urlController.text = url;
                                }
                              },
                              onTitleChanged: (title) {
                                tabManager.updateTab(tab.id, title: title);
                              },
                              onProgressChanged: (progress) {
                                tabManager.updateTab(
                                  tab.id,
                                  progress: progress,
                                );
                              },
                              onLoadingChanged: (isLoading) {
                                tabManager.updateTab(
                                  tab.id,
                                  isLoading: isLoading,
                                );
                              },
                              onNavigationStateChanged: (
                                canGoBack,
                                canGoForward,
                              ) {
                                tabManager.updateTab(
                                  tab.id,
                                  canGoBack: canGoBack,
                                  canGoForward: canGoForward,
                                );
                              },
                            );
                          }).toList(),
                    );
                  },
                ),
              ),

              // 底部工具栏
              _buildBottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 返回按钮
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
                tooltip: '关闭',
              ),

              // 地址栏
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: 'webview_enter_url'.tr,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      prefixIcon: Consumer<TabManager>(
                        builder: (context, tm, _) {
                          final tab = tm.activeTab;
                          if (tab?.isLoading ?? false) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }
                          return const Icon(Icons.lock_outline, size: 18);
                        },
                      ),
                      suffixIcon:
                          _isUrlBarFocused
                              ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _urlController.clear();
                                },
                              )
                              : null,
                    ),
                    onTap: () {
                      setState(() {
                        _isUrlBarFocused = true;
                      });
                      _urlController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _urlController.text.length,
                      );
                    },
                    onSubmitted: (value) {
                      setState(() {
                        _isUrlBarFocused = false;
                      });
                      _navigateToUrl(value);
                    },
                    onEditingComplete: () {
                      setState(() {
                        _isUrlBarFocused = false;
                      });
                    },
                  ),
                ),
              ),

              // 刷新/停止按钮
              Consumer<TabManager>(
                builder: (context, tm, _) {
                  final tab = tm.activeTab;
                  return IconButton(
                    icon: Icon(
                      tab?.isLoading ?? false ? Icons.close : Icons.refresh,
                    ),
                    onPressed: () {
                      if (tab?.isLoading ?? false) {
                        tm.getController(tab!.id)?.stopLoading();
                      } else if (tab != null) {
                        tm.reload(tab.id);
                      }
                    },
                    tooltip:
                        tab?.isLoading ?? false
                            ? 'webview_stop'.tr
                            : 'webview_reload'.tr,
                  );
                },
              ),
            ],
          ),

          // 加载进度条
          Consumer<TabManager>(
            builder: (context, tm, _) {
              final tab = tm.activeTab;
              if (tab?.isLoading ?? false) {
                return LinearProgressIndicator(
                  value: tab!.progress,
                  minHeight: 2,
                );
              }
              return const SizedBox(height: 2);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Consumer<TabManager>(
        builder: (context, tabManager, _) {
          final tab = tabManager.activeTab;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 后退
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed:
                    tab?.canGoBack ?? false
                        ? () => tabManager.goBack(tab!.id)
                        : null,
                tooltip: 'webview_go_back'.tr,
              ),

              // 前进
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed:
                    tab?.canGoForward ?? false
                        ? () => tabManager.goForward(tab!.id)
                        : null,
                tooltip: 'webview_go_forward'.tr,
              ),

              // 添加到卡片
              IconButton(
                icon: const Icon(Icons.add_box_outlined),
                onPressed: tab != null ? () => _addToCards(tab) : null,
                tooltip: 'webview_add_to_cards'.tr,
              ),

              // 标签页管理
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.layers),
                    onPressed: () => _showTabManager(),
                    tooltip: 'webview_tab_manager'.tr,
                  ),
                  if (tabManager.tabCount > 1)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${tabManager.tabCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // 更多选项
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => _handleMenuAction(value, tab),
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        value: 'new_tab',
                        child: ListTile(
                          leading: const Icon(Icons.add),
                          title: Text('webview_new_tab'.tr),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'share',
                        child: ListTile(
                          leading: const Icon(Icons.share),
                          title: Text('webview_share'.tr),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'copy_url',
                        child: ListTile(
                          leading: const Icon(Icons.copy),
                          title: Text('webview_copy_url'.tr),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'open_in_browser',
                        child: ListTile(
                          leading: const Icon(Icons.open_in_browser),
                          title: Text('webview_open_in_browser'.tr),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'close_tab',
                        child: ListTile(
                          leading: const Icon(Icons.close),
                          title: Text('webview_close_tab'.tr),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'close_all',
                        child: ListTile(
                          leading: const Icon(
                            Icons.close_fullscreen,
                            color: Colors.red,
                          ),
                          title: Text(
                            'webview_close_all_tabs'.tr,
                            style: const TextStyle(color: Colors.red),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _navigateToUrl(String input) {
    String url = input.trim();

    // 处理搜索或 URL
    if (!url.contains('.') && !url.startsWith('http')) {
      // 使用搜索引擎
      final searchEngine =
          WebViewPlugin.instance.webviewSettings.defaultSearchEngine;
      url = '$searchEngine${Uri.encodeComponent(url)}';
    } else if (!url.startsWith('http')) {
      url = 'https://$url';
    }

    final tabId = WebViewPlugin.instance.tabManager.activeTabId;
    if (tabId != null) {
      WebViewPlugin.instance.tabManager.navigateTo(tabId, url);
      WebViewPlugin.instance.tabManager.updateTab(tabId, url: url);
    }
  }

  void _addToCards(WebViewTab tab) async {
    final exists = WebViewPlugin.instance.cardManager.getCardByUrl(tab.url);
    if (exists != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('该网址已在卡片中')));
      return;
    }

    await WebViewPlugin.instance.cardManager.addCard(
      title: tab.title.isNotEmpty ? tab.title : tab.url,
      url: tab.url,
      type: CardType.url,
      iconUrl: tab.favicon,
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('webview_card_added'.tr)));
    }
  }

  void _showTabManager() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TabManagerScreen()),
    ).then((_) {
      // 返回时更新 URL 栏
      final tab = WebViewPlugin.instance.tabManager.activeTab;
      if (tab != null) {
        _urlController.text = tab.url;
      }
    });
  }

  void _handleMenuAction(String action, WebViewTab? tab) async {
    final plugin = WebViewPlugin.instance;

    switch (action) {
      case 'new_tab':
        await plugin.tabManager.createTab(
          url: 'about:blank',
          title: '新标签页',
          setActive: true,
        );
        _urlController.clear();
        break;

      case 'share':
        if (tab != null) {
          // TODO: 实现分享功能
        }
        break;

      case 'copy_url':
        if (tab != null) {
          Clipboard.setData(ClipboardData(text: tab.url));
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('webview_url_copied'.tr)));
        }
        break;

      case 'open_in_browser':
        if (tab != null) {
          final uri = Uri.tryParse(tab.url);
          if (uri != null) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
        break;

      case 'close_tab':
        if (tab != null) {
          await plugin.tabManager.closeTab(tab.id);
          if (plugin.tabManager.tabs.isEmpty) {
            Navigator.pop(context);
          } else {
            final newTab = plugin.tabManager.activeTab;
            if (newTab != null) {
              _urlController.text = newTab.url;
            }
          }
        }
        break;

      case 'close_all':
        final confirm = await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: Text('webview_close_all_tabs'.tr),
                content: Text('webview_confirm_close_all'.tr),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(
                      MaterialLocalizations.of(context).cancelButtonLabel,
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(
                      MaterialLocalizations.of(context).okButtonLabel,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
        );

        if (confirm == true) {
          await plugin.tabManager.closeAllTabs();
          if (mounted) Navigator.pop(context);
        }
        break;
    }
  }
}

/// WebView 标签页内容组件
class _WebViewTabContent extends StatefulWidget {
  final WebViewTab tab;
  final ValueChanged<String> onUrlChanged;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<double> onProgressChanged;
  final ValueChanged<bool> onLoadingChanged;
  final void Function(bool canGoBack, bool canGoForward)
  onNavigationStateChanged;

  const _WebViewTabContent({
    super.key,
    required this.tab,
    required this.onUrlChanged,
    required this.onTitleChanged,
    required this.onProgressChanged,
    required this.onLoadingChanged,
    required this.onNavigationStateChanged,
  });

  @override
  State<_WebViewTabContent> createState() => _WebViewTabContentState();
}

class _WebViewTabContentState extends State<_WebViewTabContent> {
  JSBridgeInjector? _jsBridgeInjector;
  bool _initialLoadCompleted = false; // 标记初始加载是否完成
  String? _lastProcessedUrl; // 记录最后一次处理的 URL，避免重复处理
  final Set<String> _redirectChain = {}; // 记录重定向链，检测循环重定向

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
      initialUrlRequest: URLRequest(url: WebUri(widget.tab.url)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: webviewSettings.enableJavaScript,
        javaScriptCanOpenWindowsAutomatically: !webviewSettings.blockPopups,
        supportZoom: webviewSettings.enableZoom,
        userAgent:
            webviewSettings.userAgent.isNotEmpty
                ? webviewSettings.userAgent
                : null,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        // 允许本地文件访问（用于 file:// URL）
        allowFileAccessFromFileURLs: true,
        allowUniversalAccessFromFileURLs: true,
        useHybridComposition: true, // 启用混合组成，提高性能
      ),
      // 使用 UserScript 预加载 JS Bridge
      initialUserScripts: webviewSettings.enableJSBridge
          ? UnmodifiableListView<UserScript>([
              _createMementoUserScript(),
            ])
          : null,
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final url = navigationAction.request.url?.toString() ?? '';

        // 允许 about:blank
        if (url == 'about:blank') {
          _lastProcessedUrl = url;
          _redirectChain.clear();
          return NavigationActionPolicy.ALLOW;
        }

        // 允许初始加载（尚未完成首次加载）
        if (!_initialLoadCompleted) {
          _lastProcessedUrl = url;
          _redirectChain.clear();
          return NavigationActionPolicy.ALLOW;
        }

        // 允许初始加载（tab.url 为空或为 about:blank）
        if (widget.tab.url.isEmpty || widget.tab.url == 'about:blank') {
          _lastProcessedUrl = url;
          _redirectChain.clear();
          return NavigationActionPolicy.ALLOW;
        }

        // 规范化 URL：去除尾部斜杠（除了根路径）
        String normalizeUrl(String u) {
          if (u.length > 1 && u.endsWith('/')) {
            return u.substring(0, u.length - 1);
          }
          return u;
        }

        final normalizedUrl = normalizeUrl(url);

        // 防止无限循环重定向：检测是否在相同的规范化 URL 之间反复跳转
        if (_redirectChain.contains(normalizedUrl)) {
          debugPrint('[WebView] 检测到循环重定向，已阻止: $url');
          return NavigationActionPolicy.CANCEL;
        }

        // 添加到重定向链
        _redirectChain.add(normalizedUrl);

        // 限制重定向链长度（防止内存泄漏）
        if (_redirectChain.length > 10) {
          // 保留最近的 5 个 URL
          final urls = _redirectChain.toList();
          _redirectChain.clear();
          _redirectChain.addAll(urls.sublist(5));
        }

        // 对于百度等网站，特殊处理：如果检测到 HTTP/HTTPS 反复切换，直接允许第一次，然后阻止后续
        final lastUrl = _lastProcessedUrl;
        if (lastUrl != null) {
          final normalizedLastUrl = normalizeUrl(lastUrl);

          // 如果只是协议不同（HTTP <-> HTTPS），但域名相同
          final isProtocolSwitch =
              (normalizedUrl.startsWith('http://') &&
                  normalizedLastUrl.startsWith('https://')) ||
              (normalizedUrl.startsWith('https://') &&
                  normalizedLastUrl.startsWith('http://'));

          if (isProtocolSwitch) {
            // 提取域名部分进行比较
            Uri? currentUri;
            Uri? lastUri;
            try {
              currentUri = Uri.parse(normalizedUrl);
              lastUri = Uri.parse(normalizedLastUrl);
            } catch (_) {
              // 解析失败，继续正常流程
            }

            if (currentUri != null &&
                lastUri != null &&
                currentUri.host == lastUri.host) {
              // 如果已经在重定向链中，说明是循环，阻止
              if (_redirectChain.contains(normalizedUrl)) {
                debugPrint(
                    '[WebView] 检测到协议切换循环，阻止: $url (上次: $lastUrl)');
                return NavigationActionPolicy.CANCEL;
              }
            }
          }
        }

        // 记录 URL 并允许导航
        _lastProcessedUrl = url;
        return NavigationActionPolicy.ALLOW;
      },
      onWebViewCreated: (controller) {
        plugin.tabManager.setController(widget.tab.id, controller);

        // 初始化 JS Bridge
        if (webviewSettings.enableJSBridge) {
          _jsBridgeInjector = JSBridgeInjector(
            controller: controller,
            enabled: true,
          );
          _jsBridgeInjector!.setContext(context);
          _jsBridgeInjector!.initialize();
        }
      },
      onLoadStart: (controller, url) async {
        widget.onLoadingChanged(true);
        if (url != null) {
          // 在开始新导航时，重置最后处理的 URL（但不重置为 null，避免误判）
          widget.onUrlChanged(url.toString());
        }
      },
      onLoadStop: (controller, url) async {
        widget.onLoadingChanged(false);

        // 标记初始加载已完成
        if (!_initialLoadCompleted) {
          _initialLoadCompleted = true;
        }

        // 页面加载完成后清理重定向链（为下次导航做准备）
        _redirectChain.clear();

        // 更新导航状态
        final canGoBack = await controller.canGoBack();
        final canGoForward = await controller.canGoForward();
        widget.onNavigationStateChanged(canGoBack, canGoForward);

        // 注意：JS Bridge 已通过 UserScript 预加载，无需重复注入
        // Handler 已在 onWebViewCreated 中注册

        // 调试：检查页面 DOM 状态和运行时错误
        try {
          final domCheck = await controller.evaluateJavascript(source: '''
            (function() {
              const bodyHTML = document.body ? document.body.innerHTML : 'NO BODY';
              const rootElement = document.getElementById('root') || document.getElementById('app');
              const rootHTML = rootElement ? rootElement.innerHTML : 'NO ROOT';
              const hasChildren = document.body ? document.body.children.length : 0;

              // 检查是否有全局错误
              const errors = window.__webviewErrors || [];

              // 尝试获取 React/Vue 的错误状态
              let frameworkError = null;
              try {
                // 检查常见的全局状态
                if (window.Vue && window.Vue.config && window.Vue.config.errorHandler) {
                  frameworkError = 'Vue detected';
                }
                if (window.React) {
                  frameworkError = 'React detected';
                }
              } catch (e) {
                frameworkError = 'Error checking framework: ' + e.message;
              }

              // 检查是否有加载指示器
              const hasLoadingIndicator = document.querySelector('.loading, [class*="loading"], [class*="spinner"]') !== null;

              return JSON.stringify({
                bodyEmpty: !document.body || document.body.innerHTML.trim() === '',
                hasRoot: !!rootElement,
                rootEmpty: !rootElement || rootElement.innerHTML.trim() === '',
                childCount: hasChildren,
                bodyPreview: bodyHTML.substring(0, 300),
                rootPreview: rootHTML.substring(0, 300),
                documentReady: document.readyState,
                mementoReady: typeof window.Memento !== 'undefined',
                hasLoadingIndicator: hasLoadingIndicator,
                globalErrors: errors.length,
                frameworkError: frameworkError
              });
            })();
          ''');
          debugPrint('[WebView DOM Check] $domCheck');

          // 注入全局错误捕获器
          await controller.evaluateJavascript(source: '''
            (function() {
              if (!window.__webviewErrors) {
                window.__webviewErrors = [];

                // 捕获未捕获的 Promise 错误
                window.addEventListener('unhandledrejection', function(event) {
                  const error = {
                    type: 'unhandledrejection',
                    message: event.reason ? event.reason.message || event.reason : 'Unknown error',
                    stack: event.reason ? event.reason.stack : null
                  };
                  window.__webviewErrors.push(error);
                  console.error('[Unhandled Promise Rejection]', error.message);
                });

                // 捕获全局错误
                window.addEventListener('error', function(event) {
                  const error = {
                    type: 'error',
                    message: event.message,
                    filename: event.filename,
                    lineno: event.lineno,
                    colno: event.colno
                  };
                  window.__webviewErrors.push(error);
                  console.error('[Global Error]', error.message, 'at', error.filename + ':' + error.lineno);
                });

                console.log('[Memento] Global error handlers installed');
              }
            })();
          ''');

          // 延迟 3 秒后再次检查页面状态（用于诊断是否卡在加载状态）
          Future.delayed(const Duration(seconds: 3), () async {
            try {
              final laterCheck = await controller.evaluateJavascript(source: '''
                (function() {
                  const rootElement = document.getElementById('root') || document.getElementById('app');
                  const hasLoadingIndicator = document.querySelector('.loading, [class*="loading"], [class*="spinner"]') !== null;
                  const errors = window.__webviewErrors || [];

                  return JSON.stringify({
                    stillLoading: hasLoadingIndicator,
                    errorCount: errors.length,
                    errors: errors,
                    bodyHTML: document.body ? document.body.innerHTML.substring(0, 500) : 'NO BODY'
                  });
                })();
              ''');
              debugPrint('[WebView Status After 3s] $laterCheck');
            } catch (e) {
              debugPrint('[WebView Status After 3s] Error: $e');
            }
          });
        } catch (e) {
          debugPrint('[WebView DOM Check] Error: $e');
        }
      },
      onProgressChanged: (controller, progress) {
        widget.onProgressChanged(progress / 100);
      },
      onTitleChanged: (controller, title) {
        if (title != null && title.isNotEmpty) {
          widget.onTitleChanged(title);
        }
      },
      onUpdateVisitedHistory: (controller, url, androidIsReload) async {
        if (url != null) {
          widget.onUrlChanged(url.toString());

          // 更新导航状态
          final canGoBack = await controller.canGoBack();
          final canGoForward = await controller.canGoForward();
          widget.onNavigationStateChanged(canGoBack, canGoForward);
        }
      },
      onConsoleMessage: (controller, consoleMessage) {
        // 增强日志：包含消息级别
        final levelStr = consoleMessage.messageLevel.toString().split('.').last;
        debugPrint('[WebView Console][$levelStr] ${consoleMessage.message}');
      },
      onReceivedError: (controller, request, error) async {
        // 忽略 about:blank 的错误
        if (request.url.toString() == 'about:blank') {
          return;
        }

        // 忽略连接停止错误（type 9），这通常是用户主动停止或页面跳转
        // WebResourceErrorType 在不同平台上的值可能不同，直接比较数值
        if (error.type.toNativeValue() == 9) {
          return;
        }

        // 记录其他错误以便调试
        debugPrint(
          '[WebView Error] URL: ${request.url}, '
          'Error Type: ${error.type} (${error.type.toNativeValue()}), '
          'Description: ${error.description}',
        );

        // 停止加载状态
        widget.onLoadingChanged(false);
      },
      onReceivedHttpError: (controller, request, errorResponse) async {
        // 记录 HTTP 错误（如 404, 500 等）
        debugPrint(
          '[WebView HTTP Error] URL: ${request.url}, '
          'Status: ${errorResponse.statusCode}, '
          'Reason: ${errorResponse.reasonPhrase}',
        );
      },
      onReceivedServerTrustAuthRequest: (controller, challenge) async {
        // 处理 SSL 证书信任请求
        // 在开发环境中，自动信任所有有效证书
        // 注意：在生产环境中应该进行更严格的证书验证

        // 简单的解决方案：信任所有 SSL 证书验证
        return ServerTrustAuthResponse(
          action: ServerTrustAuthResponseAction.PROCEED,
        );
      },
    );
  }
}
