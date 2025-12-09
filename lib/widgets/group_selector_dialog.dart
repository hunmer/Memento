import 'package:flutter/material.dart';
import 'package:get/get.dart';

typedef OnGroupRenamed = void Function(String oldName, String newName);
typedef OnGroupDeleted = void Function(String groupName);

class GroupSelectorDialog extends StatefulWidget {
  final List<String> groups;
  final OnGroupRenamed onGroupRenamed;
  final OnGroupDeleted onGroupDeleted;
  final String? initialSelectedGroup;

  const GroupSelectorDialog({
    super.key,
    required this.groups,
    required this.onGroupRenamed,
    required this.onGroupDeleted,
    this.initialSelectedGroup,
  });

  @override
  State<GroupSelectorDialog> createState() => _GroupSelectorDialogState();
}

class _GroupSelectorDialogState extends State<GroupSelectorDialog> {
  late String? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _selectedGroup = widget.initialSelectedGroup;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('group_selector_selectGroup'.tr),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.groups.length,
          itemBuilder: (context, index) {
            final group = widget.groups[index];
            return ListTile(
              title: Text(group),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showRenameDialog(group),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _showDeleteDialog(group),
                  ),
                ],
              ),
              onTap: () {
                setState(() {
                  _selectedGroup = group;
                });
                Navigator.of(context).pop(_selectedGroup);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('group_selector_cancel'.tr),
        ),
        TextButton(
          onPressed: () => _showCreateDialog(),
          child: Text('group_selector_newGroup'.tr),
        ),
      ],
    );
  }

  void _showRenameDialog(String oldName) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('group_selector_renameGroup'.tr),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'group_selector_groupName'.tr,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('group_selector_cancel'.tr),
              ),
              TextButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    final index = widget.groups.indexOf(oldName);
                    if (index != -1) widget.groups[index] = controller.text;
                    widget.onGroupRenamed(oldName, controller.text);
                    setState(() {}); // 刷新列表
                    Navigator.of(context).pop();
                  }
                },
                child: Text('group_selector_ok'.tr),
              ),
            ],
          ),
    );
  }

  void _showDeleteDialog(String groupName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('group_selector_deleteGroup'.tr),
            content: Text(
              'group_selector_deleteGroupConfirmation'.trParams({
                'groupName': groupName,
              }),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('group_selector_cancel'.tr),
              ),
              TextButton(
                onPressed: () {
                  widget.groups.remove(groupName);
                  widget.onGroupDeleted(groupName);
                  setState(() {}); // 刷新列表
                  Navigator.of(context).pop();
                },
                child: Text('group_selector_ok'.tr),
              ),
            ],
          ),
    );
  }

  void _showCreateDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('group_selector_createGroup'.tr),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'group_selector_groupName'.tr,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('group_selector_cancel'.tr),
              ),
              TextButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    widget.groups.add(controller.text);
                    setState(() {
                      _selectedGroup = controller.text;
                    });
                    setState(() {}); // 刷新列表
                    Navigator.of(context).pop(_selectedGroup);
                  }
                },
                child: Text('group_selector_ok'.tr),
              ),
            ],
          ),
    );
  }
}
