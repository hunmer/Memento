import 'package:flutter/material.dart';
import 'package:Memento/widgets/simple_group_selector.dart';

/// 简单组选择器示例
class SimpleGroupSelectorExample extends StatefulWidget {
  const SimpleGroupSelectorExample({super.key});

  @override
  State<SimpleGroupSelectorExample> createState() => _SimpleGroupSelectorExampleState();
}

class _SimpleGroupSelectorExampleState extends State<SimpleGroupSelectorExample> {
  String? selectedGroup;
  final List<String> groups = ['工作', '生活', '学习', '娱乐'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('简单组选择器'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SimpleGroupSelector',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('这是一个简单的组选择器组件。'),
            const SizedBox(height: 32),
            SimpleGroupSelector(
              groups: groups,
              selectedGroup: selectedGroup,
              onGroupSelected: (group) {
                setState(() {
                  selectedGroup = group;
                });
              },
            ),
            const SizedBox(height: 24),
            if (selectedGroup != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('已选择: $selectedGroup'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
