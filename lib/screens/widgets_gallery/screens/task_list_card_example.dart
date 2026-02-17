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
        color: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF2F2F7),
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
                    child: TaskListCardWidget(
                      size: const SmallSize(),
                      icon: Icons.format_list_bulleted,
                      iconBackgroundColor: const Color(0xFF5A72EA),
                      count: 12,
                      countLabel: 'Tasks',
                      items: [
                        'Design UI',
                        'Budget',
                      ],
                      moreCount: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 200,
                    child: TaskListCardWidget(
                      size: const MediumSize(),
                      icon: Icons.format_list_bulleted,
                      iconBackgroundColor: const Color(0xFF5A72EA),
                      count: 24,
                      countLabel: 'Upcoming',
                      items: [
                        'Design mobile UI dashboard',
                        'Calculate budget',
                      ],
                      moreCount: 5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 280,
                    child: TaskListCardWidget(
                      size: const LargeSize(),
                      icon: Icons.format_list_bulleted,
                      iconBackgroundColor: const Color(0xFF5A72EA),
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
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 220,
                  child: TaskListCardWidget(
                    size: const WideSize(),
                    icon: Icons.format_list_bulleted,
                    iconBackgroundColor: const Color(0xFF5A72EA),
                    count: 36,
                    countLabel: 'Upcoming',
                    items: [
                      'Design mobile UI dashboard for client',
                      'Calculate budget and contract details',
                      'Search for a suitable UI kit',
                      'Create HTML & CSS for startup landing page',
                    ],
                    moreCount: 8,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 320,
                  child: TaskListCardWidget(
                    size: const Wide2Size(),
                    icon: Icons.format_list_bulleted,
                    iconBackgroundColor: const Color(0xFF5A72EA),
                    count: 64,
                    countLabel: 'Upcoming',
                    items: [
                      'Design mobile UI dashboard for client project',
                      'Calculate budget and contract details thoroughly',
                      'Search for a suitable UI kit library',
                      'Create HTML & CSS for startup landing page',
                      'Implement responsive design patterns',
                      'Write documentation for API endpoints',
                    ],
                    moreCount: 16,
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
