import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/multi_metric_progress_card.dart';

/// 多指标进度卡片示例
class MultiMetricProgressCardExample extends StatelessWidget {
  const MultiMetricProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('多指标进度卡片')),
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
                    height: 200,
                    child: MultiMetricProgressCardWidget(
                      trackers: const [
                        MetricProgressData(
                          emoji: '🐱',
                          progress: 88.0,
                          progressColor: Color(0xFFFFD60A),
                          title: "Peach's Life",
                          subtitle: 'July 21, 2019',
                          value: 0.88,
                          unit: 'years old',
                        ),
                      ],
                      size: const SmallSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 250,
                    child: MultiMetricProgressCardWidget(
                      trackers: const [
                        MetricProgressData(
                          emoji: '🐱',
                          progress: 88.0,
                          progressColor: Color(0xFFFFD60A),
                          title: "Peach's Life",
                          subtitle: 'July 21, 2019 • 321 days',
                          value: 0.88,
                          unit: 'years old',
                        ),
                        MetricProgressData(
                          emoji: '📅',
                          progress: 71.23,
                          progressColor: Color(0xFFFFD60A),
                          title: '2020 Progress',
                          subtitle: '157d/366d',
                          value: 71.23,
                          unit: '%',
                        ),
                      ],
                      size: const MediumSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 350,
                    height: 320,
                    child: MultiMetricProgressCardWidget(
                      trackers: const [
                        MetricProgressData(
                          emoji: '🐱',
                          progress: 88.0,
                          progressColor: Color(0xFFFFD60A),
                          title: "Peach's Life",
                          subtitle: 'July 21, 2019 • 321 days',
                          value: 0.88,
                          unit: 'years old',
                        ),
                        MetricProgressData(
                          emoji: '📅',
                          progress: 71.23,
                          progressColor: Color(0xFFFFD60A),
                          title: '2020 Progress',
                          subtitle: '157d/366d • Passed',
                          value: 71.23,
                          unit: '%',
                        ),
                        MetricProgressData(
                          emoji: '🏡',
                          progress: 65.5,
                          progressColor: Color(0xFF34C759),
                          title: 'Work from home',
                          subtitle: 'Jan 22, 2020',
                          value: 239,
                          unit: 'days',
                        ),
                      ],
                      size: const LargeSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: MultiMetricProgressCardWidget(
                    trackers: const [
                      MetricProgressData(
                        emoji: '🐱',
                        progress: 88.0,
                        progressColor: Color(0xFFFFD60A),
                        title: "Peach's Life Journey",
                        subtitle: 'July 21, 2019 • 321 days',
                        value: 0.88,
                        unit: 'years old',
                      ),
                      MetricProgressData(
                        emoji: '📅',
                        progress: 71.23,
                        progressColor: Color(0xFFFFD60A),
                        title: '2020 Annual Progress',
                        subtitle: '157d/366d • Passed',
                        value: 71.23,
                        unit: '%',
                      ),
                      MetricProgressData(
                        emoji: '🏡',
                        progress: 65.5,
                        progressColor: Color(0xFF34C759),
                        title: 'Work from home',
                        subtitle: 'Jan 22, 2020 • Remote Work',
                        value: 239,
                        unit: 'days',
                      ),
                    ],
                    size: const WideSize(),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 450,
                  child: MultiMetricProgressCardWidget(
                    trackers: const [
                      MetricProgressData(
                        emoji: '🐱',
                        progress: 88.0,
                        progressColor: Color(0xFFFFD60A),
                        title: "Peach's Life Journey and Milestones",
                        subtitle: 'July 21, 2019 • 321 days',
                        value: 0.88,
                        unit: 'years old',
                      ),
                      MetricProgressData(
                        emoji: '📅',
                        progress: 71.23,
                        progressColor: Color(0xFFFFD60A),
                        title: '2020 Annual Progress Tracking',
                        subtitle: '157d/366d • Passed',
                        value: 71.23,
                        unit: '%',
                      ),
                      MetricProgressData(
                        emoji: '🏡',
                        progress: 65.5,
                        progressColor: Color(0xFF34C759),
                        title: 'Work from home Statistics',
                        subtitle: 'Jan 22, 2020 • Remote Work Tracking',
                        value: 239,
                        unit: 'days',
                      ),
                    ],
                    size: const Wide2Size(),
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
