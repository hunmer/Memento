import 'package:flutter/material.dart';
import '../../../models/activity_record.dart';
import '../../../services/activity_service.dart';
import '../../../widgets/tag_manager_dialog.dart';

class TagController {
  final ActivityService activityService;
  final VoidCallback onTagsChanged;
  
  List<TagGroup> tagGroups = [];
  List<String> selectedTags = [];
  List<String> recentTags = [];

  TagController({
    required this.activityService,
    required this.onTagsChanged,
  });

  Future<void> initialize() async {
    // 初始化标签组
    tagGroups = [
      TagGroup(name: '最近使用', tags: []),
      TagGroup(name: '工作', tags: ['会议', '编程', '写作', '阅读', '学习']),
      TagGroup(name: '生活', tags: ['运动', '购物', '休息', '娱乐', '社交']),
      TagGroup(name: '健康', tags: ['锻炼', '冥想', '饮食', '睡眠']),
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
          tagGroups.insert(0, TagGroup(name: '最近使用', tags: []));
        }
      }

      // 加载最近使用的标签
      final loadedRecentTags = await activityService.getRecentTags();
      if (loadedRecentTags.isNotEmpty) {
        recentTags = loadedRecentTags;

        // 更新最近使用标签组
        _updateRecentTagGroup();
      }
      
      onTagsChanged();
    } catch (e) {
      // 处理错误
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

  void _updateRecentTagGroup() {
    final recentGroupIndex = tagGroups.indexWhere((g) => g.name == '最近使用');
    if (recentGroupIndex != -1) {
      tagGroups[recentGroupIndex] = TagGroup(
        name: '最近使用',
        tags: List.from(recentTags),
      );
    }
  }

  // 更新最近使用的标签
  Future<void> updateRecentTags(List<String> tags) async {
    if (tags.isEmpty) return;

    // 更新最近使用标签列表
    for (final tag in tags) {
      recentTags.remove(tag); // 如果已存在，先移除
      recentTags.insert(0, tag); // 添加到最前面
    }

    // 限制最近使用标签数量
    if (recentTags.length > 10) {
      recentTags.removeRange(10, recentTags.length);
    }

    // 更新最近使用标签组
    _updateRecentTagGroup();

    // 保存最近使用的标签
    await activityService.saveRecentTags(recentTags);

    // 保存标签组
    await _saveTagGroups();
    
    onTagsChanged();
  }

  Future<void> showTagManagerDialog(BuildContext context) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => TagManagerDialog(
        groups: tagGroups,
        selectedTags: selectedTags,
        onGroupsChanged: (updatedGroups) {
          // 保存更新后的标签组
          tagGroups = updatedGroups;
          _saveTagGroups();
          onTagsChanged();
        },
      ),
    );

    if (result != null) {
      selectedTags = result;
      // 更新最近使用的标签
      await updateRecentTags(result);
      onTagsChanged();
    }
  }
}