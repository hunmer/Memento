import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/task_list_stat_card.dart';

/// 任务统计列表卡片示例
class TaskListStatCardExample extends StatelessWidget {
  const TaskListStatCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('任务统计列表卡片'),
        backgroundColor: isDark ? Colors.black : const Color(0xFF545AE7),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFF545AE7),
        child: const Center(
          child: TaskListStatCardWidget(
            icon: Icons.format_list_bulleted,
            count: 48,
            statusLabel: 'Upcoming',
            tasks: [
              'Design mobile UI dashboard',
              'Calculate budget and contract',
              'Search for a UI kit',
              'Create HTML & CSS for startup',
            ],
            remainingCount: 10,
            primaryColor: Color(0xFF5A72EA),
          ),
        ),
      ),
    );
  }
}
