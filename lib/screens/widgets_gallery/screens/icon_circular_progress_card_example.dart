import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
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
                    child: IconCircularProgressCardWidget(
                      size: const SmallSize(),
                      progress: 0.75,
                      icon: Icons.inventory_2,
                      title: 'Widgefy UI kit',
                      subtitle: 'Graphics design',
                      showNotification: true,
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
                    child: IconCircularProgressCardWidget(
                      size: const MediumSize(),
                      progress: 0.75,
                      icon: Icons.inventory_2,
                      title: 'Widgefy UI kit',
                      subtitle: 'Graphics design',
                      showNotification: true,
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
                    child: IconCircularProgressCardWidget(
                      size: const LargeSize(),
                      progress: 0.75,
                      icon: Icons.inventory_2,
                      title: 'Widgefy UI kit',
                      subtitle: 'Graphics design',
                      showNotification: true,
                    ),
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
