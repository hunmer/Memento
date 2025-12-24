import 'package:flutter/material.dart';

/// Markdown 编辑器示例
class MarkdownEditorExample extends StatelessWidget {
  const MarkdownEditorExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Markdown 编辑器'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'MarkdownEditor',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Markdown 编辑器组件',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  const Text('这是一个支持 Markdown 语法的编辑器。'),
                  const SizedBox(height: 16),
                  const Text('功能特性:'),
                  const SizedBox(height: 8),
                  const Text('• 支持 Markdown 语法'),
                  const Text('• 实时预览'),
                  const Text('• 工具栏快捷操作'),
                  const Text('• 代码高亮'),
                  const SizedBox(height: 24),
                  const Text('使用示例:'),
                  const SizedBox(height: 8),
                  const SelectableText('''
MarkdownEditor(
  initialTitle: '标题',
  initialContent: '内容',
  onSave: (title, content) {
    // 保存逻辑
  },
)'''),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
