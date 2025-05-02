import 'package:flutter/material.dart';

class MessageActions extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCopy;
  final Function(String?) onSetFixedSymbol;

  const MessageActions({
    super.key,
    required this.onEdit,
    required this.onDelete,
    required this.onCopy,
    required this.onSetFixedSymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, size: 16),
          onPressed: onEdit,
          tooltip: '编辑',
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 16),
          onPressed: onCopy,
          tooltip: '复制',
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete, size: 16),
          onPressed: onDelete,
          tooltip: '删除',
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
      ],
    );
  }
}