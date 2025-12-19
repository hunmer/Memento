import 'package:Memento/plugins/chat/models/message.dart';
import 'package:Memento/plugins/chat/models/tag.dart';
import 'package:Memento/plugins/chat/services/message_service.dart';

/// 标签服务
/// 负责从消息中提取标签、统计标签信息等功能
class TagService {
  final MessageService messageService;

  /// 标签缓存
  List<MessageTag>? _cachedTags;
  DateTime? _lastCacheTime;

  /// 缓存有效期（5分钟）
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  TagService({required this.messageService});

  /// 从消息内容中提取标签（排除markdown代码块）
  ///
  /// 标签规则:
  /// - 以 # 开头
  /// - 后跟中文、英文、数字、下划线
  /// - 排除 markdown 代码块中的内容
  List<String> extractTagsFromContent(String content) {
    // 1. 移除多行代码块 ```...```
    String cleanContent = content.replaceAll(RegExp(r'```[\s\S]*?```'), '');

    // 2. 移除行内代码 `...`
    cleanContent = cleanContent.replaceAll(RegExp(r'`[^`]*`'), '');

    // 3. 提取标签：#后跟中文、英文、数字、下划线
    final tagRegex = RegExp(r'#([a-zA-Z0-9\u4e00-\u9fa5_]+)');
    final matches = tagRegex.allMatches(cleanContent);

    // 4. 去重并返回
    return matches.map((m) => m.group(1)!).toSet().toList();
  }

  /// 获取所有标签及其消息计数
  ///
  /// 使用缓存策略提升性能
  Future<List<MessageTag>> getAllTags() async {
    // 检查缓存是否有效
    if (_cachedTags != null && _lastCacheTime != null) {
      final cacheAge = DateTime.now().difference(_lastCacheTime!);
      if (cacheAge < _cacheValidDuration) {
        return _cachedTags!;
      }
    }

    // 重新计算标签
    _cachedTags = await _computeTags();
    _lastCacheTime = DateTime.now();
    return _cachedTags!;
  }

  /// 计算所有标签
  Future<List<MessageTag>> _computeTags() async {
    final messages = await messageService.getAllMessages();
    final tagMap = <String, List<Message>>{};

    // 遍历消息提取标签（仅处理文本消息）
    for (final message in messages) {
      if (message.type == MessageType.sent ||
          message.type == MessageType.received) {
        final tags = extractTagsFromContent(message.content);
        for (final tag in tags) {
          tagMap.putIfAbsent(tag, () => []).add(message);
        }
      }
    }

    // 转换为MessageTag对象并返回
    return tagMap.entries.map((entry) {
      return MessageTag(
        name: entry.key,
        messageCount: entry.value.length,
        lastUsed: entry.value
            .map((m) => m.date)
            .reduce((a, b) => a.isAfter(b) ? a : b),
      );
    }).toList();
  }

  /// 根据标签名获取关联的消息列表
  ///
  /// [tagName] 标签名称（不含 # 前缀）
  /// 返回包含该标签的所有消息，按时间降序排列
  Future<List<Message>> getMessagesByTag(String tagName) async {
    final messages = await messageService.getAllMessages();
    final matchedMessages = <Message>[];

    // 筛选包含该标签的消息
    for (final message in messages) {
      if (message.type == MessageType.sent ||
          message.type == MessageType.received) {
        final tags = extractTagsFromContent(message.content);
        if (tags.contains(tagName)) {
          matchedMessages.add(message);
        }
      }
    }

    // 按时间降序排序（最新消息在前）
    matchedMessages.sort((a, b) => b.date.compareTo(a.date));

    return matchedMessages;
  }

  /// 搜索标签（用于自动补全）
  ///
  /// [query] 搜索关键词
  /// 返回匹配的标签名列表
  Future<List<String>> searchTags(String query) async {
    if (query.isEmpty) return [];

    final allTags = await getAllTags();
    final lowercaseQuery = query.toLowerCase();

    return allTags
        .where((tag) => tag.name.toLowerCase().contains(lowercaseQuery))
        .map((tag) => tag.name)
        .toList();
  }

  /// 清除缓存
  ///
  /// 当消息更新时应调用此方法
  void invalidateCache() {
    _cachedTags = null;
    _lastCacheTime = null;
  }

  /// 获取标签总数
  Future<int> getTagCount() async {
    final tags = await getAllTags();
    return tags.length;
  }

  /// 获取使用最频繁的标签
  ///
  /// [limit] 返回数量限制
  Future<List<MessageTag>> getMostUsedTags({int limit = 10}) async {
    final tags = await getAllTags();

    // 按消息数量降序排序
    tags.sort((a, b) => b.messageCount.compareTo(a.messageCount));

    // 返回前N个
    return tags.take(limit).toList();
  }

  /// 获取最近使用的标签
  ///
  /// [limit] 返回数量限制
  Future<List<MessageTag>> getRecentlyUsedTags({int limit = 10}) async {
    final tags = await getAllTags();

    // 按最后使用时间降序排序
    tags.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));

    // 返回前N个
    return tags.take(limit).toList();
  }
}
