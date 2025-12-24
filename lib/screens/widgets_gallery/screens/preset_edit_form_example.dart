import 'package:flutter/material.dart';

/// 预设编辑表单示例
class PresetEditFormExample extends StatelessWidget {
  const PresetEditFormExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('预设编辑表单'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PresetEditForm',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('这是一个预设编辑表单组件。'),
            const SizedBox(height: 24),
            Text(
              '功能特性',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('• 表单验证'),
            const Text('• 动态字段'),
            const Text('• 预设模板'),
          ],
        ),
      ),
    );
  }
}
