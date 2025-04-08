import 'package:flutter/material.dart';
import '../utils/date_formatter.dart';

class DatePickerDialog extends StatelessWidget {
  final List<DateTime> availableDates;
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;

  const DatePickerDialog({
    Key? key,
    required this.availableDates,
    required this.selectedDate,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择日期'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView.builder(
          itemCount: availableDates.length,
          itemBuilder: (context, index) {
            final date = availableDates[index];
            final isSelected = selectedDate != null &&
                date.year == selectedDate!.year &&
                date.month == selectedDate!.month &&
                date.day == selectedDate!.day;

            return ListTile(
              title: Text(formatDateFull(date)),
              selected: isSelected,
              tileColor: isSelected ? Colors.blue.withOpacity(0.1) : null,
              onTap: () {
                onDateSelected(date);
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }
}