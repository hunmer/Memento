import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/task_progress_list.dart';

/// 任务进度列表示例
class TaskProgressListExample extends StatelessWidget {
  const TaskProgressListExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('任务进度列表')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: TaskProgressListWidget(
            tasks: [
              TaskProgressData(
                title: 'Design mobile UI dashboard',
                time: '24 mins ago',
                progress: 1.0,
                color: Color(0xFF34D399),
              ),
              TaskProgressData(
                title: 'Calculate budget and contract',
                time: '54 mins ago',
                progress: 0.67,
                color: Color(0xFFFBBF24),
              ),
              TaskProgressData(
                title: 'Search for a UI kit',
                time: '54 mins ago',
                progress: 1.0,
                color: Color(0xFF34D399),
              ),
              TaskProgressData(
                title: 'Design search page for website',
                time: '54 mins ago',
                progress: 0.25,
                color: Color(0xFFFB7185),
              ),
              TaskProgressData(
                title: 'Create HTML & CSS for startup',
                time: '54 mins ago',
                progress: 0.25,
                color: Color(0xFFFB7185),
              ),
            ],
            moreCount: 10,
          ),
        ),
      ),
    );
  }
}
