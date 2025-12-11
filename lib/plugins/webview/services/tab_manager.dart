import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:uuid/uuid.dart';
import '../models/webview_tab.dart';

/// 标签页管理服务
///
/// 职责：
/// - 管理多个 WebView 标签页
/// - 维护 InAppWebViewController 实例（保持状态不刷新）
/// - 标签页的创建、切换、关闭
class TabManager extends ChangeNotifier {
  final List<WebViewTab> _tabs = [];
  final Map<String, InAppWebViewController?> _controllers = {};
  String? _activeTabId;
  final int maxTabs;

  TabManager({this.maxTabs = 10});

  // Getters
  List<WebViewTab> get tabs => List.unmodifiable(_tabs);

  WebViewTab? get activeTab {
    if (_activeTabId == null) return null;
    try {
      return _tabs.firstWhere((t) => t.id == _activeTabId);
    } catch (_) {
      return null;
    }
  }

  String? get activeTabId => _activeTabId;
  int get tabCount => _tabs.length;
  bool get hasActiveTabs => _tabs.isNotEmpty;
  bool get canAddTab => _tabs.length < maxTabs;

  InAppWebViewController? get activeController {
    if (_activeTabId == null) return null;
    return _controllers[_activeTabId];
  }

  /// 创建新标签页
  Future<WebViewTab> createTab({
    required String url,
    String? title,
    bool setActive = true,
  }) async {
    if (_tabs.length >= maxTabs) {
      throw Exception('已达到最大标签页数量 ($maxTabs)');
    }

    final now = DateTime.now();
    final tab = WebViewTab(
      id: const Uuid().v4(),
      url: url,
      title: title ?? '新标签页',
      createdAt: now,
      lastAccessedAt: now,
      isActive: setActive,
    );

    _tabs.add(tab);
    _controllers[tab.id] = null; // 控制器将在 WebView 创建时设置

    if (setActive) {
      await switchToTab(tab.id);
    }

    notifyListeners();
    return tab;
  }

  /// 切换到指定标签页
  Future<void> switchToTab(String tabId) async {
    final tabIndex = _tabs.indexWhere((t) => t.id == tabId);
    if (tabIndex == -1) return;

    // 更新所有标签页的 isActive 状态
    for (var i = 0; i < _tabs.length; i++) {
      _tabs[i] = _tabs[i].copyWith(isActive: _tabs[i].id == tabId);
    }

    // 更新访问时间
    _tabs[tabIndex] = _tabs[tabIndex].copyWith(
      lastAccessedAt: DateTime.now(),
    );

    _activeTabId = tabId;
    notifyListeners();
  }

  /// 关闭标签页
  Future<void> closeTab(String tabId) async {
    final tabIndex = _tabs.indexWhere((t) => t.id == tabId);
    if (tabIndex == -1) return;

    final wasActive = _tabs[tabIndex].isActive;

    // 清理控制器
    _controllers.remove(tabId);

    // 移除标签页
    _tabs.removeAt(tabIndex);

    // 如果关闭的是活动标签页，切换到最近访问的标签页
    if (wasActive && _tabs.isNotEmpty) {
      final mostRecent = _tabs.reduce(
        (a, b) => a.lastAccessedAt.isAfter(b.lastAccessedAt) ? a : b,
      );
      await switchToTab(mostRecent.id);
    } else if (_tabs.isEmpty) {
      _activeTabId = null;
    }

    notifyListeners();
  }

  /// 关闭所有标签页
  Future<void> closeAllTabs() async {
    _controllers.clear();
    _tabs.clear();
    _activeTabId = null;
    notifyListeners();
  }

  /// 设置标签页的 WebView 控制器
  void setController(String tabId, InAppWebViewController controller) {
    _controllers[tabId] = controller;
  }

  /// 获取标签页的 WebView 控制器
  InAppWebViewController? getController(String tabId) {
    return _controllers[tabId];
  }

  /// 获取标签页索引
  int getTabIndex(String tabId) {
    return _tabs.indexWhere((t) => t.id == tabId);
  }

  /// 根据 ID 获取标签页
  WebViewTab? getTabById(String tabId) {
    try {
      return _tabs.firstWhere((t) => t.id == tabId);
    } catch (_) {
      return null;
    }
  }

  /// 更新标签页信息
  void updateTab(
    String tabId, {
    String? url,
    String? title,
    String? favicon,
    bool? canGoBack,
    bool? canGoForward,
    bool? isLoading,
    double? progress,
  }) {
    final index = _tabs.indexWhere((t) => t.id == tabId);
    if (index == -1) return;

    _tabs[index] = _tabs[index].copyWith(
      url: url,
      title: title,
      favicon: favicon,
      canGoBack: canGoBack,
      canGoForward: canGoForward,
      isLoading: isLoading,
      progress: progress,
    );
    notifyListeners();
  }

  /// 导航到新 URL（带防抖机制）
  Future<void> navigateTo(String tabId, String url) async {
    final tab = getTabById(tabId);
    final controller = _controllers[tabId];

    if (tab == null || controller == null) return;

    // 防抖：避免在短时间内重复导航到相同 URL
    final currentUrl = tab.url;
    final normalizedCurrent = _normalizeUrl(currentUrl);
    final normalizedNew = _normalizeUrl(url);

    // 如果是相同的 URL，跳过
    if (normalizedCurrent == normalizedNew) {
      return;
    }

    await controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  /// 规范化 URL（去除尾部斜杠等差异）
  String _normalizeUrl(String url) {
    // 去除尾部斜杠（除了根路径）
    if (url.length > 1 && url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }

  /// 后退
  Future<bool> goBack(String tabId) async {
    final tab = getTabById(tabId);
    final controller = _controllers[tabId];
    if (tab != null && controller != null && tab.canGoBack) {
      await controller.goBack();
      return true;
    }
    return false;
  }

  /// 前进
  Future<bool> goForward(String tabId) async {
    final tab = getTabById(tabId);
    final controller = _controllers[tabId];
    if (tab != null && controller != null && tab.canGoForward) {
      await controller.goForward();
      return true;
    }
    return false;
  }

  /// 刷新
  Future<void> reload(String tabId) async {
    final controller = _controllers[tabId];
    if (controller != null) {
      await controller.reload();
    }
  }

  /// 持久化标签页状态
  List<Map<String, dynamic>> toJson() {
    return _tabs.map((t) => t.toJson()).toList();
  }

  /// 从 JSON 恢复标签页状态
  Future<void> restoreFromJson(List<dynamic> json) async {
    _tabs.clear();
    _controllers.clear();

    for (var item in json) {
      final tab = WebViewTab.fromJson(item as Map<String, dynamic>);
      _tabs.add(tab);
      _controllers[tab.id] = null;
    }

    if (_tabs.isNotEmpty) {
      // 尝试恢复之前的活动标签页
      final previousActive = _tabs.where((t) => t.isActive).firstOrNull;
      if (previousActive != null) {
        _activeTabId = previousActive.id;
      } else {
        _activeTabId = _tabs.first.id;
        _tabs[0] = _tabs[0].copyWith(isActive: true);
      }
    }

    notifyListeners();
  }

  /// 重新排序标签页
  void reorderTabs(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final tab = _tabs.removeAt(oldIndex);
    _tabs.insert(newIndex, tab);
    notifyListeners();
  }
}
