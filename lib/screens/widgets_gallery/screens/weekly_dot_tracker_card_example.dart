import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/index.dart';

/// 周点阵追踪卡片示例
///
/// 展示点阵追踪卡片的两种使用方式：
/// 1. 直接使用组件构造函数
/// 2. 从数据模型创建组件（支持 JSON 序列化）
class WeeklyDotTrackerCardExample extends StatefulWidget {
  const WeeklyDotTrackerCardExample({super.key});

  @override
  State<WeeklyDotTrackerCardExample> createState() =>
      _WeeklyDotTrackerCardExampleState();
}

class _WeeklyDotTrackerCardExampleState
    extends State<WeeklyDotTrackerCardExample> {
  /// 示例数据（模拟从存储加载）
  static final DotTrackerCardData exampleData = DotTrackerCardData.withIcon(
    title: 'Nutrition',
    icon: Icons.eco,
    currentValue: 998,
    unit: 'kcal',
    status: 'On Track',
    weekDays: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
    dotStates: [
      [false, true, true], // 周一
      [false, false, true], // 周二
      [false, true, true], // 周三
      [true, true, false], // 周四
      [false, false, false], // 周五
      [true, false, false], // 周六
      [true, true, false], // 周日
    ],
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('周点阵追踪卡片'),
        actions: [
          // 演示 JSON 序列化功能的按钮
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: '查看 JSON',
            onPressed: _showJsonDialog,
          ),
        ],
      ),
      body: Container(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
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
                    child: DotTrackerCardWidget.fromData(
                      exampleData,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('点击了点阵追踪卡片')),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: DotTrackerCardWidget.fromData(
                      exampleData,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('点击了点阵追踪卡片')),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: DotTrackerCardWidget.fromData(
                      exampleData,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('点击了点阵追踪卡片')),
                        );
                      },
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

  /// 显示 JSON 序列化演示对话框
  void _showJsonDialog() {
    // 将数据序列化为 JSON
    final jsonString = exampleData.toJsonString();

    // 从 JSON 反序列化
    final restoredData = DotTrackerCardData.fromJsonString(jsonString);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('JSON 序列化演示'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '原始数据:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    exampleData.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'JSON 字符串:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    jsonString,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '反序列化验证:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('标题: ${restoredData.title}'),
                  Text('数值: ${restoredData.currentValue} ${restoredData.unit}'),
                  Text('状态: ${restoredData.status}'),
                  Text('天数: ${restoredData.weekDays.length}'),
                  Text('点阵数: ${restoredData.dotStates.length}'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          ),
    );
  }
}
