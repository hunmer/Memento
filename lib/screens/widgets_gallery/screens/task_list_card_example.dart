import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/task_list_card.dart';

/// 任务列表卡片示例
class TaskListCardExample extends StatelessWidget {
  const TaskListCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('任务列表卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: TaskListCardWidget(
            size: HomeWidgetSize.large,
            icon: Icons.format_list_bulleted,
            iconBackgroundColor: Color(0xFF5A72EA),
            count: 48,
            countLabel: 'Upcoming',
            items: [
              'Design mobile UI dashboard',
              'Calculate budget and contract',
              'Search for a UI kit',
              'Create HTML & CSS for startup',
            ],
            moreCount: 10,
          ),
        ),
      ),
    );
  }
}
