import 'package:flutter/material.dart';
import '../l10n/tag_manager_localizations.dart';

class DialogActions extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onClear;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final bool enableClear;

  const DialogActions({
    super.key,
    required this.selectedCount,
    required this.onClear,
    required this.onCancel,
    required this.onConfirm,
    required this.enableClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: enableClear ? onClear : null,
          icon: const Icon(Icons.clear_all),
          label: Text(
            '${TagManagerLocalizations.of(context, 'clearSelected').replaceFirst('\$selectedCount', selectedCount.toString())}',
          ),
        ),
        Row(
          children: [
            TextButton(
              onPressed: onCancel,
              child: Text(TagManagerLocalizations.of(context, 'cancel')),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onConfirm,
              child: Text(TagManagerLocalizations.of(context, 'confirm')),
            ),
          ],
        ),
      ],
    );
  }
}
