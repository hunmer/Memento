import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/icon_circular_progress_card.dart';

/// 图标圆形进度卡片示例
class IconCircularProgressCardExample extends StatelessWidget {
  const IconCircularProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('图标圆形进度卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: IconCircularProgressCardWidget(
            progress: 0.75,
            icon: Icons.inventory_2,
            title: 'Widgefy UI kit',
            subtitle: 'Graphics design',
            showNotification: true,
          ),
        ),
      ),
    );
  }
}
