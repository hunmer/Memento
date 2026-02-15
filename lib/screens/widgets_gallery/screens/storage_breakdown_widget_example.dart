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
                    height: 180,
                    child: StorageBreakdownCard(
                      title: 'Device Storage',
                      used: 150,
                      total: 256,
                      categories: [
                        SegmentedCategory(
                          name: 'Apps',
                          value: 50,
                          color: Color(0xFFFF3B30),
                        ),
                        SegmentedCategory(
                          name: 'Photos',
                          value: 40,
                          color: Color(0xFF34C759),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 320,
                    height: 220,
                    child: StorageBreakdownCard(
                      title: 'Device Storage',
                      used: 250,
                      total: 512,
                      categories: [
                        SegmentedCategory(
                          name: 'Apps',
                          value: 80,
                          color: Color(0xFFFF3B30),
                        ),
                        SegmentedCategory(
                          name: 'Photos',
                          value: 60,
                          color: Color(0xFF34C759),
                        ),
                        SegmentedCategory(
                          name: 'iCloud',
                          value: 40,
                          color: Color(0xFFFF9500),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 380,
                    height: 280,
                    child: StorageBreakdownCard(
                      title: 'Device Storage',
                      used: 345,
                      total: 512,
                      categories: [
                        SegmentedCategory(
                          name: 'Apps',
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
                        SegmentedCategory(name: 'System', value: 146, color: null),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: StorageBreakdownCard(
                    title: 'Device Storage Overview',
                    used: 400,
                    total: 512,
                    categories: [
                      SegmentedCategory(
                        name: 'Applications',
                        value: 120,
                        color: Color(0xFFFF3B30),
                      ),
                      SegmentedCategory(
                        name: 'Photos & Videos',
                        value: 100,
                        color: Color(0xFF34C759),
                      ),
                      SegmentedCategory(
                        name: 'iCloud Drive',
                        value: 60,
                        color: Color(0xFFFF9500),
                      ),
                      SegmentedCategory(
                        name: 'Documents',
                        value: 50,
                        color: Color(0xFF007AFF),
                      ),
                      SegmentedCategory(name: 'System Data', value: 70, color: null),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: StorageBreakdownCard(
                    title: 'Complete Device Storage Analysis',
                    used: 480,
                    total: 512,
                    categories: [
                      SegmentedCategory(
                        name: 'Applications',
                        value: 140,
                        color: Color(0xFFFF3B30),
                      ),
                      SegmentedCategory(
                        name: 'Photos & Videos',
                        value: 120,
                        color: Color(0xFF34C759),
                      ),
                      SegmentedCategory(
                        name: 'iCloud Drive',
                        value: 80,
                        color: Color(0xFFFF9500),
                      ),
                      SegmentedCategory(
                        name: 'Documents & Files',
                        value: 60,
                        color: Color(0xFF007AFF),
                      ),
                      SegmentedCategory(
                        name: 'Music & Audio',
                        value: 40,
                        color: Color(0xFFAF52DE),
                      ),
                      SegmentedCategory(name: 'System Data', value: 40, color: null),
                    ],
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
