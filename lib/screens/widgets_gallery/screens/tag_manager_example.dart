import 'package:flutter/material.dart';

/// 标签管理器示例
class TagManagerExample extends StatelessWidget {
  const TagManagerExample({super.key});

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
          ],
        ),
      ),
    );
  }
}
