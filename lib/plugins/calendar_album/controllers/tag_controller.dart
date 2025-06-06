import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/widgets/tag_manager_dialog/widgets/tag_manager_dialog.dart';
import 'package:flutter/material.dart';
import '../../../../widgets/tag_manager_dialog/models/tag_group.dart' as dialog;
import 'dart:convert';
import '../../../core/storage/storage_manager.dart';

class TagController extends ChangeNotifier {
  final VoidCallback? onTagsChanged;

  List<dialog.TagGroup> tagGroups = [];
  List<String> selectedTags = [];
  List<String> recentTags = [];

  static const String _tagGroupsKey = 'calendar_tag_groups';
  static const String _recentTagsKey = 'calendar_recent_tags';
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
      dialog.TagGroup(name: '最近使用', tags: []),
      dialog.TagGroup(name: '地点', tags: ['家', '工作', '旅行']),
      dialog.TagGroup(name: '活动', tags: ['生日', '聚会', '会议']),
    ];

    await _loadTagGroups();
  }

  Future<void> _loadTagGroups() async {
    try {
      // 尝试加载标签组
      final groupsJson = await storageManager.readFile(_tagGroupsFile, '[]');
      final List<dynamic> jsonData = json.decode(groupsJson);
      tagGroups =
          jsonData
              .map((e) => dialog.TagGroup.fromMap(e as Map<String, dynamic>))
              .toList();

      // 确保最近使用标签组存在
      if (!tagGroups.any((group) => group.name == '最近使用')) {
        tagGroups.insert(0, dialog.TagGroup(name: '最近使用', tags: []));
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
      tagGroups[recentGroupIndex] = dialog.TagGroup(
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
    final result = await showDialog<List<String>>(
      context: context,
      builder:
          (context) => TagManagerDialog(
            groups: List.from(tagGroups),
            selectedTags: List.from(selectedTags),
            onGroupsChanged: (updatedGroups) {
              setState(() {
                tagGroups = List.from(updatedGroups);
                _saveTagGroups();
                notifyListeners();
                onTagsChanged?.call();
              });
            },
          ),
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
              orElse: () => dialog.TagGroup(name: groupName, tags: []),
            )
            : tagGroups.firstWhere((g) => g.name == '最近使用');

    if (!group.tags.contains(tag)) {
      group.tags.add(tag);
      await _saveTagGroups();
      notifyListeners();
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
  }

  bool hasTag(String name) {
    return tagGroups.any((group) => group.tags.contains(name));
  }
}
