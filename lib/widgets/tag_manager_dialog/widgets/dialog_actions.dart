import 'package:flutter/material.dart';

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
          label: Text('清空 $selectedCount 选中'),
        ),
        Row(
          children: [
            TextButton(
              onPressed: onCancel,
              child: const Text('取消'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onConfirm,
              child: const Text('确认'),
            ),
          ],
        ),
      ],
    );
  }
}