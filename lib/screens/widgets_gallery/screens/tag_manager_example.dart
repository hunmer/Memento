import 'package:flutter/material.dart';
import 'package:Memento/widgets/tags_dialog/tags_dialog.dart';

/// 标签管理器示例
class TagManagerExample extends StatefulWidget {
  const TagManagerExample({super.key});

  @override
  State<TagManagerExample> createState() => _TagManagerExampleState();
}

class _TagManagerExampleState extends State<TagManagerExample> {
  List<String> selectedTags = [];

  // 使用兼容的旧格式数据（简单的字符串列表）
  final List<Map<String, dynamic>> legacyGroups = [
    {
      'name': '工作',
      'tags': ['重要', '紧急', '待办'],
    },
    {
      'name': '生活',
      'tags': ['购物', '娱乐', '健康'],
    },
    {
      'name': '学习',
      'tags': ['阅读', '笔记', '复习'],
    },
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
              'TagsDialog',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text(
                '全新的标签管理器组件，支持搜索、过滤、批量编辑等功能。'),
            const SizedBox(height: 24),
            Text(
              '功能特性',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('• 分组管理'),
            const Text('• 标签增删改'),
            const Text('• 多选支持'),
            const Text('• 搜索功能（标题、注释）'),
            const Text('• 多条件过滤（分组、排序）'),
            const Text('• 批量编辑模式'),
            const Text('• 长按菜单（编辑、删除）'),
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
    // 使用新的 TagsDialog，自动兼容旧格式数据
    final result = await TagsDialog.show(
      context,
      groups: legacyGroups, // 传入旧格式数据，会自动转换
      selectedTags: selectedTags,
      config: const TagsDialogConfig(
        title: '标签选择',
        selectionMode: TagsSelectionMode.multiple,
        enableEditing: true,
        enableBatchEdit: true,
      ),
      onGroupsChanged: (newGroups) {
        // 新格式数据变更回调
        print('分组已更新: ${newGroups.length} 个分组');
      },
    );

    if (result != null) {
      setState(() {
        selectedTags = result;
      });
    }
  }
}
