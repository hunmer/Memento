import 'package:flutter/material.dart';

class SendButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SendButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Container(
          alignment: Alignment.center,
          child: Icon(
            Icons.send,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 20,
          ),
        ),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}