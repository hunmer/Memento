import 'package:flutter/material.dart';

/// Quill 富文本查看器示例
class QuillViewerExample extends StatelessWidget {
  const QuillViewerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quill 富文本查看器'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'QuillViewer',
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
                    'Quill 富文本查看器组件',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  const Text('这是一个用于显示 Quill Delta JSON 格式富文本的查看器。'),
                  const SizedBox(height: 24),
                  const Text('使用示例:'),
                  const SizedBox(height: 8),
                  const SelectableText('''
QuillViewer(
  data: {
    "ops": [
      {"insert": "标题\\n", "attributes": {"header": 1}},
      {"insert": "正文内容"},
    ]
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
