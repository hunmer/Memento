import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Memento/screens/js_console/controllers/js_console_controller.dart';

class CodeEditor extends StatefulWidget {
  const CodeEditor({super.key});

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JSConsoleController>(
      builder: (context, controller, _) {
        // 同步文本
        if (_textController.text != controller.code) {
          _textController.text = controller.code;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.code.length),
          );
        }

        return Container(
          color: Colors.grey[900],
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _textController,
            onChanged: controller.setCode,
            maxLines: null,
            expands: true,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: Colors.white,
            ),
            decoration: const InputDecoration(
              hintText: '// 在此输入 JavaScript 代码\n// 可以使用 Memento.chat.* API',
              hintStyle: TextStyle(color: Colors.white38),
              border: InputBorder.none,
            ),
          ),
        );
      },
    );
  }
}
