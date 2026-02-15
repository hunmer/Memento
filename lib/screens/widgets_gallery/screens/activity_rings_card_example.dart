import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/activity_rings_card.dart';

/// 活动圆环卡片示例
class ActivityRingsCardExample extends StatelessWidget {
  const ActivityRingsCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('活动圆环卡片')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
          ),
        ),
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
                    child: ActivityRingsCardWidget(
                      date: 'Jan 23, 2025',
                      steps: 858,
                      status: 'Normal',
                      rings: const [
                        RingData(value: 70, color: Color(0xFFF97316), icon: Icons.print),
                        RingData(value: 20, color: Color(0xFF2563EB), icon: null, isDiamond: true),
                        RingData(value: 40, color: Color(0xFF6B7280), icon: Icons.directions_run),
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
                    child: ActivityRingsCardWidget(
                      date: 'Jan 23, 2025',
                      steps: 858,
                      status: 'Normal',
                      rings: const [
                        RingData(value: 70, color: Color(0xFFF97316), icon: Icons.print),
                        RingData(value: 20, color: Color(0xFF2563EB), icon: null, isDiamond: true),
                        RingData(value: 40, color: Color(0xFF6B7280), icon: Icons.directions_run),
                      ],
                      size: const MediumSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 220,
                  child: ActivityRingsCardWidget(
                    date: 'Jan 23, 2025',
                    steps: 858,
                    status: 'Normal',
                    rings: const [
                      RingData(value: 70, color: Color(0xFFF97316), icon: Icons.print),
                      RingData(value: 20, color: Color(0xFF2563EB), icon: null, isDiamond: true),
                      RingData(value: 40, color: Color(0xFF6B7280), icon: Icons.directions_run),
                    ],
                    size: const WideSize(),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: ActivityRingsCardWidget(
                      date: 'Jan 23, 2025',
                      steps: 858,
                      status: 'Normal',
                      rings: const [
                        RingData(value: 70, color: Color(0xFFF97316), icon: Icons.print),
                        RingData(value: 20, color: Color(0xFF2563EB), icon: null, isDiamond: true),
                        RingData(value: 40, color: Color(0xFF6B7280), icon: Icons.directions_run),
                      ],
                      size: const LargeSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 300,
                  child: ActivityRingsCardWidget(
                    date: 'Jan 23, 2025',
                    steps: 858,
                    status: 'Normal',
                    rings: const [
                      RingData(value: 70, color: Color(0xFFF97316), icon: Icons.print),
                      RingData(value: 20, color: Color(0xFF2563EB), icon: null, isDiamond: true),
                      RingData(value: 40, color: Color(0xFF6B7280), icon: Icons.directions_run),
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
        color: Colors.white,
      ),
    );
  }
}
