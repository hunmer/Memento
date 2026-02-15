import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/vertical_circular_progress_card.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/models/vertical_circular_progress_card_data.dart';

/// 睡眠追踪卡片示例
///
/// 展示如何使用 VerticalCircularProgressCard 公共小组件
class VerticalCircularProgressCardExample extends StatelessWidget {
  const VerticalCircularProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text('睡眠追踪卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('小尺寸 (1x1)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: VerticalCircularProgressCard(
                      data: VerticalCircularProgressCardData(
                        mainValue: 3.57,
                        statusLabel: 'Insomniac',
                        weeklyProgress: [
                          CircularProgressItemData(
                            day: 'M',
                            achieved: true,
                            progress: 1.0,
                          ),
                          CircularProgressItemData(
                            day: 'T',
                            achieved: false,
                            progress: 0.68,
                          ),
                          CircularProgressItemData(
                            day: 'W',
                            achieved: true,
                            progress: 1.0,
                          ),
                          CircularProgressItemData(
                            day: 'T',
                            achieved: true,
                            progress: 0.92,
                          ),
                          CircularProgressItemData(
                            day: 'F',
                            achieved: false,
                            progress: 0.6,
                          ),
                        ],
                      ),
                      size: const SmallSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸 (2x1)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: VerticalCircularProgressCard(
                      data: VerticalCircularProgressCardData(
                        mainValue: 7.12,
                        statusLabel: 'Excellent',
                        weeklyProgress: [
                          CircularProgressItemData(
                            day: 'Mon',
                            achieved: true,
                            progress: 1.0,
                          ),
                          CircularProgressItemData(
                            day: 'Tue',
                            achieved: true,
                            progress: 1.0,
                          ),
                          CircularProgressItemData(
                            day: 'Wed',
                            achieved: true,
                            progress: 0.92,
                          ),
                          CircularProgressItemData(
                            day: 'Thu',
                            achieved: true,
                            progress: 1.0,
                          ),
                          CircularProgressItemData(
                            day: 'Fri',
                            achieved: true,
                            progress: 1.0,
                          ),
                          CircularProgressItemData(
                            day: 'Sat',
                            achieved: true,
                            progress: 1.0,
                          ),
                        ],
                      ),
                      size: const MediumSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸 (2x2)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: VerticalCircularProgressCard(
                      data: VerticalCircularProgressCardData(
                        mainValue: 3.57,
                        statusLabel: 'Insomniac',
                        weeklyProgress: [
                          CircularProgressItemData(
                            day: 'Mon',
                            achieved: true,
                            progress: 1.0,
                          ),
                          CircularProgressItemData(
                            day: 'Tue',
                            achieved: false,
                            progress: 0.68,
                          ),
                          CircularProgressItemData(
                            day: 'Wed',
                            achieved: true,
                            progress: 1.0,
                          ),
                          CircularProgressItemData(
                            day: 'Thu',
                            achieved: true,
                            progress: 0.92,
                          ),
                          CircularProgressItemData(
                            day: 'Fri',
                            achieved: false,
                            progress: 0.6,
                          ),
                          CircularProgressItemData(
                            day: 'Sat',
                            achieved: false,
                            progress: 0.76,
                          ),
                          CircularProgressItemData(
                            day: 'Sun',
                            achieved: true,
                            progress: 1.0,
                          ),
                        ],
                      ),
                      size: const LargeSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸 (4x1)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: screenWidth - 32,
                    height: 220,
                    child: VerticalCircularProgressCard(
                      data: VerticalCircularProgressCardData(
                        mainValue: 6.45,
                        statusLabel: 'Good Sleep',
                        weeklyProgress: [
                          CircularProgressItemData(
                            day: 'Mon',
                            achieved: true,
                            progress: 0.88,
                          ),
                          CircularProgressItemData(
                            day: 'Tue',
                            achieved: true,
                            progress: 1.0,
                          ),
                          CircularProgressItemData(
                            day: 'Wed',
                            achieved: true,
                            progress: 0.95,
                          ),
                          CircularProgressItemData(
                            day: 'Thu',
                            achieved: true,
                            progress: 0.90,
                          ),
                          CircularProgressItemData(
                            day: 'Fri',
                            achieved: true,
                            progress: 1.0,
                          ),
                          CircularProgressItemData(
                            day: 'Sat',
                            achieved: true,
                            progress: 0.85,
                          ),
                          CircularProgressItemData(
                            day: 'Sun',
                            achieved: true,
                            progress: 0.92,
                          ),
                        ],
                      ),
                      size: const WideSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸 (4x2)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: screenWidth - 32,
                    height: 320,
                    child: VerticalCircularProgressCard(
                      data: VerticalCircularProgressCardData(
                        mainValue: 5.20,
                        statusLabel: 'Average Sleep',
                        weeklyProgress: [
                          CircularProgressItemData(
                            day: 'Monday',
                            achieved: true,
                            progress: 0.75,
                          ),
                          CircularProgressItemData(
                            day: 'Tuesday',
                            achieved: true,
                            progress: 0.80,
                          ),
                          CircularProgressItemData(
                            day: 'Wednesday',
                            achieved: false,
                            progress: 0.65,
                          ),
                          CircularProgressItemData(
                            day: 'Thursday',
                            achieved: true,
                            progress: 0.78,
                          ),
                          CircularProgressItemData(
                            day: 'Friday',
                            achieved: true,
                            progress: 0.82,
                          ),
                          CircularProgressItemData(
                            day: 'Saturday',
                            achieved: true,
                            progress: 0.90,
                          ),
                          CircularProgressItemData(
                            day: 'Sunday',
                            achieved: false,
                            progress: 0.70,
                          ),
                        ],
                      ),
                      size: const Wide2Size(),
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
