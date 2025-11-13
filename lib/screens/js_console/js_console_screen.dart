import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/js_console_controller.dart';
import 'widgets/code_editor.dart';
import 'widgets/output_viewer.dart';
import 'widgets/example_buttons.dart';

class JSConsoleScreen extends StatelessWidget {
  const JSConsoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JSConsoleController(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('JS Console'),
          actions: [
            Consumer<JSConsoleController>(
              builder: (context, controller, _) {
                return IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: '清空输出',
                  onPressed: controller.clearOutput,
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // 示例按钮
            const ExampleButtons(),
            const Divider(height: 1),

            // 代码编辑器
            const Expanded(
              flex: 3,
              child: CodeEditor(),
            ),

            const Divider(height: 1),

            // 运行按钮
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Consumer<JSConsoleController>(
                builder: (context, controller, _) {
                  return ElevatedButton.icon(
                    onPressed:
                        controller.isRunning ? null : controller.runCode,
                    icon: controller.isRunning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(controller.isRunning ? '运行中...' : '运行代码'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // 输出显示
            const Expanded(
              flex: 2,
              child: OutputViewer(),
            ),
          ],
        ),
      ),
    );
  }
}
