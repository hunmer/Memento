import 'package:flutter/material.dart';
import 'package:Memento/widgets/group_selector_dialog.dart';

/// 组选择器对话框示例
class GroupSelectorExample extends StatefulWidget {
  const GroupSelectorExample({super.key});

  @override
  State<GroupSelectorExample> createState() => _GroupSelectorExampleState();
}

class _GroupSelectorExampleState extends State<GroupSelectorExample> {
  String? selectedGroup;
  final List<String> groups = ['工作', '生活', '学习', '娱乐'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('组选择器对话框'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GroupSelectorDialog',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('这是一个组选择器对话框，支持分组选择、重命名和删除。'),
            const SizedBox(height: 32),
            if (selectedGroup != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.group_work),
                      const SizedBox(width: 12),
                      Text(selectedGroup!),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: _showGroupSelector,
                icon: const Icon(Icons.group_work),
                label: const Text('选择分组'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupSelector() async {
    final group = await showDialog<String>(
      context: context,
      builder: (context) => GroupSelectorDialog(
        groups: groups,
        initialSelectedGroup: selectedGroup,
        onGroupRenamed: (oldName, newName) {
          setState(() {
            final index = groups.indexOf(oldName);
            if (index >= 0) {
              groups[index] = newName;
            }
            if (selectedGroup == oldName) {
              selectedGroup = newName;
            }
          });
        },
        onGroupDeleted: (groupName) {
          setState(() {
            groups.remove(groupName);
            if (selectedGroup == groupName) {
              selectedGroup = null;
            }
          });
        },
      ),
    );
    if (group != null) {
      setState(() {
        selectedGroup = group;
      });
    }
  }
}
