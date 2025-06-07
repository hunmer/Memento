import 'package:flutter/material.dart';
import '../models/tag_group.dart' as dialog;
import '../models/tag_manager_config.dart';
import '../services/dialog_service.dart';
import '../widgets/tag_manager_dialog.dart';

/// 标签管理器对话框状态
abstract class TagManagerDialogState extends State<TagManagerDialog> {
  @protected
  late String selectedGroup;
  @protected
  late List<String> selectedTags;
  @protected
  late List<dialog.TagGroup> groups;
  @protected
  late final TagManagerConfig config;

  @protected
  List<String> get allTags =>
      groups.expand((group) => group.tags).toSet().toList();
  @protected
  List<String> get groupNames => groups.map((g) => g.name).toList();

  @override
  void initState() {
    super.initState();
    groups = List.from(widget.groups);
    selectedTags = List.from(widget.selectedTags);
    selectedGroup = widget.config?.allTagsLabel ?? '所有标签';
    config = widget.config ?? const TagManagerConfig();
  }

  @protected
  Future<void> createNewGroup() async {
    if (!widget.enableEditing) return;

    final name = await DialogService.createNewGroup(
      context,
      config.addGroupHint,
    );

    if (name != null && name.isNotEmpty) {
      setState(() {
        groups.add(dialog.TagGroup(name: name, tags: []));
        selectedGroup = name;
      });
      widget.onGroupsChanged(groups);
    }
  }

  @protected
  Future<void> addNewTag() async {
    if (!widget.enableEditing || selectedGroup == config.newGroupLabel) return;

    String? name;

    // 使用自定义的添加标签回调，如果提供了的话
    if (widget.onAddTag != null) {
      name = await widget.onAddTag!(selectedGroup);
    } else {
      // 默认的添加标签对话框
      name = await DialogService.addNewTag(context, config.addTagHint);
    }

    if (name != null && name.isNotEmpty) {
      setState(() {
        DialogService.addTagToGroup(
          groups,
          selectedGroup,
          name!,
          widget.onGroupsChanged,
        );
      });
    }
  }

  @protected
  Future<void> editCurrentGroup() async {
    if (!widget.enableEditing) return;

    final result = await DialogService.editGroup(
      context,
      selectedGroup,
      config.editGroupHint,
    );

    if (result != null) {
      if (result['action'] == 'delete') {
        deleteCurrentGroup();
      } else if (result['action'] == 'rename' &&
          result['name'] != null &&
          result['name'].isNotEmpty) {
        setState(() {
          final index = groups.indexWhere((g) => g.name == selectedGroup);
          if (index != -1) {
            groups[index] = dialog.TagGroup(
              name: result['name'],
              tags: groups[index].tags,
              tagIds: groups[index].tagIds,
            );
            selectedGroup = result['name'];
            widget.onGroupsChanged(groups);
          }
        });
      }
    }
  }

  @protected
  void onTagToggle(String tag) {
    setState(() {
      if (selectedTags.contains(tag)) {
        selectedTags.remove(tag);
      } else {
        selectedTags.add(tag);
      }
    });
    widget.onTagsSelected?.call(selectedTags);
  }

  @protected
  void deleteCurrentGroup() {
    if (!widget.enableEditing || selectedGroup == config.newGroupLabel) return;

    setState(() {
      selectedGroup = DialogService.deleteGroup(
        groups,
        selectedGroup,
        config.newGroupLabel,
        widget.onGroupsChanged,
      );
    });
  }

  @protected
  void deleteSelectedTags() {
    if (!widget.enableEditing ||
        selectedGroup == config.newGroupLabel ||
        selectedTags.isEmpty) {
      return;
    }

    setState(() {
      DialogService.deleteSelectedTags(
        groups,
        selectedGroup,
        selectedTags,
        widget.onGroupsChanged,
        widget.onTagsSelected,
      );
    });
  }

  @protected
  List<String> getCurrentGroupTags() {
    if (selectedGroup == config.allTagsLabel) {
      return allTags;
    }
    final currentGroup = groups.firstWhere(
      (group) => group.name == selectedGroup,
      orElse: () => dialog.TagGroup(name: config.newGroupLabel, tags: []),
    );
    return currentGroup.tags.toSet().toList();
  }

  @protected
  void clearSelectedTags() {
    setState(() {
      selectedTags.clear();
    });
    widget.onTagsSelected?.call(selectedTags);
  }

  @protected
  void onGroupChanged(String? value) {
    if (value != null) {
      setState(() {
        selectedGroup = value;
        if (value != config.allTagsLabel) {
          selectedTags.clear();
          widget.onTagsSelected?.call(selectedTags);
        }
      });
    }
  }

  @protected
  String getTagRealGroup(String tag) {
    for (var group in groups) {
      if (group.tags.contains(tag)) {
        return group.name;
      }
    }
    return selectedGroup;
  }

  @protected
  Future<void> handleTagLongPress(String tag, String group) async {
    if (widget.onAddTag != null) {
      final realGroup =
          group == config.allTagsLabel ? getTagRealGroup(tag) : group;
      final result = await widget.onAddTag!(realGroup, tag: tag);

      // 如果有返回值并且提供了刷新数据的回调，则获取最新数据
      if (result != null && widget.onRefreshData != null) {
        final newGroups = await widget.onRefreshData!();
        setState(() {
          groups = List.from(newGroups);
          // 保持当前选中的分组
          if (!groupNames.contains(selectedGroup) &&
              selectedGroup != config.allTagsLabel) {
            selectedGroup = config.allTagsLabel;
          }
        });
        widget.onGroupsChanged(groups);
      }
    }
  }
}
