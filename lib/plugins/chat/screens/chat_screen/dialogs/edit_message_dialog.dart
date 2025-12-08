import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/chat/l10n/chat_localizations.dart';
import 'package:flutter/material.dart';
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
      title: Text(ChatLocalizations.of(context).editMessageTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            maxLines: null,
            decoration: InputDecoration(
              hintText: ChatLocalizations.of(context).messageHintText,
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
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: onSave,
          child: Text(AppLocalizations.of(context)!.save),
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
