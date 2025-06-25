import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

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
      title: const Text('选择分组'),
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
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: () => _showCreateDialog(),
          child: const Text('新建分组'),
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
            title: const Text('重命名分组'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: '分组名称'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.cancel),
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
                child: Text(AppLocalizations.of(context)!.ok),
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
            title: const Text('删除分组'),
            content: Text('确定要删除分组"$groupName"吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () {
                  widget.groups.remove(groupName);
                  widget.onGroupDeleted(groupName);
                  setState(() {}); // 刷新列表
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context)!.ok),
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
            title: const Text('新建分组'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: '分组名称'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.cancel),
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
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
    );
  }
}
