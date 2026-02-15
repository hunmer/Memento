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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('小尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: UpcomingTasksWidget(
                      taskCount: 56,
                      tasks: [
                        TaskItem(title: 'Design mobile dashboard', color: const Color(0xFF3B82F6)),
                        TaskItem(title: 'Budget and contract', color: const Color(0xFFEC4899)),
                        TaskItem(title: 'Search for a UI kit', color: const Color(0xFFFB923C)),
                        TaskItem(title: 'Prepare HTML & CSS', color: const Color(0xFF34D399)),
                      ],
                      moreCount: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: UpcomingTasksWidget(
                      taskCount: 56,
                      tasks: [
                        TaskItem(title: 'Design mobile dashboard', color: const Color(0xFF3B82F6)),
                        TaskItem(title: 'Budget and contract', color: const Color(0xFFEC4899)),
                        TaskItem(title: 'Search for a UI kit', color: const Color(0xFFFB923C)),
                        TaskItem(title: 'Prepare HTML & CSS', color: const Color(0xFF34D399)),
                      ],
                      moreCount: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: UpcomingTasksWidget(
                      taskCount: 56,
                      tasks: [
                        TaskItem(title: 'Design mobile dashboard', color: const Color(0xFF3B82F6)),
                        TaskItem(title: 'Budget and contract', color: const Color(0xFFEC4899)),
                        TaskItem(title: 'Search for a UI kit', color: const Color(0xFFFB923C)),
                        TaskItem(title: 'Prepare HTML & CSS', color: const Color(0xFF34D399)),
                      ],
                      moreCount: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      ),
    );
  }
}
