import 'package:flutter/material.dart';
import 'circle_icon_picker.dart';

class GroupManagementDialog<T> {
  final BuildContext context;
  final List<T> items;
  final String Function(T) getGroupName;
  final String Function(T) getItemName;
  final bool Function(T) isItemChecked;
  final Future<void> Function(T, String) updateItemGroup;
  final Future<void> Function(String, IconData, Color) createNewGroup;
  final VoidCallback onStateChanged;

  GroupManagementDialog({
    required this.context,
    required this.items,
    required this.getGroupName,
    required this.getItemName,
    required this.isItemChecked,
    required this.updateItemGroup,
    required this.createNewGroup,
    required this.onStateChanged,
  });

  void show() {
    showDialog(
      context: context,
      builder:
          (BuildContext dialogContext) => StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                title: const Text('分组管理'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (groups.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              '暂无分组',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: groups.length,
                            itemBuilder: (context, index) {
                              final group = groups[index];
                              final groupItems = groupedItems[group] ?? [];
                              final completedCount =
                                  groupItems.where(isItemChecked).length;

                              return ListTile(
                                leading: const Icon(Icons.folder_outlined),
                                title: Text(group),
                                subtitle: Text(
                                  '${groupItems.length}个项目，$completedCount个已完成',
                                  style: TextStyle(
                                    color:
                                        completedCount > 0
                                            ? Colors.green
                                            : Colors.grey,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      tooltip: '编辑分组',
                                      onPressed: () {
                                        _showEditOrCreateGroupDialog(
                                          group: group,
                                          items: groupItems,
                                          parentContext: dialogContext,
                                          onGroupUpdated: () => setState(() {}),
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
                      _showEditOrCreateGroupDialog(
                        parentContext: dialogContext,
                        onGroupUpdated: () => setState(() {}),
                      );
                    },
                    child: const Text('新建'),
                  ),
                ],
              );
            },
          ),
    ).then((_) {
      // 关闭对话框后刷新界面
      onStateChanged();
    });
  }

  List<String> get groups => items.map(getGroupName).toSet().toList()..sort();

  Map<String, List<T>> get groupedItems {
    final grouped = <String, List<T>>{};
    for (var item in items) {
      final group = getGroupName(item);
      if (!grouped.containsKey(group)) {
        grouped[group] = [];
      }
      grouped[group]!.add(item);
    }
    return grouped;
  }

  void _showEditOrCreateGroupDialog({
    String? group,
    List<T>? items,
    required BuildContext parentContext,
    required VoidCallback onGroupUpdated,
  }) {
    final bool isEditing = group != null;
    final TextEditingController groupController = TextEditingController(
      text: group,
    );
    IconData selectedIcon = Icons.folder; // 默认图标
    Color selectedColor = Colors.blue; // 默认颜色

    showDialog(
      context: parentContext,
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
                    onPressed: () async {
                      final newGroupName = groupController.text.trim();
                      if (newGroupName.isNotEmpty &&
                          (!isEditing || newGroupName != group)) {
                        if (isEditing) {
                          // 更新所有该分组下的项目
                          for (var item in items!) {
                            await updateItemGroup(item, newGroupName);
                          }
                        } else {
                          // 创建新分组
                          await createNewGroup(
                            newGroupName,
                            selectedIcon,
                            selectedColor,
                          );
                        }

                        Navigator.pop(context);
                        onGroupUpdated();
                        onStateChanged();
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEditing
                                  ? '已更新分组"$newGroupName"'
                                  : '已创建新分组"$newGroupName"',
                            ),
                          ),
                        );
                      } else {
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
}
