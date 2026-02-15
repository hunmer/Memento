import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/modern_flip_counter_card.dart';

/// 现代 eGFR 健康指标卡片示例
class ModernFlipCounterCardExample extends StatelessWidget {
  const ModernFlipCounterCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('eGFR 健康指标卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF3F4F6),
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
                    child: ModernFlipCounterCard(
                      title: 'eGFR - Low Range',
                      value: 4.2,
                      unit: 'mL/min',
                      date: 'September 2026',
                      status: 'In-Range',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: ModernFlipCounterCard(
                      title: 'eGFR - Low Range',
                      value: 4.2,
                      unit: 'mL/min',
                      date: 'September 2026',
                      status: 'In-Range',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 280,
                    height: 280,
                    child: ModernFlipCounterCard(
                      title: 'eGFR - Low Range',
                      value: 4.2,
                      unit: 'mL/min',
                      date: 'September 2026',
                      status: 'In-Range',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 200,
                  child: ModernFlipCounterCard(
                    title: 'eGFR - Low Range Kidney Function',
                    value: 4.2,
                    unit: 'mL/min',
                    date: 'September 2026',
                    status: 'In-Range',
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: ModernFlipCounterCard(
                    title: 'eGFR - Low Range Kidney Function Monitoring',
                    value: 4.2,
                    unit: 'mL/min',
                    date: 'September 2026',
                    status: 'In-Range',
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
