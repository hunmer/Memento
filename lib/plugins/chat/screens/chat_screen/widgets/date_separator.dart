import 'package:flutter/material.dart';
import '../utils/date_formatter.dart' show formatDate;

class DateSeparator extends StatelessWidget {
  final DateTime date;

  const DateSeparator({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              formatDate(date),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }
}