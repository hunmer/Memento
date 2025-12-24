import 'package:flutter/material.dart';

/// 小组件配置编辑器示例
class WidgetConfigEditorExample extends StatelessWidget {
  const WidgetConfigEditorExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('小组件配置编辑器'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WidgetConfigEditor',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('这是一个小组件配置编辑器组件。'),
            const SizedBox(height: 24),
            Text(
              '功能特性',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('• 尺寸配置'),
            const Text('• 颜色配置'),
            const Text('• 实时预览'),
          ],
        ),
      ),
    );
  }
}
