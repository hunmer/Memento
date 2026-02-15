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
                    child: TaskProgressListWidget(
                      tasks: [
                        TaskProgressData(
                          title: 'Design mobile UI dashboard',
                          time: '24 mins ago',
                          progress: 1.0,
                          color: Color(0xFF34D399),
                        ),
                        TaskProgressData(
                          title: 'Calculate budget',
                          time: '54 mins ago',
                          progress: 0.67,
                          color: Color(0xFFFBBF24),
                        ),
                        TaskProgressData(
                          title: 'Search for UI kit',
                          time: '54 mins ago',
                          progress: 1.0,
                          color: Color(0xFF34D399),
                        ),
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
                          title: 'Design search page',
                          time: '54 mins ago',
                          progress: 0.25,
                          color: Color(0xFFFB7185),
                        ),
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
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
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
                    ],
                    moreCount: 10,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
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
