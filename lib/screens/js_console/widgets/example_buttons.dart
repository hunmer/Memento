import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/js_console_controller.dart';

class ExampleButtons extends StatelessWidget {
  const ExampleButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<JSConsoleController>(
      builder: (context, controller, _) {
        // 如果示例未加载，显示加载提示
        if (!controller.examplesLoaded) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey[200],
            child: const Center(
              child: Text('加载示例中...', style: TextStyle(fontSize: 12)),
            ),
          );
        }

        // 如果没有示例，显示提示
        if (controller.examples.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey[200],
            child: const Center(
              child: Text('没有可用示例', style: TextStyle(fontSize: 12)),
            ),
          );
        }

        // 显示示例按钮
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: Colors.grey[200],
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: controller.examples.keys.map((key) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton.icon(
                    onPressed: () => controller.loadExample(key),
                    icon: const Icon(Icons.code, size: 16),
                    label: Text(key),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
