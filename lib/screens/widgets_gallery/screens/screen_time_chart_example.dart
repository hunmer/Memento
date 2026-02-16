import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/screen_time_chart_card.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // SmallSize (1x1)
              _buildSizeCard(
                context,
                'SmallSize (1x1)',
                const SmallSize(),
                isDark,
                150,
                150,
              ),
              const SizedBox(height: 16),

              // MediumSize (2x1)
              _buildSizeCard(
                context,
                'MediumSize (2x1)',
                const MediumSize(),
                isDark,
                220,
                220,
              ),
              const SizedBox(height: 16),

              // LargeSize (2x2)
              _buildSizeCard(
                context,
                'LargeSize (2x2)',
                const LargeSize(),
                isDark,
                300,
                300,
              ),
              const SizedBox(height: 16),

              // WideSize (4x1) - 宽度填满屏幕
              _buildWideCard(
                context,
                'WideSize (4x1)',
                const WideSize(),
                isDark,
                280,
              ),
              const SizedBox(height: 16),

              // Wide2Size (4x2) - 宽度填满屏幕
              _buildWideCard(
                context,
                'Wide2Size (4x2)',
                const Wide2Size(),
                isDark,
                350,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSizeCard(
    BuildContext context,
    String label,
    HomeWidgetSize size,
    bool isDark,
    double height,
    double? width,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: width,
          height: height,
          child: ScreenTimeChartCardWidget(
            avatarUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCXQvcX8rQqhqCmwdBavY1gogXgYogija-OQqrGPWMkNVRdTOXp3y09ywNdXnQiGCc-P4vDokR0EZuET3x_sFa8qkqVhUpYHrWbT5jEY-aUWA34HMs4jtlKdSs0s6TB5--o6B_1AUgdLlDjW3KWwos7Uq1FMEoipxOcxwEdd-V7Wsw78Oeu4kFEXKYwWqXUDSvXMHj8JjfX43Aj-t5Y90q6IzW8MRV1XPJ0euk9I5-2nURrj6HlqacrDBWNexqUb4DBJPJPVFeGDw',
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
            size: size,
          ),
        ),
      ],
    );
  }

  Widget _buildWideCard(
    BuildContext context,
    String label,
    HomeWidgetSize size,
    bool isDark,
    double height,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth - 32;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: cardWidth,
          height: height,
          child: ScreenTimeChartCardWidget(
            avatarUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCXQvcX8rQqhqCmwdBavY1gogXgYogija-OQqrGPWMkNVRdTOXp3y09ywNdXnQiGCc-P4vDokR0EZuET3x_sFa8qkqVhUpYHrWbT5jEY-aUWA34HMs4jtlKdSs0s6TB5--o6B_1AUgdLlDjW3KWwos7Uq1FMEoipxOcxwEdd-V7Wsw78Oeu4kFEXKYwWqXUDSvXMHj8JjfX43Aj-t5Y90q6IzW8MRV1XPJ0euk9I5-2nURrj6HlqacrDBWNexqUb4DBJPJPVFeGDw',
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
              ScreenTimeDataPoint(
                timeLabel: '6 PM',
                segments: [
                  ScreenTimeSegment(category: 'blue', percentage: 0.55),
                  ScreenTimeSegment(category: 'teal', percentage: 0.20),
                  ScreenTimeSegment(category: 'orange', percentage: 0.15),
                  ScreenTimeSegment(category: 'gray', percentage: 0.10),
                ],
                heightPercentage: 0.50,
              ),
              ScreenTimeDataPoint(
                timeLabel: '',
                segments: [
                  ScreenTimeSegment(category: 'blue', percentage: 0.40),
                  ScreenTimeSegment(category: 'teal', percentage: 0.30),
                  ScreenTimeSegment(category: 'orange', percentage: 0.15),
                  ScreenTimeSegment(category: 'gray', percentage: 0.15),
                ],
                heightPercentage: 0.35,
              ),
            ],
            size: size,
          ),
        ),
      ],
    );
  }
}
