import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/index.dart';

/// 每周步数进度卡片示例
class WeeklyStepsProgressCardExample extends StatelessWidget {
  const WeeklyStepsProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('每周步数进度卡片')),
      body: Container(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E5E5),
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
                    child: WeeklyStepsProgressCard(
                      title: 'Steps',
                      totalSteps: 16254,
                      dateRange: '17-23 Jun 2024',
                      averageSteps: 6028,
                      dailyData: [
                        DailyStepData(
                          day: 'Mon',
                          steps: 4500,
                          date: '17 Jun 2024',
                        ),
                        DailyStepData(
                          day: 'Tue',
                          steps: 6200,
                          date: '18 Jun 2024',
                        ),
                        DailyStepData(
                          day: 'Wed',
                          steps: 3800,
                          date: '19 Jun 2024',
                        ),
                        DailyStepData(
                          day: 'Thu',
                          steps: 7800,
                          date: '20 Jun 2024',
                        ),
                        DailyStepData(
                          day: 'Fri',
                          steps: 12800,
                          date: '21 Jun 2024',
                          percentage: '+2,4%',
                          isSelected: true,
                        ),
                        DailyStepData(
                          day: 'Sat',
                          steps: 9600,
                          date: '22 Jun 2024',
                        ),
                        DailyStepData(
                          day: 'Sun',
                          steps: 7200,
                          date: '23 Jun 2024',
                        ),
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
                    child: WeeklyStepsProgressCard(
                      title: 'Steps',
                      totalSteps: 16254,
                      dateRange: '17-23 Jun 2024',
                      averageSteps: 6028,
                      dailyData: [
                        DailyStepData(
                          day: 'Mon',
                          steps: 4500,
                          date: '17 Jun 2024',
                        ),
                        DailyStepData(
                          day: 'Tue',
                          steps: 6200,
                          date: '18 Jun 2024',
                        ),
                        DailyStepData(
                          day: 'Wed',
                          steps: 3800,
                          date: '19 Jun 2024',
                        ),
                        DailyStepData(
                          day: 'Thu',
                          steps: 7800,
                          date: '20 Jun 2024',
                        ),
                        DailyStepData(
                          day: 'Fri',
                          steps: 12800,
                          date: '21 Jun 2024',
                          percentage: '+2,4%',
                          isSelected: true,
                        ),
                        DailyStepData(
                          day: 'Sat',
                          steps: 9600,
                          date: '22 Jun 2024',
                        ),
                        DailyStepData(
                          day: 'Sun',
                          steps: 7200,
                          date: '23 Jun 2024',
                        ),
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
                    child: WeeklyStepsProgressCard(
                      title: 'Steps',
                      totalSteps: 16254,
                      dateRange: '17-23 Jun 2024',
                      averageSteps: 6028,
                      dailyData: [
                        DailyStepData(
                          day: 'Mon',
                          steps: 4500,
                          date: '17 Jun 2024',
                        ),
                        DailyStepData(
                          day: 'Tue',
                          steps: 6200,
                          date: '18 Jun 2024',
                        ),
                        DailyStepData(
                          day: 'Wed',
                          steps: 3800,
                          date: '19 Jun 2024',
                        ),
                        DailyStepData(
                          day: 'Thu',
                          steps: 7800,
                          date: '20 Jun 2024',
                        ),
                        DailyStepData(
                          day: 'Fri',
                          steps: 12800,
                          date: '21 Jun 2024',
                          percentage: '+2,4%',
                          isSelected: true,
                        ),
                        DailyStepData(
                          day: 'Sat',
                          steps: 9600,
                          date: '22 Jun 2024',
                        ),
                        DailyStepData(
                          day: 'Sun',
                          steps: 7200,
                          date: '23 Jun 2024',
                        ),
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
