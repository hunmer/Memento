import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/circular_metrics_card.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 环形指标卡片示例
class CircularMetricsCardExample extends StatelessWidget {
  const CircularMetricsCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('环形指标卡片')),
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
                    child: CircularMetricsCardWidget(
                      title: 'Overview',
                      metrics: const [
                        MetricData(
                          icon: Icons.person,
                          value: '12d 23hrs',
                          label: 'To complete',
                          progress: 0.75,
                          color: Color(0xFF34D399),
                        ),
                        MetricData(
                          icon: Icons.pets,
                          value: '24',
                          label: 'Team',
                          progress: 0.60,
                          color: Color(0xFFFB7185),
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
                    height: 220,
                    child: CircularMetricsCardWidget(
                      title: 'Overview',
                      metrics: const [
                        MetricData(
                          icon: Icons.person,
                          value: '12d 23hrs',
                          label: 'To complete',
                          progress: 0.75,
                          color: Color(0xFF34D399),
                        ),
                        MetricData(
                          icon: Icons.pets,
                          value: '24',
                          label: 'Team',
                          progress: 0.60,
                          color: Color(0xFFFB7185),
                        ),
                        MetricData(
                          icon: Icons.savings,
                          value: '20.5k',
                          label: 'Budget left',
                          progress: 0.40,
                          color: Color(0xFFFBBF24),
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
                    width: 300,
                    height: 300,
                    child: CircularMetricsCardWidget(
                      title: 'Overview',
                      metrics: const [
                        MetricData(
                          icon: Icons.person,
                          value: '12d 23hrs',
                          label: 'To complete',
                          progress: 0.75,
                          color: Color(0xFF34D399),
                        ),
                        MetricData(
                          icon: Icons.pets,
                          value: '24',
                          label: 'Team',
                          progress: 0.60,
                          color: Color(0xFFFB7185),
                        ),
                        MetricData(
                          icon: Icons.savings,
                          value: '20.5k',
                          label: 'Budget left',
                          progress: 0.40,
                          color: Color(0xFFFBBF24),
                        ),
                        MetricData(
                          icon: Icons.inventory_2,
                          value: '384',
                          label: 'Assigned',
                          progress: 0.80,
                          color: Color(0xFF6366F1),
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
                  height: 160,
                  child: CircularMetricsCardWidget(
                    title: 'Project Overview',
                    metrics: const [
                      MetricData(
                        icon: Icons.timer,
                        value: '48h',
                        label: 'Time Spent',
                        progress: 0.65,
                        color: Color(0xFF34D399),
                      ),
                      MetricData(
                        icon: Icons.check_circle,
                        value: '18/24',
                        label: 'Tasks Done',
                        progress: 0.75,
                        color: Color(0xFF6366F1),
                      ),
                      MetricData(
                        icon: Icons.people,
                        value: '8',
                        label: 'Members',
                        progress: 0.90,
                        color: Color(0xFFFB7185),
                      ),
                      MetricData(
                        icon: Icons.attach_money,
                        value: '\$2.4k',
                        label: 'Budget',
                        progress: 0.45,
                        color: Color(0xFFFBBF24),
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
                  height: 320,
                  child: CircularMetricsCardWidget(
                    title: 'Team Performance Dashboard',
                    metrics: const [
                      MetricData(
                        icon: Icons.speed,
                        value: '92%',
                        label: 'Efficiency',
                        progress: 0.92,
                        color: Color(0xFF34D399),
                      ),
                      MetricData(
                        icon: Icons.trending_up,
                        value: '+15%',
                        label: 'Growth',
                        progress: 0.72,
                        color: Color(0xFF6366F1),
                      ),
                      MetricData(
                        icon: Icons.task_alt,
                        value: '156',
                        label: 'Completed',
                        progress: 0.85,
                        color: Color(0xFFFB7185),
                      ),
                      MetricData(
                        icon: Icons.pending_actions,
                        value: '23',
                        label: 'In Progress',
                        progress: 0.45,
                        color: Color(0xFFFBBF24),
                      ),
                      MetricData(
                        icon: Icons.calendar_today,
                        value: '5d',
                        label: 'Time Left',
                        progress: 0.35,
                        color: Color(0xFF60A5FA),
                      ),
                      MetricData(
                        icon: Icons.star,
                        value: '4.8',
                        label: 'Rating',
                        progress: 0.96,
                        color: Color(0xFFF472B6),
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
