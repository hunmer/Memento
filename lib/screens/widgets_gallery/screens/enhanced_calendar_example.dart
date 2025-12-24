import 'package:flutter/material.dart';

/// 增强日历示例
class EnhancedCalendarExample extends StatelessWidget {
  const EnhancedCalendarExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('增强日历'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'EnhancedCalendar',
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
                    '增强日历组件',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  const Text('这是一个增强的日历组件，提供更多的定制选项。'),
                  const SizedBox(height: 24),
                  const Text('功能特性:'),
                  const SizedBox(height: 8),
                  const Text('• 自定义样式'),
                  const Text('• 事件标记'),
                  const Text('• 多选支持'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
