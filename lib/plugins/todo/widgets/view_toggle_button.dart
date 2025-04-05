import 'package:flutter/material.dart';

class ViewToggleButton extends StatelessWidget {
  final bool isTreeView;
  final VoidCallback onToggle;

  const ViewToggleButton({
    super.key,
    required this.isTreeView,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isTreeView ? Icons.account_tree : Icons.list,
        color: Colors.white,
      ),
      onPressed: onToggle,
      tooltip: isTreeView ? '树状视图（当前）' : '树状视图',
    );
  }
}
