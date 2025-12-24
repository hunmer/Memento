import 'package:flutter/material.dart';

/// 数据选择器示例
class DataSelectorExample extends StatelessWidget {
  const DataSelectorExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据选择器'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DataSelectorSheet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('这是一个数据选择器组件，支持树形数据结构和搜索。'),
            const SizedBox(height: 24),
            Text(
              '功能特性',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('• 树形数据结构'),
            const Text('• 搜索功能'),
            const Text('• 面包屑导航'),
            const Text('• 网格/列表视图切换'),
          ],
        ),
      ),
    );
  }
}
