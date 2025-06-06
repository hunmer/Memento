import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/widgets/tag_manager_dialog/widgets/tag_manager_dialog.dart';
import 'package:flutter/material.dart';
import '../../../../widgets/tag_manager_dialog/models/tag_group.dart' as dialog;
import 'dart:convert';
import '../../../core/storage/storage_manager.dart';

class Tag {
  final String id;
  final String name;
  final Color color;

  Tag({required this.id, required this.name, Color? color})
    : color = color ?? Colors.grey;

  factory Tag.create({required String name, Color? color}) {
    return Tag(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      color: color,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'color': color.value};
  }

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'],
      name: json['name'],
      color: json.containsKey('color') ? Color(json['color']) : null,
    );
  }
}

extension TagGroupExtension on dialog.TagGroup {
  List<Tag> get tagObjects {
    return tags.map((name) => Tag.create(name: name)).toList();
  }
}

class TagController extends ChangeNotifier {
  final VoidCallback? onTagsChanged;

  List<dialog.TagGroup> tagGroups = [];
  List<Tag> selectedTags = [];
  List<Tag> recentTags = [];

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
      recentTags =
          recentData
              .map((e) => Tag.fromJson(e as Map<String, dynamic>))
              .toList();
      _updateRecentTagGroup();

      notifyListeners();
      onTagsChanged?.call();
    } catch (e, stack) {
      debugPrint('加载标签组失败: $e');
      debugPrint('Stack trace: $stack');
      // 回退到默认初始化
      initialize();
    }
  }

  Future<void> _saveTagGroups() async {
    try {
      final data = json.encode(
        tagGroups
            .map(
              (group) => {
                'name': group.name,
                'tags': group.tagObjects.map((tag) => tag.toJson()).toList(),
              },
            )
            .toList(),
      );
      await storageManager.writeFile(_tagGroupsFile, data);
    } catch (e) {
      debugPrint('保存标签组失败: $e');
    }
  }

  Future<void> _saveRecentTags() async {
    try {
      final data = json.encode(recentTags.map((tag) => tag.toJson()).toList());
      await storageManager.setString(_recentTagsKey, data);
    } catch (e) {
      debugPrint('保存最近标签失败: $e');
    }
  }

  void _updateRecentTagGroup() {
    final recentGroupIndex = tagGroups.indexWhere((g) => g.name == '最近使用');
    if (recentGroupIndex != -1) {
      tagGroups[recentGroupIndex] = dialog.TagGroup(
        name: '最近使用',
        tags: recentTags.map((tag) => tag.name).toList(),
      );
    }
  }

  Future<void> updateRecentTags(List<Tag> tags) async {
    if (tags.isEmpty) return;

    // 更新最近使用标签列表
    for (final tag in tags) {
      recentTags.removeWhere((t) => t.id == tag.id);
      recentTags.insert(0, tag);
    }

    // 限制最近使用标签数量
    if (recentTags.length > 10) {
      recentTags.removeRange(10, recentTags.length);
    }

    // 更新最近使用标签组
    _updateRecentTagGroup();

    // 保存最近使用的标签
    await _saveRecentTags();
    await _saveTagGroups();

    notifyListeners();
    onTagsChanged?.call();
  }

  Future<void> showTagManagerDialog(BuildContext context) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder:
          (context) => TagManagerDialog(
            groups: List.from(tagGroups),
            selectedTags: selectedTags.map((t) => t.name).toList(),
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
      setState(() {
        selectedTags = result.map((name) => Tag.create(name: name)).toList();
      });
      await updateRecentTags(selectedTags);
      notifyListeners();
      onTagsChanged?.call();
    }
  }

  void setState(void Function() fn) {
    fn();
    notifyListeners();
  }

  List<Tag> get tags {
    return tagGroups.expand((group) => group.tagObjects).toList();
  }

  Future<void> addTag(Tag tag, {String? groupName}) async {
    final group =
        groupName != null
            ? tagGroups.firstWhere(
              (g) => g.name == groupName,
              orElse: () => dialog.TagGroup(name: groupName, tags: []),
            )
            : tagGroups.firstWhere((g) => g.name == '最近使用');

    if (!group.tagObjects.any((t) => t.id == tag.id)) {
      group.tags.add(tag.name);
      await _saveTagGroups();
      notifyListeners();
    }
  }

  Future<void> deleteTag(String tagId) async {
    for (final group in tagGroups) {
      group.tags.removeWhere((tag) => tag == tagId);
    }
    recentTags.removeWhere((tag) => tag.id == tagId);
    await _saveTagGroups();
    await _saveRecentTags();
    notifyListeners();
  }

  Tag? getTagByName(String name) {
    try {
      for (final group in tagGroups) {
        final tag = group.tagObjects.firstWhere((tag) => tag.name == name);
        return tag;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
