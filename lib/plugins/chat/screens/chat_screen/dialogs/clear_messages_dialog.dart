import 'package:flutter/material.dart';

class ClearMessagesDialog extends StatelessWidget {
  final Function() onConfirm;
  final Function() onCancel;

  const ClearMessagesDialog({
    Key? key,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('清空消息'),
      content: const Text('确定要清空所有消息吗？此操作不可撤销。'),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: onConfirm,
          child: const Text('确定'),
        ),
      ],
    );
  }
}