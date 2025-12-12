import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/base_plugin.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/core/plugin_manager.dart';

import 'models/webview_card.dart';
import 'models/webview_settings.dart';
import 'services/tab_manager.dart';
import 'services/card_manager.dart';
import 'services/proxy_controller_service.dart';
import 'screens/webview_main_screen.dart';

/// WebView 插件
///
/// 支持：
/// - 多标签页浏览
/// - 网址卡片管理（在线/本地）
/// - Memento JS Bridge 集成
class WebViewPlugin extends BasePlugin with ChangeNotifier, JSBridgePlugin {
  static WebViewPlugin? _instance;

  static WebViewPlugin get instance {
    _instance ??= PluginManager.instance.getPlugin('webview') as WebViewPlugin?;
    if (_instance == null) {
      throw StateError('WebViewPlugin has not been initialized');
    }
    return _instance!;
  }

  // Services
  late final TabManager tabManager;
  late final CardManager cardManager;
  late final ProxyControllerService proxyController;
  late WebViewSettings webviewSettings;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  @override
  String get id => 'webview';

  @override
  Color get color => const Color(0xFF4285F4); // Google Blue

  @override
  IconData get icon => Icons.language;

  @override
  String? getPluginName(context) => 'webview_name'.tr;

  @override
  Future<void> initialize() async {
    // 初始化服务
    tabManager = TabManager(maxTabs: 10);
    cardManager = CardManager(storage);
    proxyController = ProxyControllerService();

    // 检查 proxy 支持
    await proxyController.checkSupport();

    // 加载设置
    await _loadSettings();

    // 应用 proxy 配置（如果支持）
    if (proxyController.isSupported) {
      await proxyController.applyProxySettings(webviewSettings.proxySettings);
    }

    // 初始化卡片服务
    await cardManager.initialize();

    // 恢复标签页状态
    if (webviewSettings.restoreTabsOnStartup) {
      await _restoreTabs();
    }

    _isInitialized = true;
    _instance = this;

    // 注册 JS API
    await registerJSAPI();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      final data = await storage.read('webview/settings.json');
      if (data != null) {
        webviewSettings = WebViewSettings.fromJson(data as Map<String, dynamic>);
      } else {
        webviewSettings = WebViewSettings();
      }
    } catch (e) {
      webviewSettings = WebViewSettings();
    }
  }

  /// 保存设置
  Future<void> saveWebviewSettings() async {
    await storage.write('webview/settings.json', webviewSettings.toJson());

    // 重新应用 proxy 配置
    if (proxyController.isSupported) {
      await proxyController.applyProxySettings(webviewSettings.proxySettings);
    }

    notifyListeners();
  }

  /// 恢复标签页
  Future<void> _restoreTabs() async {
    try {
      final data = await storage.read('webview/tabs.json');
      if (data != null && data is List) {
        await tabManager.restoreFromJson(data);
      }
    } catch (e) {
      debugPrint('恢复标签页失败: $e');
    }
  }

  /// 保存标签页状态
  Future<void> saveTabs() async {
    final tabsJson = tabManager.toJson();
    await storage.write('webview/tabs.json', tabsJson);
  }

  /// 获取本地文件存储路径
  String get localFilesPath => '${storage.getPluginStoragePath(id)}/local_files';

  /// 检查 URL 是否为本地文件
  bool isLocalFileUrl(String url) {
    return url.startsWith('file://') || url.contains(localFilesPath);
  }

  // ==================== 统计方法 ====================

  int getTotalCardsCount() => _isInitialized ? cardManager.count : 0;
  int getUrlCardsCount() => _isInitialized ? cardManager.urlCards.length : 0;
  int getLocalFileCardsCount() => _isInitialized ? cardManager.localFileCards.length : 0;
  int getActiveTabsCount() => _isInitialized ? tabManager.tabCount : 0;

  // ==================== UI 构建 ====================

  @override
  Widget buildMainView(BuildContext context) {
    return const WebViewMainScreen();
  }

  @override
  Widget? buildCardView(BuildContext context) {
    if (!_isInitialized) return null;

    final theme = Theme.of(context);
    final totalCards = getTotalCardsCount();
    final activeTabs = getActiveTabsCount();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                'webview_name'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text('webview_cards'.tr, style: theme.textTheme.bodyMedium),
                  Text(
                    '$totalCards',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text('webview_tabs'.tr, style: theme.textTheme.bodyMedium),
                  Text(
                    '$activeTabs',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== JS API ====================

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 卡片管理
      'getCards': _jsGetCards,
      'addCard': _jsAddCard,
      'deleteCard': _jsDeleteCard,
      'updateCard': _jsUpdateCard,
      'findCardById': _jsFindCardById,
      'findCardByUrl': _jsFindCardByUrl,

      // 标签页管理
      'getTabs': _jsGetTabs,
      'createTab': _jsCreateTab,
      'closeTab': _jsCloseTab,
      'switchTab': _jsSwitchTab,

      // 导航
      'navigate': _jsNavigate,
      'goBack': _jsGoBack,
      'goForward': _jsGoForward,
      'reload': _jsReload,
    };
  }

  Future<String> _jsGetCards(Map<String, dynamic> params) async {
    if (!_isInitialized) return jsonEncode({'error': '插件未初始化'});
    return jsonEncode(cardManager.cards.map((c) => c.toJson()).toList());
  }

  Future<String> _jsAddCard(Map<String, dynamic> params) async {
    if (!_isInitialized) return jsonEncode({'error': '插件未初始化'});

    final title = params['title'] as String?;
    final url = params['url'] as String?;
    final type = params['type'] as String? ?? 'url';

    if (title == null || url == null) {
      return jsonEncode({'error': '缺少必需参数: title, url'});
    }

    final card = await cardManager.addCard(
      title: title,
      url: url,
      type: type == 'localFile' ? CardType.localFile : CardType.url,
      description: params['description'] as String?,
      tags: (params['tags'] as List<dynamic>?)?.cast<String>(),
    );

    return jsonEncode(card.toJson());
  }

  Future<String> _jsDeleteCard(Map<String, dynamic> params) async {
    if (!_isInitialized) return jsonEncode({'error': '插件未初始化'});

    final cardId = params['cardId'] as String?;
    if (cardId == null) {
      return jsonEncode({'error': '缺少必需参数: cardId'});
    }

    await cardManager.deleteCard(cardId);
    return jsonEncode({'success': true});
  }

  Future<String> _jsUpdateCard(Map<String, dynamic> params) async {
    if (!_isInitialized) return jsonEncode({'error': '插件未初始化'});

    final cardId = params['cardId'] as String?;
    if (cardId == null) {
      return jsonEncode({'error': '缺少必需参数: cardId'});
    }

    final card = cardManager.getCardById(cardId);
    if (card == null) {
      return jsonEncode({'error': '卡片不存在'});
    }

    final updatedCard = card.copyWith(
      title: params['title'] as String?,
      url: params['url'] as String?,
      description: params['description'] as String?,
    );

    await cardManager.updateCard(updatedCard);
    return jsonEncode(updatedCard.toJson());
  }

  Future<String> _jsFindCardById(Map<String, dynamic> params) async {
    if (!_isInitialized) return jsonEncode(null);

    final id = params['id'] as String?;
    if (id == null) return jsonEncode(null);

    final card = cardManager.getCardById(id);
    return jsonEncode(card?.toJson());
  }

  Future<String> _jsFindCardByUrl(Map<String, dynamic> params) async {
    if (!_isInitialized) return jsonEncode(null);

    final url = params['url'] as String?;
    if (url == null) return jsonEncode(null);

    final card = cardManager.getCardByUrl(url);
    return jsonEncode(card?.toJson());
  }

  Future<String> _jsGetTabs(Map<String, dynamic> params) async {
    if (!_isInitialized) return jsonEncode({'error': '插件未初始化'});
    return jsonEncode(tabManager.tabs.map((t) => t.toJson()).toList());
  }

  Future<String> _jsCreateTab(Map<String, dynamic> params) async {
    if (!_isInitialized) return jsonEncode({'error': '插件未初始化'});

    final url = params['url'] as String?;
    if (url == null) {
      return jsonEncode({'error': '缺少必需参数: url'});
    }

    try {
      final tab = await tabManager.createTab(
        url: url,
        title: params['title'] as String?,
        setActive: params['setActive'] as bool? ?? true,
      );
      return jsonEncode(tab.toJson());
    } catch (e) {
      return jsonEncode({'error': e.toString()});
    }
  }

  Future<String> _jsCloseTab(Map<String, dynamic> params) async {
    if (!_isInitialized) return jsonEncode({'error': '插件未初始化'});

    final tabId = params['tabId'] as String?;
    if (tabId == null) {
      return jsonEncode({'error': '缺少必需参数: tabId'});
    }

    await tabManager.closeTab(tabId);
    return jsonEncode({'success': true});
  }

  Future<String> _jsSwitchTab(Map<String, dynamic> params) async {
    if (!_isInitialized) return jsonEncode({'error': '插件未初始化'});

    final tabId = params['tabId'] as String?;
    if (tabId == null) {
      return jsonEncode({'error': '缺少必需参数: tabId'});
    }

    await tabManager.switchToTab(tabId);
    return jsonEncode({'success': true});
  }

  Future<String> _jsNavigate(Map<String, dynamic> params) async {
    if (!_isInitialized) return jsonEncode({'error': '插件未初始化'});

    final url = params['url'] as String?;
    if (url == null) {
      return jsonEncode({'error': '缺少必需参数: url'});
    }

    final tabId = tabManager.activeTabId;
    if (tabId == null) {
      return jsonEncode({'error': '没有活动的标签页'});
    }

    await tabManager.navigateTo(tabId, url);
    return jsonEncode({'success': true});
  }

  Future<String> _jsGoBack(Map<String, dynamic> params) async {
    final tabId = tabManager.activeTabId;
    if (tabId != null) {
      final success = await tabManager.goBack(tabId);
      return jsonEncode({'success': success});
    }
    return jsonEncode({'success': false, 'error': '无法后退'});
  }

  Future<String> _jsGoForward(Map<String, dynamic> params) async {
    final tabId = tabManager.activeTabId;
    if (tabId != null) {
      final success = await tabManager.goForward(tabId);
      return jsonEncode({'success': success});
    }
    return jsonEncode({'success': false, 'error': '无法前进'});
  }

  Future<String> _jsReload(Map<String, dynamic> params) async {
    final tabId = tabManager.activeTabId;
    if (tabId != null) {
      await tabManager.reload(tabId);
      return jsonEncode({'success': true});
    }
    return jsonEncode({'success': false, 'error': '没有活动的标签页'});
  }
}
