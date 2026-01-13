import 'package:animated_flip_counter/animated_flip_counter.dart';
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
        child: const Center(
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
    );
  }
}
