import 'package:flutter/material.dart';
import '../../../models/message.dart';

class EditMessageDialog extends StatelessWidget {
  final Message message;
  final TextEditingController controller;
  final Function() onCancel;
  final Function() onSave;

  const EditMessageDialog({
    Key? key,
    required this.message,
    required this.controller,
    required this.onCancel,
    required this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑消息'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            maxLines: null,
            decoration: const InputDecoration(hintText: '输入新的消息内容...'),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.format_bold),
                onPressed: () => _insertMarkdownStyle('**'),
              ),
              IconButton(
                icon: const Icon(Icons.format_italic),
                onPressed: () => _insertMarkdownStyle('*'),
              ),
              IconButton(
                icon: const Icon(Icons.format_strikethrough),
                onPressed: () => _insertMarkdownStyle('~~'),
              ),
              IconButton(
                icon: const Icon(Icons.format_underline),
                onPressed: () => _insertMarkdownStyle('__'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: onSave,
          child: const Text('保存'),
        ),
      ],
    );
  }

  void _insertMarkdownStyle(String style) {
    final text = controller.text;
    final selection = controller.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '$style${selection.textInside(text)}$style',
    );
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset:
            selection.baseOffset +
            style.length * 2 +
            selection.textInside(text).length,
      ),
    );
  }
}