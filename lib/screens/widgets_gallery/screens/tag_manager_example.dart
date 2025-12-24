import 'package:flutter/material.dart';
import 'package:Memento/widgets/tag_manager_dialog/models/tag_group.dart';
import 'package:Memento/widgets/tag_manager_dialog/widgets/tag_manager_dialog.dart';

/// 标签管理器示例
class TagManagerExample extends StatefulWidget {
  const TagManagerExample({super.key});

  @override
  State<TagManagerExample> createState() => _TagManagerExampleState();
}

class _TagManagerExampleState extends State<TagManagerExample> {
  List<String> selectedTags = [];
  List<TagGroup> groups = const [
    TagGroup(name: '工作', tags: ['重要', '紧急', '待办']),
    TagGroup(name: '生活', tags: ['购物', '娱乐', '健康']),
    TagGroup(name: '学习', tags: ['阅读', '笔记', '复习']),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('标签管理器'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TagManagerDialog',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('这是一个标签管理器组件，支持标签的增删改查。'),
            const SizedBox(height: 24),
            Text(
              '功能特性',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('• 分组管理'),
            const Text('• 标签增删改'),
            const Text('• 多选支持'),
            const Text('• 搜索功能'),
            const SizedBox(height: 24),
            if (selectedTags.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.label),
                          const SizedBox(width: 12),
                          Text(
                            '已选择的标签 (${selectedTags.length})',
                            style:
                                Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedTags
                            .map((tag) => Chip(
                                  label: Text(tag),
                                  onDeleted: () {
                                    setState(() {
                                      selectedTags.remove(tag);
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: _showTagManager,
                icon: const Icon(Icons.label),
                label: const Text('选择标签'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTagManager() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => TagManagerDialog(
        groups: groups,
        selectedTags: selectedTags,
        onGroupsChanged: (newGroups) {
          setState(() {
            groups = newGroups;
          });
        },
        onTagsSelected: (tags) {
          // 实时更新选中的标签（可选）
          print('实时选择: $tags');
        },
      ),
    );
    if (result != null) {
      setState(() {
        selectedTags = result;
      });
    }
  }
}
