import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
            'tagManager_clearSelected'.tr
                .replaceFirst('\$selectedCount', selectedCount.toString()),
          ),
        ),
        Row(
          children: [
            TextButton(
              onPressed: onCancel,
              child: Text('tagManager_cancel'.tr),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onConfirm,
              child: Text('tagManager_confirm'.tr),
            ),
          ],
        ),
      ],
    );
  }
}
