import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/segmented_progress_card.dart';

/// 分段进度条统计卡片示例
///
/// 此示例展示如何使用 [SegmentedProgressCardWidget] 组件
/// 该组件用于显示分段的预算/进度统计
/// 展示三种尺寸：小、中、大
class SegmentedProgressCardExample extends StatelessWidget {
  const SegmentedProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('分段进度条统计卡片')),
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
                    width: 160,
                    height: 180,
                    child: const SegmentedProgressCardWidget(
                      title: 'Small',
                      currentValue: 50,
                      targetValue: 100,
                      segments: [
                        SegmentData(label: '餐饮', value: 20, color: Color(0xFFFF3B30)),
                        SegmentData(label: '健身', value: 15, color: Color(0xFF007AFF)),
                        SegmentData(label: '交通', value: 10, color: Color(0xFFFFCC00)),
                        SegmentData(label: '其他', value: 5, color: Color(0xFF8E8E93)),
                      ],
                      unit: '\$',
                      size: HomeWidgetSize.small,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 280,
                    height: 300,
                    child: const SegmentedProgressCardWidget(
                      title: 'Medium',
                      currentValue: 322,
                      targetValue: 443,
                      segments: [
                        SegmentData(label: '餐饮', value: 37, color: Color(0xFFFF3B30)),
                        SegmentData(label: '健身', value: 43, color: Color(0xFF007AFF)),
                        SegmentData(label: '交通', value: 31, color: Color(0xFFFFCC00)),
                        SegmentData(label: '其他', value: 11, color: Color(0xFF8E8E93)),
                      ],
                      unit: '\$',
                      size: HomeWidgetSize.medium,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 360,
                    height: 400,
                    child: const SegmentedProgressCardWidget(
                      title: 'Large',
                      currentValue: 890,
                      targetValue: 1200,
                      segments: [
                        SegmentData(label: '餐饮', value: 120, color: Color(0xFFFF3B30)),
                        SegmentData(label: '健身', value: 150, color: Color(0xFF007AFF)),
                        SegmentData(label: '交通', value: 85, color: Color(0xFFFFCC00)),
                        SegmentData(label: '购物', value: 200, color: Color(0xFF34C759)),
                        SegmentData(label: '娱乐', value: 95, color: Color(0xFFAF52DE)),
                        SegmentData(label: '其他', value: 240, color: Color(0xFF8E8E93)),
                      ],
                      unit: '\$',
                      size: HomeWidgetSize.large,
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
