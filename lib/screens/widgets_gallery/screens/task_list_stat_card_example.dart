import 'package:flutter/material.dart';
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
                      primaryColor: const Color(0xFF5A72EA),
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
                      primaryColor: const Color(0xFF5A72EA),
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
                      primaryColor: const Color(0xFF5A72EA),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: TaskListStatCardWidget(
                    icon: Icons.format_list_bulleted,
                    count: 48,
                    statusLabel: 'Upcoming Tasks',
                    tasks: [
                      'Design mobile UI dashboard',
                      'Calculate budget and contract',
                      'Search for a UI kit',
                      'Create HTML & CSS for startup',
                      'Review project timeline',
                    ],
                    remainingCount: 10,
                    primaryColor: const Color(0xFF5A72EA),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: TaskListStatCardWidget(
                    icon: Icons.format_list_bulleted,
                    count: 48,
                    statusLabel: 'Upcoming Tasks Overview',
                    tasks: [
                      'Design mobile UI dashboard - Widgefy',
                      'Calculate budget and contract - BetaCRM',
                      'Search for a UI kit - Cardify',
                      'Create HTML & CSS for startup - Roomsfy',
                      'Review project timeline and milestones',
                      'Update documentation and specs',
                    ],
                    remainingCount: 10,
                    primaryColor: const Color(0xFF5A72EA),
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
