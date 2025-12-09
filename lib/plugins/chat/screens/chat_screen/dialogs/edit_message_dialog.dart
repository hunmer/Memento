import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/chat/models/message.dart';

class EditMessageDialog extends StatelessWidget {
  final Message message;
  final TextEditingController controller;
  final Function() onCancel;
  final Function() onSave;

  const EditMessageDialog({
    super.key,
    required this.message,
    required this.controller,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('chat_editMessageTitle'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            maxLines: null,
            decoration: InputDecoration(
              hintText: 'chat_messageHintText'.tr,
            ),
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
          child: Text('app_cancel'.tr),
        ),
        TextButton(
          onPressed: onSave,
          child: Text('app_save'.tr),
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
