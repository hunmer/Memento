import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/upcoming_tasks_widget.dart';

/// 即将到来的任务小组件示例
class UpcomingTasksWidgetExample extends StatelessWidget {
  const UpcomingTasksWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('即将到来的任务小组件')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: UpcomingTasksWidget(
            taskCount: 56,
            tasks: [
              TaskItem(title: 'Design mobile dashboard', color: Color(0xFF3B82F6)),
              TaskItem(title: 'Budget and contract', color: Color(0xFFEC4899)),
              TaskItem(title: 'Search for a UI kit', color: Color(0xFFFB923C)),
              TaskItem(title: 'Prepare HTML & CSS', color: Color(0xFF34D399)),
            ],
            moreCount: 10,
          ),
        ),
      ),
    );
  }
}
