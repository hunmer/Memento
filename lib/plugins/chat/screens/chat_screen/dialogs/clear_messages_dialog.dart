import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClearMessagesDialog extends StatelessWidget {
  final Function() onConfirm;
  final Function() onCancel;

  const ClearMessagesDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('chat_clearAllMessages'.tr),
      content: Text('chat_confirmClearAllMessages'.tr),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: onConfirm,
          child: Text(AppLocalizations.of(context)!.save),
        ),
      ],
    );
  }
}
