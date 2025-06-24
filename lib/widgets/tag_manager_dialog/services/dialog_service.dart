import 'package:flutter/material.dart';
import '../models/tag_group.dart';
import '../l10n/tag_manager_localizations.dart';
import '../l10n/tag_manager_dialog_localizations.dart';

/// 对话框服务类，处理标签管理对话框的各种操作
class DialogService {
  /// 创建新分组
  static Future<String?> createNewGroup(
    BuildContext context,
    String hintText,
  ) async {
    final TextEditingController textController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(TagManagerLocalizations.of(context, 'newGroup')),
            content: TextField(
              autofocus: true,
              controller: textController,
              decoration: InputDecoration(hintText: hintText),
              onSubmitted: (value) => Navigator.of(context).pop(value),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(TagManagerLocalizations.of(context, 'cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(textController.text),
                child: Text(TagManagerLocalizations.of(context, 'confirm')),
              ),
            ],
          ),
    );
  }

  /// 添加新标签
  static Future<String?> addNewTag(
    BuildContext context,
    String hintText,
  ) async {
    final TextEditingController textController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(TagManagerLocalizations.of(context, 'newTag')),
            content: TextField(
              autofocus: true,
              controller: textController,
              decoration: InputDecoration(hintText: hintText),
              onSubmitted: (value) => Navigator.of(context).pop(value),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(TagManagerLocalizations.of(context, 'cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(textController.text),
                child: Text(TagManagerLocalizations.of(context, 'confirm')),
              ),
            ],
          ),
    );
  }

  /// 编辑分组
  static Future<Map<String, dynamic>?> editGroup(
    BuildContext context,
    String groupName,
    String hintText,
  ) async {
    final TextEditingController textController = TextEditingController(
      text: groupName,
    );

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(TagManagerDialogLocalizations.getEditGroup(context)),
            content: TextField(
              autofocus: true,
              controller: textController,
              decoration: InputDecoration(hintText: hintText),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed:
                    () => Navigator.of(context).pop({'action': 'delete'}),
                child: Text(TagManagerLocalizations.of(context, 'deleteGroup')),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(TagManagerLocalizations.of(context, 'cancel')),
              ),
              TextButton(
                onPressed:
                    () => Navigator.of(
                      context,
                    ).pop({'action': 'rename', 'name': textController.text}),
                child: Text(TagManagerLocalizations.of(context, 'confirm')),
              ),
            ],
          ),
    );
  }

  /// 添加标签到分组
  static void addTagToGroup(
    List<TagGroup> groups,
    String groupName,
    String tagName,
    Function(List<TagGroup>) onGroupsChanged,
  ) {
    final groupIndex = groups.indexWhere((g) => g.name == groupName);
    if (groupIndex != -1) {
      if (!groups[groupIndex].tags.contains(tagName)) {
        final currentTags = List<String>.from(groups[groupIndex].tags);
        currentTags.add(tagName);
        groups[groupIndex] = TagGroup(
          name: groupName,
          tags: currentTags,
          tagIds: groups[groupIndex].tagIds,
        );
        onGroupsChanged(groups);
      }
    }
  }

  /// 删除分组
  static String deleteGroup(
    List<TagGroup> groups,
    String groupName,
    String defaultGroup,
    Function(List<TagGroup>) onGroupsChanged,
  ) {
    groups.removeWhere((group) => group.name == groupName);
    final newSelectedGroup = groups.isEmpty ? defaultGroup : groups[0].name;
    onGroupsChanged(groups);
    return newSelectedGroup;
  }

  /// 删除选中的标签
  static void deleteSelectedTags(
    List<TagGroup> groups,
    String groupName,
    List<String> selectedTags,
    Function(List<TagGroup>) onGroupsChanged,
    Function(List<String>)? onTagsSelected,
  ) {
    final groupIndex = groups.indexWhere((g) => g.name == groupName);
    if (groupIndex != -1) {
      final currentTags = List<String>.from(groups[groupIndex].tags);
      currentTags.removeWhere((tag) => selectedTags.contains(tag));
      groups[groupIndex] = TagGroup(
        name: groupName,
        tags: currentTags,
        tagIds: groups[groupIndex].tagIds,
      );
      selectedTags.clear();
      onGroupsChanged(groups);
      onTagsSelected?.call(selectedTags);
    }
  }
}
