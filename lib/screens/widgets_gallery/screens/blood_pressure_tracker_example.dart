import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/index.dart';

/// 血压追踪器组件示例
///
/// 展示如何使用 DualValueTrackerCard 组件来显示血压数据
class BloodPressureTrackerExample extends StatelessWidget {
  const BloodPressureTrackerExample({super.key});

  @override
  Widget build(BuildContext context) {
    // 血压数据配置
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('血压追踪器'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Center(
        child: DualValueTrackerCard(
          title: 'Blood Pressure',
          primaryValue: 128, // 收缩压
          secondaryValue: 80, // 舒张压
          status: 'Stable Range',
          unit: 'mmHg',
          icon: Icons.water_drop,
          weekData: weekData,
        ),
      ),
    );
  }
}
