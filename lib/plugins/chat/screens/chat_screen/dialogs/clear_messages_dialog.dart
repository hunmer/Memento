import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/chat/l10n/chat_localizations.dart';
import 'package:flutter/material.dart';

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
      title: Text(ChatLocalizations.of(context)!.clearAllMessages),
      content: Text(ChatLocalizations.of(context)!.confirmClearAllMessages),
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
