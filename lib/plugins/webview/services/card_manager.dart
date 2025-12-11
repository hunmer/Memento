import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/core/storage/storage_manager.dart';
import '../models/webview_card.dart';

/// 卡片/书签管理服务
class CardManager extends ChangeNotifier {
  final StorageManager _storage;
  static const String _storageKey = 'webview/cards.json';

  List<WebViewCard> _cards = [];

  CardManager(this._storage);

  // Getters
  List<WebViewCard> get cards => List.unmodifiable(_cards);
  List<WebViewCard> get pinnedCards => _cards.where((c) => c.isPinned).toList();
  List<WebViewCard> get urlCards => _cards.where((c) => c.type == CardType.url).toList();
  List<WebViewCard> get localFileCards => _cards.where((c) => c.type == CardType.localFile).toList();
  int get count => _cards.length;

  /// 初始化
  Future<void> initialize() async {
    await _loadCards();
  }

  /// 加载卡片数据
  Future<void> _loadCards() async {
    try {
      final data = await _storage.read(_storageKey);
      if (data != null && data is List) {
        _cards = data.map((item) => WebViewCard.fromJson(item as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('加载卡片数据失败: $e');
    }
  }

  /// 保存卡片数据
  Future<void> _saveCards() async {
    try {
      await _storage.write(_storageKey, _cards.map((c) => c.toJson()).toList());
    } catch (e) {
      debugPrint('保存卡片数据失败: $e');
    }
  }

  /// 添加卡片
  Future<WebViewCard> addCard({
    required String title,
    required String url,
    required CardType type,
    String? description,
    String? iconUrl,
    int? iconCodePoint,
    List<String>? tags,
  }) async {
    final card = WebViewCard(
      id: const Uuid().v4(),
      title: title,
      url: url,
      type: type,
      description: description,
      iconUrl: iconUrl,
      iconCodePoint: iconCodePoint,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: tags ?? [],
    );

    _cards.add(card);
    await _saveCards();
    notifyListeners();
    return card;
  }

  /// 更新卡片
  Future<void> updateCard(WebViewCard card) async {
    final index = _cards.indexWhere((c) => c.id == card.id);
    if (index == -1) return;

    _cards[index] = card.copyWith(updatedAt: DateTime.now());
    await _saveCards();
    notifyListeners();
  }

  /// 删除卡片
  Future<void> deleteCard(String cardId) async {
    _cards.removeWhere((c) => c.id == cardId);
    await _saveCards();
    notifyListeners();
  }

  /// 根据 ID 获取卡片
  WebViewCard? getCardById(String id) {
    try {
      return _cards.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 根据 URL 获取卡片
  WebViewCard? getCardByUrl(String url) {
    try {
      return _cards.firstWhere((c) => c.url == url);
    } catch (_) {
      return null;
    }
  }

  /// 切换固定状态
  Future<void> togglePinned(String cardId) async {
    final index = _cards.indexWhere((c) => c.id == cardId);
    if (index == -1) return;

    _cards[index] = _cards[index].copyWith(
      isPinned: !_cards[index].isPinned,
      updatedAt: DateTime.now(),
    );
    await _saveCards();
    notifyListeners();
  }

  /// 增加打开次数
  Future<void> incrementOpenCount(String cardId) async {
    final index = _cards.indexWhere((c) => c.id == cardId);
    if (index == -1) return;

    _cards[index] = _cards[index].copyWith(
      openCount: _cards[index].openCount + 1,
      updatedAt: DateTime.now(),
    );
    await _saveCards();
    notifyListeners();
  }

  /// 搜索卡片
  List<WebViewCard> searchCards(String query) {
    if (query.isEmpty) return _cards;
    final lowerQuery = query.toLowerCase();
    return _cards.where((card) {
      return card.title.toLowerCase().contains(lowerQuery) ||
          card.url.toLowerCase().contains(lowerQuery) ||
          (card.description?.toLowerCase().contains(lowerQuery) ?? false) ||
          card.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// 按标签筛选
  List<WebViewCard> filterByTag(String tag) {
    return _cards.where((card) => card.tags.contains(tag)).toList();
  }

  /// 获取所有标签
  List<String> getAllTags() {
    final tags = <String>{};
    for (var card in _cards) {
      tags.addAll(card.tags);
    }
    return tags.toList()..sort();
  }

  /// 按打开次数排序
  List<WebViewCard> getFrequentlyUsed({int limit = 10}) {
    final sorted = List<WebViewCard>.from(_cards);
    sorted.sort((a, b) => b.openCount.compareTo(a.openCount));
    return sorted.take(limit).toList();
  }

  /// 按更新时间排序
  List<WebViewCard> getRecentlyUpdated({int limit = 10}) {
    final sorted = List<WebViewCard>.from(_cards);
    sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.take(limit).toList();
  }

  /// 重新排序卡片
  Future<void> reorderCards(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final card = _cards.removeAt(oldIndex);
    _cards.insert(newIndex, card);
    await _saveCards();
    notifyListeners();
  }
}
