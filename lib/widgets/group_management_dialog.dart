import 'package:flutter/material.dart';
import 'circle_icon_picker.dart';

class GroupData {
  final String name;
  final int itemCount;
  final int completedCount;
  final List<dynamic> items;

  GroupData({
    required this.name,
    required this.itemCount,
    required this.completedCount,
    required this.items,
  });
}

class GroupManagementDialog extends StatefulWidget {
  final List<GroupData> groups;
  final Function(String oldGroup, String newGroup) onGroupRenamed;
  final Function(String groupName, IconData icon, Color color) onGroupCreated;
  final Map<String, bool> expandedGroups;
  final String title;
  final Widget Function(BuildContext, GroupData)? customItemBuilder;

  const GroupManagementDialog({
    super.key,
    required this.groups,
    required this.onGroupRenamed,
    required this.onGroupCreated,
    required this.expandedGroups,
    this.title = '分组管理',
    this.customItemBuilder,
  });

  static Future<void> show({
    required BuildContext context,
    required List<GroupData> groups,
    required Function(String oldGroup, String newGroup) onGroupRenamed,
    required Function(String groupName, IconData icon, Color color)
    onGroupCreated,
    required Map<String, bool> expandedGroups,
    String title = '分组管理',
    Widget Function(BuildContext, GroupData)? customItemBuilder,
  }) {
    return showDialog(
      context: context,
      builder:
          (BuildContext dialogContext) => GroupManagementDialog(
            groups: groups,
            onGroupRenamed: onGroupRenamed,
            onGroupCreated: onGroupCreated,
            expandedGroups: expandedGroups,
            title: title,
            customItemBuilder: customItemBuilder,
          ),
    );
  }

  @override
  State<GroupManagementDialog> createState() => _GroupManagementDialogState();
}

class _GroupManagementDialogState extends State<GroupManagementDialog> {
  void _showEditOrCreateGroupDialog({String? group, List<dynamic>? items}) {
    final bool isEditing = group != null;
    final TextEditingController groupController = TextEditingController(
      text: group,
    );
    IconData selectedIcon = Icons.folder;
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder:
          (BuildContext context) => StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                title: Text(isEditing ? '编辑分组' : '新建分组'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleIconPicker(
                        currentIcon: selectedIcon,
                        backgroundColor: selectedColor,
                        onIconSelected: (icon) {
                          setState(() => selectedIcon = icon);
                        },
                        onColorSelected: (color) {
                          setState(() => selectedColor = color);
                        },
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: groupController,
                        decoration: const InputDecoration(
                          labelText: '分组名称',
                          hintText: '请输入分组名称',
                        ),
                      ),
                      if (isEditing) ...[
                        const SizedBox(height: 16),
                        Text('该分组包含 ${items!.length} 个项目'),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () {
                      final newGroupName = groupController.text.trim();
                      if (newGroupName.isNotEmpty &&
                          (!isEditing || newGroupName != group)) {
                        if (isEditing) {
                          widget.onGroupRenamed(group, newGroupName);
                          setState(() {});
                        } else {
                          widget.onGroupCreated(
                            newGroupName,
                            selectedIcon,
                            selectedColor,
                          );
                          setState(() {});
                        }
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('保存'),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.groups.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    '暂无分组',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.groups.length,
                  itemBuilder: (context, index) {
                    final group = widget.groups[index];

                    if (widget.customItemBuilder != null) {
                      return widget.customItemBuilder!(context, group);
                    }

                    return ListTile(
                      leading: const Icon(Icons.folder_outlined),
                      title: Text(group.name),
                      subtitle: Text(
                        '${group.itemCount}个项目，${group.completedCount}个已完成',
                        style: TextStyle(
                          color:
                              group.completedCount > 0
                                  ? Colors.green
                                  : Colors.grey,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (group.itemCount == 0)
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: '删除空分组',
                              onPressed: () {
                                setState(() {});
                                Navigator.pop(context);
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: '编辑分组',
                            onPressed: () {
                              _showEditOrCreateGroupDialog(
                                group: group.name,
                                items: group.items,
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
        TextButton(
          onPressed: () {
            _showEditOrCreateGroupDialog();
          },
          child: const Text('新建'),
        ),
      ],
    );
  }
}
