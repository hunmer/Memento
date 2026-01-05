part of 'webview_plugin.dart';

// JS API 实现 - 私有方法
// defineJSAPI() 方法在主插件类中实现

Future<String> _jsGetCards(Map<String, dynamic> params) async {
  if (!WebViewPlugin.instance._isInitialized) return jsonEncode({'error': '插件未初始化'});
  return jsonEncode(WebViewPlugin.instance.cardManager.getAllCards().map((c) => c.toJson()).toList());
}

Future<String> _jsAddCard(Map<String, dynamic> params) async {
  final plugin = WebViewPlugin.instance;
  if (!plugin._isInitialized) return jsonEncode({'error': '插件未初始化'});

  final title = params['title'] as String?;
  final url = params['url'] as String?;
  final type = params['type'] as String? ?? 'url';

  if (title == null || url == null) {
    return jsonEncode({'error': '缺少必需参数: title, url'});
  }

  final card = await plugin.cardManager.addCard(
    title: title,
    url: url,
    type: type == 'localFile' ? CardType.localFile : CardType.url,
    description: params['description'] as String?,
    tags: (params['tags'] as List<dynamic>?)?.cast<String>(),
  );

  return jsonEncode(card.toJson());
}

Future<String> _jsDeleteCard(Map<String, dynamic> params) async {
  if (!WebViewPlugin.instance._isInitialized) return jsonEncode({'error': '插件未初始化'});

  final cardId = params['cardId'] as String?;
  if (cardId == null) {
    return jsonEncode({'error': '缺少必需参数: cardId'});
  }

  await WebViewPlugin.instance.cardManager.deleteCard(cardId);
  return jsonEncode({'success': true});
}

Future<String> _jsUpdateCard(Map<String, dynamic> params) async {
  if (!WebViewPlugin.instance._isInitialized) return jsonEncode({'error': '插件未初始化'});

  final cardId = params['cardId'] as String?;
  if (cardId == null) {
    return jsonEncode({'error': '缺少必需参数: cardId'});
  }

  final card = WebViewPlugin.instance.cardManager.getCardById(cardId);
  if (card == null) {
    return jsonEncode({'error': '卡片不存在'});
  }

  final updatedCard = card.copyWith(
    title: params['title'] as String?,
    url: params['url'] as String?,
    description: params['description'] as String?,
  );

  await WebViewPlugin.instance.cardManager.updateCard(updatedCard);
  return jsonEncode(updatedCard.toJson());
}

Future<String> _jsFindCardById(Map<String, dynamic> params) async {
  if (!WebViewPlugin.instance._isInitialized) return jsonEncode(null);

  final id = params['id'] as String?;
  if (id == null) return jsonEncode(null);

  final card = WebViewPlugin.instance.cardManager.getCardById(id);
  return jsonEncode(card?.toJson());
}

Future<String> _jsFindCardByUrl(Map<String, dynamic> params) async {
  if (!WebViewPlugin.instance._isInitialized) return jsonEncode(null);

  final url = params['url'] as String?;
  if (url == null) return jsonEncode(null);

  final card = WebViewPlugin.instance.cardManager.getCardByUrl(url);
  return jsonEncode(card?.toJson());
}

Future<String> _jsGetTabs(Map<String, dynamic> params) async {
  if (!WebViewPlugin.instance._isInitialized) return jsonEncode({'error': '插件未初始化'});
  return jsonEncode(WebViewPlugin.instance.tabManager.tabs.map((t) => t.toJson()).toList());
}

Future<String> _jsCreateTab(Map<String, dynamic> params) async {
  if (!WebViewPlugin.instance._isInitialized) return jsonEncode({'error': '插件未初始化'});

  final url = params['url'] as String?;
  if (url == null) {
    return jsonEncode({'error': '缺少必需参数: url'});
  }

  try {
    final tab = await WebViewPlugin.instance.tabManager.createTab(
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
  if (!WebViewPlugin.instance._isInitialized) return jsonEncode({'error': '插件未初始化'});

  final tabId = params['tabId'] as String?;
  if (tabId == null) {
    return jsonEncode({'error': '缺少必需参数: tabId'});
  }

  await WebViewPlugin.instance.tabManager.closeTab(tabId);
  return jsonEncode({'success': true});
}

Future<String> _jsSwitchTab(Map<String, dynamic> params) async {
  if (!WebViewPlugin.instance._isInitialized) return jsonEncode({'error': '插件未初始化'});

  final tabId = params['tabId'] as String?;
  if (tabId == null) {
    return jsonEncode({'error': '缺少必需参数: tabId'});
  }

  await WebViewPlugin.instance.tabManager.switchToTab(tabId);
  return jsonEncode({'success': true});
}

Future<String> _jsNavigate(Map<String, dynamic> params) async {
  if (!WebViewPlugin.instance._isInitialized) return jsonEncode({'error': '插件未初始化'});

  final url = params['url'] as String?;
  if (url == null) {
    return jsonEncode({'error': '缺少必需参数: url'});
  }

  final tabId = WebViewPlugin.instance.tabManager.activeTabId;
  if (tabId == null) {
    return jsonEncode({'error': '没有活动的标签页'});
  }

  await WebViewPlugin.instance.tabManager.navigateTo(tabId, url);
  return jsonEncode({'success': true});
}

Future<String> _jsGoBack(Map<String, dynamic> params) async {
  final tabId = WebViewPlugin.instance.tabManager.activeTabId;
  if (tabId != null) {
    final success = await WebViewPlugin.instance.tabManager.goBack(tabId);
    return jsonEncode({'success': success});
  }
  return jsonEncode({'success': false, 'error': '无法后退'});
}

Future<String> _jsGoForward(Map<String, dynamic> params) async {
  final tabId = WebViewPlugin.instance.tabManager.activeTabId;
  if (tabId != null) {
    final success = await WebViewPlugin.instance.tabManager.goForward(tabId);
    return jsonEncode({'success': success});
  }
  return jsonEncode({'success': false, 'error': '无法前进'});
}

Future<String> _jsReload(Map<String, dynamic> params) async {
  final tabId = WebViewPlugin.instance.tabManager.activeTabId;
  if (tabId != null) {
    await WebViewPlugin.instance.tabManager.reload(tabId);
    return jsonEncode({'success': true});
  }
  return jsonEncode({'success': false, 'error': '没有活动的标签页'});
}
