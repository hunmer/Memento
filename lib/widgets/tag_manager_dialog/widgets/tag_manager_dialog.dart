import 'package:flutter/material.dart';
import '../models/tag_group.dart';
import '../models/tag_manager_config.dart';
import '../states/tag_manager_dialog_state.dart';
import 'dialog_toolbar.dart';
import 'tag_list.dart';
import 'dialog_actions.dart';

/// 标签管理对话框
class TagManagerDialog extends StatefulWidget {
  /// 标签分组列表
  final List<TagGroup> groups;

  /// 已选择的标签列表
  final List<String> selectedTags;

  /// 标签分组变更回调
  final Function(List<TagGroup>) onGroupsChanged;

  /// 标签选择变更回调
  final Function(List<String>)? onTagsSelected;

  /// 是否启用编辑功能
  final bool enableEditing;

  /// 添加标签回调
  final Future<String?> Function(String group, {String? tag})? onAddTag;

  /// 配置选项
  final TagManagerConfig? config;

  const TagManagerDialog({
    super.key,
    required this.groups,
    required this.selectedTags,
    required this.onGroupsChanged,
    this.onTagsSelected,
    this.enableEditing = true,
    this.onAddTag,
    this.config,
  });

  @override
  State<TagManagerDialog> createState() => _TagManagerDialogState();
}

/// 标签管理器对话框状态实现
class _TagManagerDialogState extends TagManagerDialogState {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 工具栏
            DialogToolbar(
              selectedGroup: selectedGroup,
              groups: groupNames,
              config: config,
              enableEditing: widget.enableEditing,
              onGroupChanged: onGroupChanged,
              onEditGroup: editCurrentGroup,
              onDeleteTags: deleteSelectedTags,
              onAddTag: addNewTag,
              onCreateGroup: createNewGroup,
            ),
            
            const SizedBox(height: 16),
            
            // 标签列表
            TagList(
              tags: getCurrentGroupTags(),
              selectedTags: selectedTags,
              onTagToggle: onTagToggle,
              config: config,
              onLongPress: widget.onAddTag != null ? handleTagLongPress : null,
              selectedGroup: selectedGroup,
            ),
            
            const SizedBox(height: 16),
            
            // 底部操作按钮
            DialogActions(
              selectedCount: selectedTags.length,
              onClear: clearSelectedTags,
              onCancel: () => Navigator.of(context).pop(),
              onConfirm: () => Navigator.of(context).pop(selectedTags),
              enableClear: selectedTags.isNotEmpty,
            ),
          ],
        ),
      ),
    );
  }
}