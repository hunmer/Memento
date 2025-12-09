import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:Memento/screens/js_console/controllers/js_console_controller.dart';

class OutputViewer extends StatelessWidget {
  const OutputViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<JSConsoleController>(
      builder: (context, controller, _) {
        return Container(
          color: Colors.grey[100],
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: SelectableText(
              controller.output.isEmpty
                  ? '// 输出结果将显示在此处'
                  : controller.output,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: controller.output.isEmpty ? Colors.grey : Colors.black87,
              ),
            ),
          ),
        );
      },
    );
  }
}
