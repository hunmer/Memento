import 'package:flutter/material.dart';

class AddTaskButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddTaskButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      child: const Icon(Icons.add),
    );
  }
}