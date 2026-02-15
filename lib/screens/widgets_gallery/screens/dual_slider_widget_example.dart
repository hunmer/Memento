import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
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
                    child: DualSliderWidget(
                      size: const SmallSize(),
                      label1: 'Shibuya',
                      label2: '+9',
                      label3: 'Aug 12',
                      value1: 10,
                      value2: 25,
                      isPM: true,
                      badgeText: '~4H',
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
                    child: DualSliderWidget(
                      size: const MediumSize(),
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
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 200,
                  child: DualSliderWidget(
                    size: const MediumWideSize(),
                    label1: 'Shibuya, Tokyo, Japan',
                    label2: '+9',
                    label3: 'Aug 12',
                    value1: 10,
                    value2: 25,
                    isPM: true,
                    badgeText: '~4H',
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 280,
                    height: 280,
                    child: DualSliderWidget(
                      size: const LargeSize(),
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
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: DualSliderWidget(
                    size: const LargeWideSize(),
                    label1: 'Shibuya, Tokyo, Japan',
                    label2: '+9',
                    label3: 'Aug 12',
                    value1: 10,
                    value2: 25,
                    isPM: true,
                    badgeText: '~4H',
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
