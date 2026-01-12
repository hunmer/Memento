import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/index.dart';

/// 存储分段小组件示例
class StorageBreakdownWidgetExample extends StatelessWidget {
  const StorageBreakdownWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('存储分段小组件')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: StorageBreakdownCard(
            title: 'Device Storage',
            used: 345,
            total: 512,
            categories: [
              SegmentedCategory(
                name: 'Application',
                value: 96,
                color: Color(0xFFFF3B30),
              ),
              SegmentedCategory(
                name: 'Photos',
                value: 62,
                color: Color(0xFF34C759),
              ),
              SegmentedCategory(
                name: 'iCloud Drive',
                value: 41,
                color: Color(0xFFFF9500),
              ),
              SegmentedCategory(name: 'System Data', value: 146, color: null),
            ],
          ),
        ),
      ),
    );
  }
}
