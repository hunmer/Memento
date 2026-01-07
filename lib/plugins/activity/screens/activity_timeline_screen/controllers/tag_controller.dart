import 'package:flutter/material.dart';
import 'package:Memento/plugins/activity/services/activity_service.dart';
import 'package:Memento/widgets/tags_dialog/models/models.dart';
import 'package:Memento/widgets/tags_dialog/tags_dialog.dart';

class TagController {
  final ActivityService activityService;
  final VoidCallback onTagsChanged;

  List<TagGroupWithTags> tagGroups = [];
  List<String> selectedTags = [];
  List<String> recentTags = [];

  TagController({required this.activityService, required this.onTagsChanged});

  Future<void> initialize() async {
    // 初始化标签组（使用新格式）
    tagGroups = [
      TagGroupWithTags(name: '最近使用', tags: []),
      TagGroupWithTags.fromStringList(
        name: '工作',
        tags: ['会议', '编程', '写作', '阅读', '学习'],
      ),
      TagGroupWithTags.fromStringList(
        name: '生活',
        tags: ['运动', '购物', '休息', '娱乐', '社交'],
      ),
      TagGroupWithTags.fromStringList(
        name: '健康',
        tags: ['锻炼', '冥想', '饮食', '睡眠'],
      ),
    ];

    await _loadTagGroups();
  }

  // 加载保存的标签组
  Future<void> _loadTagGroups() async {
    try {
      final savedGroups = await activityService.getTagGroups();
      if (savedGroups.isNotEmpty) {
        tagGroups = savedGroups;
        // 确保最近使用标签组总是存在
        if (!tagGroups.any((group) => group.name == '最近使用')) {
          tagGroups.insert(0, TagGroupWithTags(name: '最近使用'));
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
      tagGroups[recentIndex] = TagGroupWithTags.fromStringList(
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
            orElse: () => TagGroupWithTags(name: groupName),
          )
        : tagGroups.firstWhere((g) => g.name == '最近使用');

    final tagNames = group.tags.map((t) => t.name).toList();
    if (!tagNames.contains(tag)) {
      // 创建新的 TagItem 并添加到分组
      final newTag = TagItem(
        name: tag,
        group: group.name,
        createdAt: DateTime.now(),
      );
      final updatedGroup = TagGroupWithTags(
        name: group.name,
        tags: [...group.tags, newTag],
      );
      final groupIndex = tagGroups.indexWhere((g) => g.name == group.name);
      if (groupIndex != -1) {
        tagGroups[groupIndex] = updatedGroup;
      }
      await _saveTagGroups();
      onTagsChanged();
    }
  }

  // 删除标签
  Future<void> deleteTag(String tag) async {
    for (var i = 0; i < tagGroups.length; i++) {
      final group = tagGroups[i];
      final filteredTags = group.tags.where((t) => t.name != tag).toList();
      tagGroups[i] = TagGroupWithTags(name: group.name, tags: filteredTags);
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
    final result = await TagsDialog.show(
      context,
      groups: tagGroups,
      selectedTags: List.from(selectedTags),
      config: const TagsDialogConfig(
        title: '标签管理',
        selectionMode: TagsSelectionMode.multiple,
        enableEditing: true,
        enableBatchEdit: true,
      ),
      onGroupsChanged: (newGroups) {
        tagGroups = newGroups;
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
    for (final group in tagGroups) {
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
