import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/stacked_ring_chart_card.dart';

/// 堆叠环形图统计卡片示例
class StackedRingChartExample extends StatelessWidget {
  const StackedRingChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('堆叠环形图统计卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFE0E5EC),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('小尺寸 (SmallSize)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: StackedRingChartCardWidget(
                      size: const SmallSize(),
                      segments: [
                        RingSegmentData(
                          label: 'Docs',
                          value: 30,
                          color: Color(0xFF0B1556),
                        ),
                        RingSegmentData(
                          label: 'Videos',
                          value: 50,
                          color: Color(0xFF00A9CE),
                        ),
                      ],
                      total: 100,
                      title: 'Storage',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸 (MediumSize)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: StackedRingChartCardWidget(
                      size: const MediumSize(),
                      segments: [
                        RingSegmentData(
                          label: 'Documents',
                          value: 30,
                          color: Color(0xFF0B1556),
                        ),
                        RingSegmentData(
                          label: 'Videos',
                          value: 80,
                          color: Color(0xFF00A9CE),
                        ),
                        RingSegmentData(
                          label: 'Photos',
                          value: 50,
                          color: Color(0xFF00649F),
                        ),
                      ],
                      total: 160,
                      title: 'Storage',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸 (LargeSize)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: StackedRingChartCardWidget(
                      size: const LargeSize(),
                      segments: [
                        RingSegmentData(
                          label: 'Documents',
                          value: 30,
                          color: Color(0xFF0B1556),
                        ),
                        RingSegmentData(
                          label: 'Videos',
                          value: 80,
                          color: Color(0xFF00A9CE),
                        ),
                        RingSegmentData(
                          label: 'Photos',
                          value: 50,
                          color: Color(0xFF00649F),
                        ),
                        RingSegmentData(
                          label: 'Music',
                          value: 60,
                          color: Color(0xFF8AD6E9),
                        ),
                      ],
                      total: 220,
                      title: 'Storage of your device',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸 (WideSize)'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: StackedRingChartCardWidget(
                    size: const WideSize(),
                    segments: [
                      RingSegmentData(
                        label: 'Documents',
                        value: 40,
                        color: Color(0xFF0B1556),
                      ),
                      RingSegmentData(
                        label: 'Videos',
                        value: 100,
                        color: Color(0xFF00A9CE),
                      ),
                      RingSegmentData(
                        label: 'Photos',
                        value: 80,
                        color: Color(0xFF00649F),
                      ),
                      RingSegmentData(
                        label: 'Music',
                        value: 70,
                        color: Color(0xFF8AD6E9),
                      ),
                    ],
                    total: 290,
                    title: 'Device Storage Overview',
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸 (Wide2Size)'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: StackedRingChartCardWidget(
                    size: const Wide2Size(),
                    segments: [
                      RingSegmentData(
                        label: 'Documents',
                        value: 50,
                        color: Color(0xFF0B1556),
                      ),
                      RingSegmentData(
                        label: 'Videos',
                        value: 155,
                        color: Color(0xFF00A9CE),
                      ),
                      RingSegmentData(
                        label: 'Photos',
                        value: 120,
                        color: Color(0xFF00649F),
                      ),
                      RingSegmentData(
                        label: 'Music',
                        value: 90,
                        color: Color(0xFF8AD6E9),
                      ),
                      RingSegmentData(
                        label: 'Apps',
                        value: 60,
                        color: Color(0xFF4CAF50),
                      ),
                    ],
                    total: 475,
                    title: 'Complete Device Storage Analysis',
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
