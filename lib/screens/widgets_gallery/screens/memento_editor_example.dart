import 'package:flutter/material.dart';

/// Memento 编辑器示例
class MementoEditorExample extends StatelessWidget {
  const MementoEditorExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memento 编辑器'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MementoEditor',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('这是一个富文本编辑器组件。'),
            const SizedBox(height: 24),
            Text(
              '功能特性',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('• 富文本编辑'),
            const Text('• 格式化工具栏'),
            const Text('• 多媒体支持'),
          ],
        ),
      ),
    );
  }
}
