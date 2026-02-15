import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/index.dart';

/// 血压追踪器组件示例
class BloodPressureTrackerExample extends StatelessWidget {
  const BloodPressureTrackerExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final weekData = [
      WeekData(label: 'M', normalPercent: 0.60, elevatedPercent: 0.20),
      WeekData(label: 'T', normalPercent: 0.70, elevatedPercent: 0.30),
      WeekData(label: 'W', normalPercent: 0.50, elevatedPercent: 0.20),
      WeekData(label: 'T', normalPercent: 0.85, elevatedPercent: 0.25),
      WeekData(label: 'F', normalPercent: 0.90, elevatedPercent: 0.25),
      WeekData(label: 'S', normalPercent: 0.80, elevatedPercent: 0.20),
      WeekData(label: 'S', normalPercent: 0.65, elevatedPercent: 0.20),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('血压追踪器')),
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
                    child: DualValueTrackerCard(
                      title: 'Blood Pressure',
                      primaryValue: 128,
                      secondaryValue: 80,
                      status: 'Stable Range',
                      unit: 'mmHg',
                      icon: Icons.water_drop,
                      weekData: weekData,
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
                    child: DualValueTrackerCard(
                      title: 'Blood Pressure',
                      primaryValue: 128,
                      secondaryValue: 80,
                      status: 'Stable Range',
                      unit: 'mmHg',
                      icon: Icons.water_drop,
                      weekData: weekData,
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
                    child: DualValueTrackerCard(
                      title: 'Blood Pressure',
                      primaryValue: 128,
                      secondaryValue: 80,
                      status: 'Stable Range',
                      unit: 'mmHg',
                      icon: Icons.water_drop,
                      weekData: weekData,
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
