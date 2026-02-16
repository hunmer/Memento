import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/smooth_line_chart_card.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 平滑曲线图表卡片示例（汽车统计风格）
class SmoothLineChartCardExample extends StatelessWidget {
  const SmoothLineChartCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('平滑曲线图表卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('小尺寸'),
              const SizedBox(height: 8),
              Center(
                child: SizedBox(
                  width: 150,
                  height: 200,
                  child: SmoothLineChartCardWidget(
                    title: '汽车',
                    subtitle: '统计',
                    date: '2022年2月20日',
                    size: const SmallSize(),
                    dataPoints: _dataPoints,
                    maxValue: 150,
                    timeLabels: _timeLabels,
                    primaryColor: const Color(0xFFFF7F56),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('中尺寸'),
              const SizedBox(height: 8),
              Center(
                child: SizedBox(
                  width: 340,
                  height: 280,
                  child: SmoothLineChartCardWidget(
                    title: '汽车',
                    subtitle: '统计',
                    date: '2022年2月20日',
                    size: const MediumSize(),
                    dataPoints: _dataPoints,
                    maxValue: 150,
                    timeLabels: _timeLabels,
                    primaryColor: const Color(0xFFFF7F56),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('大尺寸'),
              const SizedBox(height: 8),
              Center(
                child: SizedBox(
                  width: 340,
                  height: 400,
                  child: SmoothLineChartCardWidget(
                    title: '汽车',
                    subtitle: '统计',
                    date: '2022年2月20日',
                    size: const LargeSize(),
                    dataPoints: _dataPoints,
                    maxValue: 150,
                    timeLabels: _timeLabels,
                    primaryColor: const Color(0xFFFF7F56),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('中宽尺寸'),
              const SizedBox(height: 8),
              SizedBox(
                width: MediaQuery.of(context).size.width - 32,
                height: 280,
                child: SmoothLineChartCardWidget(
                  title: '汽车',
                  subtitle: '统计',
                  date: '2022年2月20日',
                  size: const WideSize(),
                  dataPoints: _dataPoints,
                  maxValue: 150,
                  timeLabels: _timeLabels,
                  primaryColor: const Color(0xFFFF7F56),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('大宽尺寸'),
              const SizedBox(height: 8),
              SizedBox(
                width: MediaQuery.of(context).size.width - 32,
                height: 400,
                child: SmoothLineChartCardWidget(
                  title: '汽车',
                  subtitle: '统计',
                  date: '2022年2月20日',
                  size: const Wide2Size(),
                  dataPoints: _dataPoints,
                  maxValue: 150,
                  timeLabels: _timeLabels,
                  primaryColor: const Color(0xFFFF7F56),
                ),
              ),
            ],
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

const _dataPoints = [
  DataPoint(x: 0, y: 80),
  DataPoint(x: 50, y: 50),
  DataPoint(x: 100, y: 10),
  DataPoint(x: 150, y: 60),
  DataPoint(x: 200, y: 80),
  DataPoint(x: 250, y: 110),
  DataPoint(x: 300, y: 110),
  DataPoint(x: 350, y: 80),
];

const _timeLabels = [
  '7 am',
  '9 am',
  '11 am',
  '1 pm',
  '3 pm',
  '5 pm',
  '7 pm',
  '9 pm',
];
