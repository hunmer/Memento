import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/task_progress_card.dart';

/// 任务进度卡片示例
class TaskProgressCardExample extends StatelessWidget {
  const TaskProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('任务进度卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: TaskProgressCardWidget(
            title: 'Widgefy UI kit',
            subtitle: 'Graphics design',
            completedTasks: 7,
            totalTasks: 14,
            pendingTasks: [
              'Design search page for website',
              'Send an estimate budget for app',
              'Export assets for HTML developer',
            ],
          ),
        ),
      ),
    );
  }
}
