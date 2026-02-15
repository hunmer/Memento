import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/ranked_bar_chart_card.dart';

/// 排名条形图卡片示例
class RankedBarChartCardExample extends StatelessWidget {
  const RankedBarChartCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('排名条形图卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFEEF1F6),
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
                    width: 280,
                    height: 300,
                    child: RankedBarChartCardWidget(
                      title: 'Average of the first economies',
                      subtitle: 'Minim dolor in amet nulla laboris enim dolore consequatt.',
                      itemCount: '8 countries',
                      items: [
                        RankedBarItem(label: 'Noruega', value: 1.0, color: Color(0xFF020058)),
                        RankedBarItem(label: 'Australia', value: 0.9, color: Color(0xFF053876)),
                        RankedBarItem(label: 'Suiza', value: 0.8, color: Color(0xFF0069A8)),
                        RankedBarItem(label: 'Países Bajos', value: 0.72, color: Color(0xFF008DB6)),
                      ],
                      footer: 'Minim dolor in amet.',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 320,
                    height: 350,
                    child: RankedBarChartCardWidget(
                      title: 'Average of the first economies',
                      subtitle: 'Minim dolor in amet nulla laboris enim dolore consequatt.',
                      itemCount: '8 countries',
                      items: [
                        RankedBarItem(label: 'Noruega', value: 1.0, color: Color(0xFF020058)),
                        RankedBarItem(label: 'Australia', value: 0.9, color: Color(0xFF053876)),
                        RankedBarItem(label: 'Suiza', value: 0.8, color: Color(0xFF0069A8)),
                        RankedBarItem(label: 'Países Bajos', value: 0.72, color: Color(0xFF008DB6)),
                        RankedBarItem(label: 'Estados Unidos', value: 0.64, color: Color(0xFF00B0CE)),
                      ],
                      footer: 'Minim dolor in amet.',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 380,
                    height: 420,
                    child: RankedBarChartCardWidget(
                      title: 'Average of the first economies',
                      subtitle: 'Minim dolor in amet nulla laboris enim dolore consequatt.',
                      itemCount: '8 countries',
                      items: [
                        RankedBarItem(label: 'Noruega', value: 1.0, color: Color(0xFF020058)),
                        RankedBarItem(label: 'Australia', value: 0.9, color: Color(0xFF053876)),
                        RankedBarItem(label: 'Suiza', value: 0.8, color: Color(0xFF0069A8)),
                        RankedBarItem(label: 'Países Bajos', value: 0.72, color: Color(0xFF008DB6)),
                        RankedBarItem(label: 'Estados Unidos', value: 0.64, color: Color(0xFF00B0CE)),
                        RankedBarItem(label: 'Alemania', value: 0.56, color: Color(0xFF4CCCE3)),
                        RankedBarItem(label: 'Nueva Zelanda', value: 0.48, color: Color(0xFF8EE1F1)),
                        RankedBarItem(label: 'Canadá', value: 0.4, color: Color(0xFFCBF1F7)),
                      ],
                      footer: 'Minim dolor in amet nulla laboris enim dolore consequatt.',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 380,
                  child: RankedBarChartCardWidget(
                    title: 'Average of the First Economies - Global Ranking',
                    subtitle: 'A comprehensive analysis of economic performance across leading nations worldwide.',
                    itemCount: '8 countries',
                    items: [
                      RankedBarItem(label: 'Noruega', value: 1.0, color: Color(0xFF020058)),
                      RankedBarItem(label: 'Australia', value: 0.9, color: Color(0xFF053876)),
                      RankedBarItem(label: 'Suiza', value: 0.8, color: Color(0xFF0069A8)),
                      RankedBarItem(label: 'Países Bajos', value: 0.72, color: Color(0xFF008DB6)),
                      RankedBarItem(label: 'Estados Unidos', value: 0.64, color: Color(0xFF00B0CE)),
                      RankedBarItem(label: 'Alemania', value: 0.56, color: Color(0xFF4CCCE3)),
                      RankedBarItem(label: 'Nueva Zelanda', value: 0.48, color: Color(0xFF8EE1F1)),
                      RankedBarItem(label: 'Canadá', value: 0.4, color: Color(0xFFCBF1F7)),
                    ],
                    footer: 'Comprehensive economic indicators and performance metrics analysis.',
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 480,
                  child: RankedBarChartCardWidget(
                    title: 'Average of the First Economies - Complete Global Analysis',
                    subtitle: 'A comprehensive analysis of economic performance across leading nations worldwide with detailed metrics.',
                    itemCount: '8 countries',
                    items: [
                      RankedBarItem(label: 'Noruega', value: 1.0, color: Color(0xFF020058)),
                      RankedBarItem(label: 'Australia', value: 0.9, color: Color(0xFF053876)),
                      RankedBarItem(label: 'Suiza', value: 0.8, color: Color(0xFF0069A8)),
                      RankedBarItem(label: 'Países Bajos', value: 0.72, color: Color(0xFF008DB6)),
                      RankedBarItem(label: 'Estados Unidos', value: 0.64, color: Color(0xFF00B0CE)),
                      RankedBarItem(label: 'Alemania', value: 0.56, color: Color(0xFF4CCCE3)),
                      RankedBarItem(label: 'Nueva Zelanda', value: 0.48, color: Color(0xFF8EE1F1)),
                      RankedBarItem(label: 'Canadá', value: 0.4, color: Color(0xFFCBF1F7)),
                    ],
                    footer: 'Comprehensive economic indicators and performance metrics analysis for global comparison.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
