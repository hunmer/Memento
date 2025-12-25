import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:Memento/plugins/chat/models/tag.dart';
import 'package:Memento/plugins/chat/screens/tags/widgets/tag_card.dart';
import 'package:Memento/plugins/chat/screens/tags/tag_messages_screen.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';

/// 排序类型枚举
enum SortType {
  byMessageCount, // 按消息数量排序
  byLastUsed, // 按最后使用时间排序
}

/// 标签列表页面
/// 显示所有从消息中提取的标签，支持搜索和排序
class TagsScreen extends StatefulWidget {
  final ChatPlugin chatPlugin;

  const TagsScreen({super.key, required this.chatPlugin});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  List<MessageTag> _tags = [];
  String _searchQuery = '';
  SortType _sortType = SortType.byMessageCount; // 默认按消息数量排序
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  /// 加载标签数据
  Future<void> _loadTags() async {
    setState(() => _isLoading = true);
    try {
      // 清除缓存，确保获取最新的标签数据
      widget.chatPlugin.tagService.invalidateCache();
      final tags = await widget.chatPlugin.tagService.getAllTags();
      if (mounted) {
        setState(() {
          _tags = tags;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error loading tags: $e');
    }
  }

  /// 获取过滤和排序后的标签列表
  List<MessageTag> get _filteredTags {
    var filtered =
        _tags.where((tag) {
          return tag.name.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

    // 应用排序
    if (_sortType == SortType.byMessageCount) {
      filtered.sort((a, b) => b.messageCount.compareTo(a.messageCount));
    } else {
      filtered.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    }

    return filtered;
  }

  /// 打开标签消息列表页面
  void _openTagMessages(MessageTag tag) async {
    final messages = await widget.chatPlugin.tagService.getMessagesByTag(
      tag.name,
    );
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => TagMessagesScreen(
              tagName: tag.name,
              messages: messages,
              chatPlugin: widget.chatPlugin,
            ),
      ),
    );
  }

  /// 构建排序按钮
  Widget _buildSortButton() {
    return PopupMenuButton<SortType>(
      icon: const Icon(Icons.sort),
      onSelected: (SortType type) {
        setState(() => _sortType = type);
      },
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: SortType.byMessageCount,
              child: Row(
                children: [
                  Icon(
                    Icons.numbers,
                    color:
                        _sortType == SortType.byMessageCount
                            ? Theme.of(context).colorScheme.primary
                            : null,
                  ),
                  const SizedBox(width: 8),
                  Text('chat_sortByCount'.tr),
                ],
              ),
            ),
            PopupMenuItem(
              value: SortType.byLastUsed,
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color:
                        _sortType == SortType.byLastUsed
                            ? Theme.of(context).colorScheme.primary
                            : null,
                  ),
                  const SizedBox(width: 8),
                  Text('chat_sortByTime'.tr),
                ],
              ),
            ),
          ],
    );
  }

  /// 构建标签网格
  Widget _buildTagsGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredTags.length,
      itemBuilder: (context, index) {
        return TagCard(
          tag: _filteredTags[index],
          onTap: () => _openTagMessages(_filteredTags[index]),
        );
      },
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    final message =
        _searchQuery.isEmpty ? 'chat_noTagsFound'.tr : 'chat_noMatchingTags'.tr;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tag,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SuperCupertinoNavigationWrapper(
      title: Text('chat_tagsTab'.tr),
      largeTitle: 'chat_tagsTab'.tr,
      enableSearchBar: true,
      searchPlaceholder: 'chat_searchTags'.tr,
      onSearchChanged: (query) {
        setState(() => _searchQuery = query);
      },
      onSearchSubmitted: (query) {
        setState(() => _searchQuery = query);
      },

      actions: [
        // 排序按钮
        _buildSortButton(),
        // 刷新按钮
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadTags,
          tooltip: 'chat_refresh'.tr,
        ),
      ],
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredTags.isEmpty
              ? _buildEmptyState()
              : _buildTagsGrid(),
    );
  }
}
