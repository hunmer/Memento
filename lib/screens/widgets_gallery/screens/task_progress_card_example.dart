import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
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
                    child: TaskProgressCardWidget(
                      size: HomeWidgetSize.small,
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
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: TaskProgressCardWidget(
                      size: HomeWidgetSize.medium,
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
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: TaskProgressCardWidget(
                      size: HomeWidgetSize.large,
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
