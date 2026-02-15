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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('组选择器对话框'),
      ),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('组件说明'),
                const SizedBox(height: 8),
                const Text('点击按钮打开组选择器对话框，支持分组选择、重命名和删除'),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _showGroupSelector,
                    icon: const Icon(Icons.group_work),
                    label: const Text('打开组选择器'),
                  ),
                ),
                if (selectedGroup != null) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.group_work),
                            const SizedBox(width: 12),
                            Text('已选择: $selectedGroup',
                                style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
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
