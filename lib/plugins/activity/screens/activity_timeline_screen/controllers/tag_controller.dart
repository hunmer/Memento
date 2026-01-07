import 'package:flutter/material.dart';
import 'package:Memento/plugins/activity/services/activity_service.dart';
import 'package:Memento/plugins/activity/models/tag_group.dart';
import 'package:Memento/widgets/tags_dialog/tags_dialog.dart';
import 'package:Memento/widgets/tags_dialog/models/tag_item.dart';

class TagController {
  final ActivityService activityService;
  final VoidCallback onTagsChanged;

  List<TagGroup> tagGroups = [];
  // 保留完整的标签数据（包含图标）
  List<TagGroupWithTags> tagGroupsWithTags = [];
  List<String> selectedTags = [];
  List<String> recentTags = [];

  TagController({required this.activityService, required this.onTagsChanged});

  Future<void> initialize() async {
    // 初始化标签组
    tagGroups = [
      TagGroup(name: '最近使用', tags: []),
      TagGroup(name: '工作', tags: ['会议', '编程', '写作', '阅读', '学习']),
      TagGroup(name: '生活', tags: ['运动', '购物', '休息', '娱乐', '社交']),
      TagGroup(name: '健康', tags: ['锻炼', '冥想', '饮食', '睡眠']),
    ];

    // 初始化带图标的标签组
    tagGroupsWithTags = tagGroups.map((g) => TagGroupWithTags.fromStringList(
      name: g.name,
      tags: g.tags,
    )).toList();

    await _loadTagGroups();
  }

  // 加载保存的标签组
  Future<void> _loadTagGroups() async {
    try {
      final savedGroups = await activityService.getTagGroups();
      if (savedGroups.isNotEmpty) {
        tagGroups = savedGroups;
        // 同步更新 tagGroupsWithTags
        tagGroupsWithTags = tagGroups.map((g) => TagGroupWithTags.fromStringList(
          name: g.name,
          tags: g.tags,
        )).toList();
        // 确保最近使用标签组总是存在
        if (!tagGroups.any((group) => group.name == '最近使用')) {
          tagGroups.insert(0, TagGroup(name: '最近使用', tags: []));
          tagGroupsWithTags.insert(0, TagGroupWithTags(name: '最近使用'));
        }
      }

      // 加载最近使用的标签
      final loadedRecentTags = await activityService.getRecentTags();
      if (loadedRecentTags.isNotEmpty) {
        recentTags = loadedRecentTags;
        _updateRecentTagGroup();
      }
    } catch (e) {
      debugPrint('加载标签组失败: $e');
    }
  }

  // 保存标签组
  Future<void> _saveTagGroups() async {
    try {
      await activityService.saveTagGroups(tagGroups);
    } catch (e) {
      debugPrint('保存标签组失败: $e');
    }
  }

  // 更新"最近使用"标签组
  void _updateRecentTagGroup() {
    final recentIndex = tagGroups.indexWhere((g) => g.name == '最近使用');
    if (recentIndex != -1) {
      tagGroups[recentIndex] = TagGroup(name: '最近使用', tags: List.from(recentTags));
    }
    // 同步更新 tagGroupsWithTags
    final recentIndexWithTags = tagGroupsWithTags.indexWhere((g) => g.name == '最近使用');
    if (recentIndexWithTags != -1) {
      tagGroupsWithTags[recentIndexWithTags] = TagGroupWithTags.fromStringList(
        name: '最近使用',
        tags: recentTags,
      );
    }
  }

  // 添加标签
  Future<void> addTag(String tag, {String? groupName}) async {
    final group = groupName != null
        ? tagGroups.firstWhere(
            (g) => g.name == groupName,
            orElse: () => TagGroup(name: groupName, tags: []),
          )
        : tagGroups.firstWhere((g) => g.name == '最近使用');

    if (!group.tags.contains(tag)) {
      group.tags.add(tag);
      await _saveTagGroups();
      onTagsChanged();
    }
  }

  // 删除标签
  Future<void> deleteTag(String tag) async {
    for (var group in tagGroups) {
      group.tags.remove(tag);
    }
    recentTags.remove(tag);
    await _saveTagGroups();
    onTagsChanged();
  }

  // 更新最近使用的标签
  Future<void> updateRecentTags(List<String> newTags) async {
    if (newTags.isEmpty) return;

    // 移除已存在的标签，然后将新标签添加到前面
    for (var tag in newTags) {
      recentTags.remove(tag);
      recentTags.insert(0, tag);
    }

    // 限制最多10个
    if (recentTags.length > 10) {
      recentTags.removeRange(10, recentTags.length);
    }

    _updateRecentTagGroup();
    await activityService.saveRecentTags(recentTags);
    await _saveTagGroups();
    onTagsChanged();
  }

  // 切换标签选择状态
  void toggleTagSelection(String tag) {
    if (selectedTags.contains(tag)) {
      selectedTags.remove(tag);
    } else {
      selectedTags.add(tag);
    }
    onTagsChanged();
  }

  // 清除所有选择
  void clearSelection() {
    selectedTags.clear();
    onTagsChanged();
  }

  // 显示标签管理对话框
  Future<void> showTagManagerDialog(BuildContext context) async {
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
        // 保存完整的 TagGroupWithTags 数据（包含图标）
        tagGroupsWithTags = newGroups;
        // 新格式转回旧格式（兼容性）
        tagGroups = newGroups.map((g) => TagGroup(
          name: g.name,
          tags: g.tags.map((t) => t.name).toList(),
        )).toList();
        _saveTagGroups();
        onTagsChanged();
      },
    );

    if (result != null) {
      selectedTags = result;
      // 更新最近使用的标签
      await updateRecentTags(result);
      onTagsChanged();
    }
  }

  /// 根据标签名称获取 TagItem（包含图标）
  TagItem? getTagItemByName(String tagName) {
    for (final group in tagGroupsWithTags) {
      for (final tag in group.tags) {
        if (tag.name == tagName) {
          return tag;
        }
      }
    }
    return null;
  }

  /// 获取活动的标签图标列表
  List<IconData> getTagIcons(List<String> tagNames) {
    final icons = <IconData>[];
    for (final tagName in tagNames) {
      final tag = getTagItemByName(tagName);
      if (tag != null) {
        icons.add(tag.icon);
      }
    }
    return icons;
  }

  /// 获取活动的标签颜色列表
  List<Color?> getTagColors(List<String> tagNames) {
    final colors = <Color?>[];
    for (final tagName in tagNames) {
      final tag = getTagItemByName(tagName);
      if (tag != null) {
        colors.add(tag.color);
      }
    }
    return colors;
  }
}
