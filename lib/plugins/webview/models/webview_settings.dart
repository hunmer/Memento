/// WebView 插件设置模型
class WebViewSettings {
  bool enableJavaScript;
  bool enableJSBridge;
  bool blockPopups;
  bool enableZoom;
  String userAgent;
  bool saveHistory;
  int maxTabs;
  bool restoreTabsOnStartup;
  String defaultSearchEngine;
  String homePage;
  bool blockDeepLinks;

  WebViewSettings({
    this.enableJavaScript = true,
    this.enableJSBridge = true,
    this.blockPopups = true,
    this.enableZoom = true,
    this.userAgent = '',
    this.saveHistory = true,
    this.maxTabs = 10,
    this.restoreTabsOnStartup = true,
    this.defaultSearchEngine = 'https://www.google.com/search?q=',
    this.homePage = 'about:blank',
    this.blockDeepLinks = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'enableJavaScript': enableJavaScript,
      'enableJSBridge': enableJSBridge,
      'blockPopups': blockPopups,
      'enableZoom': enableZoom,
      'userAgent': userAgent,
      'saveHistory': saveHistory,
      'maxTabs': maxTabs,
      'restoreTabsOnStartup': restoreTabsOnStartup,
      'defaultSearchEngine': defaultSearchEngine,
      'homePage': homePage,
    };
  }

  factory WebViewSettings.fromJson(Map<String, dynamic> json) {
    return WebViewSettings(
      enableJavaScript: json['enableJavaScript'] as bool? ?? true,
      enableJSBridge: json['enableJSBridge'] as bool? ?? true,
      blockPopups: json['blockPopups'] as bool? ?? true,
      enableZoom: json['enableZoom'] as bool? ?? true,
      userAgent: json['userAgent'] as String? ?? '',
      saveHistory: json['saveHistory'] as bool? ?? true,
      maxTabs: json['maxTabs'] as int? ?? 10,
      restoreTabsOnStartup: json['restoreTabsOnStartup'] as bool? ?? true,
      defaultSearchEngine:
          json['defaultSearchEngine'] as String? ?? 'https://www.google.com/search?q=',
      homePage: json['homePage'] as String? ?? 'about:blank',
    );
  }

  WebViewSettings copyWith({
    bool? enableJavaScript,
    bool? enableJSBridge,
    bool? blockPopups,
    bool? enableZoom,
    String? userAgent,
    bool? saveHistory,
    int? maxTabs,
    bool? restoreTabsOnStartup,
    String? defaultSearchEngine,
    String? homePage,
  }) {
    return WebViewSettings(
      enableJavaScript: enableJavaScript ?? this.enableJavaScript,
      enableJSBridge: enableJSBridge ?? this.enableJSBridge,
      blockPopups: blockPopups ?? this.blockPopups,
      enableZoom: enableZoom ?? this.enableZoom,
      userAgent: userAgent ?? this.userAgent,
      saveHistory: saveHistory ?? this.saveHistory,
      maxTabs: maxTabs ?? this.maxTabs,
      restoreTabsOnStartup: restoreTabsOnStartup ?? this.restoreTabsOnStartup,
      defaultSearchEngine: defaultSearchEngine ?? this.defaultSearchEngine,
      homePage: homePage ?? this.homePage,
    );
  }
}
