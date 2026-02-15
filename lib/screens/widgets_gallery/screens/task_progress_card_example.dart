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
                      size: const SmallSize(),
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
                      size: const MediumSize(),
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
                      size: const LargeSize(),
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
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: TaskProgressCardWidget(
                    size: const WideSize(),
                    title: 'Widgefy UI Kit - Project Progress',
                    subtitle: 'Graphics design and development',
                    completedTasks: 7,
                    totalTasks: 14,
                    pendingTasks: [
                      'Design search page for website',
                      'Send an estimate budget for app',
                      'Export assets for HTML developer',
                      'Review design specifications',
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: TaskProgressCardWidget(
                    size: const Wide2Size(),
                    title: 'Widgefy UI Kit - Complete Project Overview',
                    subtitle: 'Graphics design and development project management',
                    completedTasks: 7,
                    totalTasks: 14,
                    pendingTasks: [
                      'Design search page for website',
                      'Send an estimate budget for app',
                      'Export assets for HTML developer',
                      'Review design specifications',
                      'Update project timeline',
                      'Coordinate with development team',
                    ],
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
