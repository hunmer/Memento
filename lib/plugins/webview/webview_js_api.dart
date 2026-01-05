part of 'webview_plugin.dart';

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
