import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/dual_slider_widget.dart';

/// 双滑块小组件示例
class DualSliderWidgetExample extends StatelessWidget {
  const DualSliderWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('双滑块小组件')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: DualSliderWidget(
            label1: 'Shibuya, Tokyo',
            label2: '+9',
            label3: 'Aug 12',
            value1: 10,
            value2: 25,
            isPM: true,
            badgeText: '~4H',
          ),
        ),
      ),
    );
  }
}
