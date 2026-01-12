import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/index.dart';

/// 屏幕时间统计图表示例
class ScreenTimeChartExample extends StatelessWidget {
  const ScreenTimeChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('屏幕时间统计图表')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: ScreenTimeChartCardWidget(
            avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCXQvcX8rQqhqCmwdBavY1gogXgYogija-OQqrGPWMkNVRdTOXp3y09ywNdXnQiGCc-P4vDokR0EZuET3x_sFa8qkqVhUpYHrWbT5jEY-aUWA34HMs4jtlKdSs0s6TB5--o6B_1AUgdLlDjW3KWwos7Uq1FMEoipxOcxwEdd-V7Wsw78Oeu4kFEXKYwWqXUDSvXMHj8JjfX43Aj-t5Y90q6IzW8MRV1XPJ0euk9I5-2nURrj6HlqacrDBWNexqUb4DBJPJPVFeGDw',
            totalHours: 2,
            totalMinutes: 43,
            dataPoints: [
              ScreenTimeDataPoint(
                timeLabel: '6 AM',
                segments: [
                  ScreenTimeSegment(category: 'blue', percentage: 0.85),
                  ScreenTimeSegment(category: 'teal', percentage: 0.15),
                ],
                heightPercentage: 0.35,
              ),
              ScreenTimeDataPoint(
                timeLabel: '',
                segments: [
                  ScreenTimeSegment(category: 'blue', percentage: 0.60),
                  ScreenTimeSegment(category: 'teal', percentage: 0.10),
                  ScreenTimeSegment(category: 'orange', percentage: 0.05),
                  ScreenTimeSegment(category: 'gray', percentage: 0.25),
                ],
                heightPercentage: 0.45,
              ),
              ScreenTimeDataPoint(
                timeLabel: '12 PM',
                segments: [
                  ScreenTimeSegment(category: 'blue', percentage: 0.40),
                  ScreenTimeSegment(category: 'teal', percentage: 0.20),
                  ScreenTimeSegment(category: 'orange', percentage: 0.15),
                  ScreenTimeSegment(category: 'gray', percentage: 0.25),
                ],
                heightPercentage: 0.80,
              ),
              ScreenTimeDataPoint(
                timeLabel: '',
                segments: [
                  ScreenTimeSegment(category: 'blue', percentage: 0.30),
                  ScreenTimeSegment(category: 'teal', percentage: 0.25),
                  ScreenTimeSegment(category: 'orange', percentage: 0.20),
                  ScreenTimeSegment(category: 'gray', percentage: 0.25),
                ],
                heightPercentage: 0.70,
              ),
              ScreenTimeDataPoint(
                timeLabel: '',
                segments: [
                  ScreenTimeSegment(category: 'blue', percentage: 0.50),
                  ScreenTimeSegment(category: 'teal', percentage: 0.20),
                  ScreenTimeSegment(category: 'orange', percentage: 0.15),
                  ScreenTimeSegment(category: 'gray', percentage: 0.15),
                ],
                heightPercentage: 0.30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
