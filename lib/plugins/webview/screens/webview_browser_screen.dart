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

  const WebViewBrowserScreen({super.key, this.initialUrl, this.initialTitle});

  @override
  State<WebViewBrowserScreen> createState() => _WebViewBrowserScreenState();
}

class _WebViewBrowserScreenState extends State<WebViewBrowserScreen> {
  final TextEditingController _urlController = TextEditingController();
  final List<GlobalKey<_WebViewTabContentState>> _tabKeys = [];

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
      final tab = await plugin.tabManager.createTab(
        url: widget.initialUrl!,
        title: widget.initialTitle ?? '新标签页',
        setActive: true,
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
    final plugin = WebViewPlugin.instance;
    final tabManager = plugin.tabManager;

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
    final plugin = WebViewPlugin.instance;

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
  InAppWebViewController? _controller;
  JSBridgeInjector? _jsBridgeInjector;

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
      ),
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final url = navigationAction.request.url?.toString() ?? '';
        final currentUrl = widget.tab.url;

        // 如果是 HTTP 重定向到 HTTPS，允许加载
        // 如果是 HTTPS 重定向到 HTTP，允许加载
        // 但防止同一页面的重复加载
        final isHttpToHttps =
            currentUrl.startsWith('http://') && url.startsWith('https://');
        final isHttpsToHttp =
            currentUrl.startsWith('https://') && url.startsWith('http://');

        if (isHttpToHttps || isHttpsToHttp) {
          return NavigationActionPolicy.ALLOW;
        }

        // 防止无限循环：检查 URL 是否已经加载过
        final normalizedCurrent = _normalizeUrl(currentUrl);
        final normalizedNew = _normalizeUrl(url);

        if (normalizedCurrent == normalizedNew) {
          return NavigationActionPolicy.CANCEL;
        }

        return NavigationActionPolicy.ALLOW;
      },
      onWebViewCreated: (controller) {
        _controller = controller;
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
          widget.onUrlChanged(url.toString());
        }
      },
      onLoadStop: (controller, url) async {
        widget.onLoadingChanged(false);

        // 更新导航状态
        final canGoBack = await controller.canGoBack() ?? false;
        final canGoForward = await controller.canGoForward() ?? false;
        widget.onNavigationStateChanged(canGoBack, canGoForward);

        // 注入 JS Bridge（传递当前 URL 防止重复注入）
        if (_jsBridgeInjector != null) {
          await _jsBridgeInjector!.inject();
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
          final canGoBack = await controller.canGoBack() ?? false;
          final canGoForward = await controller.canGoForward() ?? false;
          widget.onNavigationStateChanged(canGoBack, canGoForward);
        }
      },
      onConsoleMessage: (controller, consoleMessage) {
        debugPrint('[WebView Console] ${consoleMessage.message}');
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

  /// 规范化 URL（去除尾部斜杠等差异）
  String _normalizeUrl(String url) {
    // 去除尾部斜杠（除了根路径）
    if (url.length > 1 && url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }
}
