import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/models/color_tag_task_card_data.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/color_tag_task_card.dart';

/// 彩色标签任务列表卡片示例
class ColorTagTaskCardExample extends StatelessWidget {
  const ColorTagTaskCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('彩色标签任务列表卡片')),
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
                    child: ColorTagTaskCardWidget(
                      size: const SmallSize(),
                      data: const ColorTagTaskCardData(
                        taskCount: 56,
                        label: 'Upcoming tasks',
                        tasks: [
                          ColorTagTaskItem(
                            title: 'Design mobile UI dashboard for iOS',
                            color: 0xFF3B82F6,
                            tag: 'Design',
                          ),
                          ColorTagTaskItem(
                            title: 'Calculate budget and contract',
                            color: 0xFFFB7185,
                            tag: 'Finance',
                          ),
                          ColorTagTaskItem(
                            title: 'Search for a UI kit',
                            color: 0xFFFBBF24,
                            tag: 'Research',
                          ),
                          ColorTagTaskItem(
                            title: 'Create HTML & CSS for startup',
                            color: 0xFF3B82F6,
                            tag: 'Dev',
                          ),
                          ColorTagTaskItem(
                            title: 'Design search page for website',
                            color: 0xFF34D399,
                            tag: 'Design',
                          ),
                          ColorTagTaskItem(
                            title: 'Send an estimate budget for app',
                            color: 0xFFFB7185,
                            tag: 'Finance',
                          ),
                          ColorTagTaskItem(
                            title: 'Search for a mobile UI kit',
                            color: 0xFFFBBF24,
                            tag: 'Research',
                          ),
                          ColorTagTaskItem(
                            title: 'Export assets for HTML developer',
                            color: 0xFF3B82F6,
                            tag: 'Dev',
                          ),
                        ],
                        moreCount: 10,
                      ),
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
                    child: ColorTagTaskCardWidget(
                      size: const MediumSize(),
                      data: const ColorTagTaskCardData(
                        taskCount: 56,
                        label: 'Upcoming tasks',
                        tasks: [
                          ColorTagTaskItem(
                            title: 'Design mobile UI dashboard for iOS',
                            color: 0xFF3B82F6,
                            tag: 'Design',
                          ),
                          ColorTagTaskItem(
                            title: 'Calculate budget and contract',
                            color: 0xFFFB7185,
                            tag: 'Finance',
                          ),
                          ColorTagTaskItem(
                            title: 'Search for a UI kit',
                            color: 0xFFFBBF24,
                            tag: 'Research',
                          ),
                          ColorTagTaskItem(
                            title: 'Create HTML & CSS for startup',
                            color: 0xFF3B82F6,
                            tag: 'Dev',
                          ),
                          ColorTagTaskItem(
                            title: 'Design search page for website',
                            color: 0xFF34D399,
                            tag: 'Design',
                          ),
                          ColorTagTaskItem(
                            title: 'Send an estimate budget for app',
                            color: 0xFFFB7185,
                            tag: 'Finance',
                          ),
                          ColorTagTaskItem(
                            title: 'Search for a mobile UI kit',
                            color: 0xFFFBBF24,
                            tag: 'Research',
                          ),
                          ColorTagTaskItem(
                            title: 'Export assets for HTML developer',
                            color: 0xFF3B82F6,
                            tag: 'Dev',
                          ),
                        ],
                        moreCount: 10,
                      ),
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
                    child: ColorTagTaskCardWidget(
                      size: const LargeSize(),
                      data: const ColorTagTaskCardData(
                        taskCount: 56,
                        label: 'Upcoming tasks',
                        tasks: [
                          ColorTagTaskItem(
                            title: 'Design mobile UI dashboard for iOS',
                            color: 0xFF3B82F6,
                            tag: 'Design',
                          ),
                          ColorTagTaskItem(
                            title: 'Calculate budget and contract',
                            color: 0xFFFB7185,
                            tag: 'Finance',
                          ),
                          ColorTagTaskItem(
                            title: 'Search for a UI kit',
                            color: 0xFFFBBF24,
                            tag: 'Research',
                          ),
                          ColorTagTaskItem(
                            title: 'Create HTML & CSS for startup',
                            color: 0xFF3B82F6,
                            tag: 'Dev',
                          ),
                          ColorTagTaskItem(
                            title: 'Design search page for website',
                            color: 0xFF34D399,
                            tag: 'Design',
                          ),
                          ColorTagTaskItem(
                            title: 'Send an estimate budget for app',
                            color: 0xFFFB7185,
                            tag: 'Finance',
                          ),
                          ColorTagTaskItem(
                            title: 'Search for a mobile UI kit',
                            color: 0xFFFBBF24,
                            tag: 'Research',
                          ),
                          ColorTagTaskItem(
                            title: 'Export assets for HTML developer',
                            color: 0xFF3B82F6,
                            tag: 'Dev',
                          ),
                        ],
                        moreCount: 10,
                      ),
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
