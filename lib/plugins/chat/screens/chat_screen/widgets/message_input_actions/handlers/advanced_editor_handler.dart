import 'package:Memento/widgets/quill_editor.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/chat/screens/chat_screen/widgets/message_input_actions/types.dart';

Future<void> handleAdvancedEditor({
  required BuildContext context,
  required OnSendMessage? onSendMessage,
}) async {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: MarkdownEditor(
          showTitle: false,
              contentHint: '在此输入消息内容...',
          onSave: (_, content) {
            if (content.isNotEmpty) {
              // 发送消息
              onSendMessage?.call(content, type: 'sent');
            }
            Navigator.of(context).pop();
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    ),
  );
}