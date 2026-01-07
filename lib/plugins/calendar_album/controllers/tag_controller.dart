import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/widgets/tags_dialog/tags_dialog.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/event/item_event_args.dart';

/// 简单的标签组数据结构（本地定义，保持向后兼容）
class TagGroup {
  final String name;
  final List<String> tags;

  TagGroup({required this.name, required this.tags});

  TagGroup copyWith({String? name, List<String>? tags}) {
    return TagGroup(
      name: name ?? this.name,
      tags: tags ?? List.from(this.tags),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'tags': tags};
  }

  factory TagGroup.fromJson(Map<String, dynamic> json) {
    return TagGroup(
      name: json['name'] as String,
      tags: List<String>.from(json['tags'] as List),
    );
  }
}

class TagController extends ChangeNotifier {
  // 发送事件通知
  void _notifyEvent(String action, String tagName) {
    final eventArgs = ItemEventArgs(
      eventName: 'calendar_tag_$action',
      itemId: tagName,
      title: tagName,
      action: action,
    );
    EventManager.instance.broadcast('calendar_tag_$action', eventArgs);
  }
  final VoidCallback? onTagsChanged;

  List<TagGroup> tagGroups = [];
  List<String> selectedTags = [];
  List<String> recentTags = [];

  final String _tagGroupsFile = 'data/calendar_tag_groups.json';
  final String _recentTagsFile = 'data/calendar_recent_tags.json';

  TagController({this.onTagsChanged}) {
    initialize();
  }

  StorageManager get storageManager {
    final storage = PluginManager.instance.storageManager;
    if (storage == null) {
      throw Exception('StorageManager is not initialized in PluginManager');
    }
    return storage;
  }

  Future<void> initialize() async {
    // 初始化默认标签组
    tagGroups = [
      TagGroup(name: '最近使用', tags: []),
      TagGroup(name: '地点', tags: ['家', '工作', '旅行']),
      TagGroup(name: '活动', tags: ['生日', '聚会', '会议']),
      TagGroup(name: '心情', tags: ['开心', '平静', '兴奋', '思考']),
    ];

    try {
      // 尝试加载标签组
      if (await storageManager.fileExists(_tagGroupsFile)) {
        final jsonStr = await storageManager.readFile(_tagGroupsFile, '');
        if (jsonStr.isNotEmpty) {
          final List<dynamic> data = json.decode(jsonStr);
          if (data.isNotEmpty) {
            tagGroups = data.map((e) => TagGroup.fromJson(e as Map<String, dynamic>)).toList();
          }
        }
      } else {
        // 如果文件为空，保存默认标签组
        await _saveTagGroups();
      }

      // 尝试加载最近使用的标签
      final recentJson = await storageManager.readFile(_recentTagsFile, '[]');
      final List<dynamic> recentData = json.decode(recentJson);
      recentTags = recentData.cast<String>().toList();
      _updateRecentTagGroup();

      notifyListeners();
      onTagsChanged?.call();
    } catch (e, stack) {
      debugPrint('加载标签组失败: $e');
      debugPrint('Stack trace: $stack');
      initialize();
    }
  }

  Future<void> _saveTagGroups() async {
    try {
      final data = json.encode(
        tagGroups
            .map((group) => {'name': group.name, 'tags': group.tags})
            .toList(),
      );
      await storageManager.writeFile(_tagGroupsFile, data);
    } catch (e) {
      debugPrint('保存标签组失败: $e');
    }
  }

  Future<void> _saveRecentTags() async {
    try {
      final data = json.encode(recentTags);
      await storageManager.writeFile(_recentTagsFile, data);
    } catch (e) {
      debugPrint('保存最近标签失败: $e');
    }
  }

  void _updateRecentTagGroup() {
    final recentGroupIndex = tagGroups.indexWhere((g) => g.name == '最近使用');
    if (recentGroupIndex != -1) {
      tagGroups[recentGroupIndex] = TagGroup(
        name: '最近使用',
        tags: List.from(recentTags),
      );
    }
  }

  Future<void> updateRecentTags(List<String> tags) async {
    if (tags.isEmpty) return;

    for (final tag in tags) {
      recentTags.remove(tag);
      recentTags.insert(0, tag);
    }

    if (recentTags.length > 10) {
      recentTags.removeRange(10, recentTags.length);
    }

    _updateRecentTagGroup();
    await _saveRecentTags();
    await _saveTagGroups();
    notifyListeners();
    onTagsChanged?.call();
  }

  Future<List<String>?> showTagManagerDialog(BuildContext context) async {
    // 转换为新组件可接受的格式
    final legacyGroups = tagGroups.map((g) => g.toJson()).toList();

    final result = await TagsDialog.show(
      context,
      groups: legacyGroups,
      selectedTags: List.from(selectedTags),
      config: const TagsDialogConfig(
        title: '标签管理',
        selectionMode: TagsSelectionMode.multiple,
        enableEditing: true,
        enableBatchEdit: true,
      ),
      onGroupsChanged: (newGroups) {
        // 新格式转回旧格式
        tagGroups = newGroups.map((g) => TagGroup(
          name: g.name,
          tags: g.tags.map((t) => t.name).toList(),
        )).toList();
        _saveTagGroups();
        notifyListeners();
        onTagsChanged?.call();
      },
    );

    if (result != null) {
      selectedTags = List.from(result);
      await updateRecentTags(selectedTags);
      notifyListeners();
      onTagsChanged?.call();
      return selectedTags;
    }
    return null;
  }

  void setState(void Function() fn) {
    fn();
    notifyListeners();
  }

  List<String> get tags {
    return tagGroups.expand((group) => group.tags).toList();
  }

  Future<void> addTag(String tag, {String? groupName}) async {
    final group =
        groupName != null
            ? tagGroups.firstWhere(
              (g) => g.name == groupName,
              orElse: () => TagGroup(name: groupName, tags: []),
            )
            : tagGroups.firstWhere((g) => g.name == '最近使用');

    if (!group.tags.contains(tag)) {
      group.tags.add(tag);
      await _saveTagGroups();
      notifyListeners();

      // 广播添加事件
      _notifyEvent('added', tag);
    }
  }

  Future<void> deleteTag(String tag) async {
    for (final group in tagGroups) {
      group.tags.remove(tag);
    }
    recentTags.remove(tag);
    await _saveTagGroups();
    await _saveRecentTags();
    notifyListeners();

    // 广播删除事件
    _notifyEvent('deleted', tag);
  }

  bool hasTag(String name) {
    return tagGroups.any((group) => group.tags.contains(name));
  }
}
