import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/curve_progress_card.dart';

/// 曲线进度卡片示例
class CurveProgressCardExample extends StatelessWidget {
  const CurveProgressCardExample({super.key});

  /// 示例数据点：时间使用趋势（最近7天）
  List<CurveDataPoint> get _timeUsageData => const [
    CurveDataPoint(value: 7200.0),
    CurveDataPoint(value: 7500.0),
    CurveDataPoint(value: 6800.0),
    CurveDataPoint(value: 8000.0),
    CurveDataPoint(value: 7800.0),
    CurveDataPoint(value: 8200.0),
    CurveDataPoint(value: 8524.0),
  ];

  /// 示例数据点：运动步数趋势
  List<CurveDataPoint> get _stepsData => const [
    CurveDataPoint(value: 4500.0),
    CurveDataPoint(value: 5200.0),
    CurveDataPoint(value: 4800.0),
    CurveDataPoint(value: 6000.0),
    CurveDataPoint(value: 5800.0),
    CurveDataPoint(value: 6500.0),
    CurveDataPoint(value: 7000.0),
  ];

  /// 示例数据点：简单上升趋势
  List<CurveDataPoint> get _trendData => const [
    CurveDataPoint(value: 100.0),
    CurveDataPoint(value: 150.0),
    CurveDataPoint(value: 130.0),
    CurveDataPoint(value: 200.0),
    CurveDataPoint(value: 250.0),
    CurveDataPoint(value: 220.0),
    CurveDataPoint(value: 300.0),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('曲线进度卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFEEF2F6),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('时间使用趋势 - 小尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: CurveProgressCardWidget(
                      size: const SmallSize(),
                      dataPoints: _timeUsageData,
                      unit: 'h',
                      icon: Icons.schedule,
                      categoryLabel: 'Time Usage',
                      lastUpdated: 'Updated 2h ago',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('运动步数趋势 - 中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: CurveProgressCardWidget(
                      size: const MediumSize(),
                      dataPoints: _stepsData,
                      unit: 'steps',
                      icon: Icons.directions_walk,
                      categoryLabel: 'Steps',
                      lastUpdated: 'Updated 2h ago',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('数据趋势 - 大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: CurveProgressCardWidget(
                      size: const LargeSize(),
                      dataPoints: _trendData,
                      unit: 'units',
                      icon: Icons.trending_up,
                      categoryLabel: 'Trend',
                      lastUpdated: 'Updated 2h ago',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('健康监测 - 中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 220,
                  child: CurveProgressCardWidget(
                    size: const WideSize(),
                    dataPoints: _stepsData,
                    unit: 'steps',
                    icon: Icons.favorite,
                    categoryLabel: 'Heart Rate',
                    lastUpdated: 'Updated 5m ago',
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('学习进度 - 大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 320,
                  child: CurveProgressCardWidget(
                    size: const Wide2Size(),
                    dataPoints: _timeUsageData,
                    unit: 'h',
                    icon: Icons.school,
                    categoryLabel: 'Learning Progress',
                    lastUpdated: 'Updated 1h ago',
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
