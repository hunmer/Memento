import 'package:flutter/material.dart';
import '../utils/time_formatter.dart';

class MessageTimestamp extends StatelessWidget {
  final DateTime date;
  final bool isEdited;

  const MessageTimestamp({
    super.key,
    required this.date,
    this.isEdited = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatTime(date),
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        if (isEdited)
          Text(
            '(已编辑)',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }
}