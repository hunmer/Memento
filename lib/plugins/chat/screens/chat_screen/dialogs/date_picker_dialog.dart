import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../utils/date_formatter.dart';

class DatePickerDialog extends StatelessWidget {
  final List<DateTime> availableDates;
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;

  const DatePickerDialog({
    super.key,
    required this.availableDates,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.selectDate),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView.builder(
          itemCount: availableDates.length,
          itemBuilder: (context, index) {
            final date = availableDates[index];
            final isSelected =
                selectedDate != null &&
                date.year == selectedDate!.year &&
                date.month == selectedDate!.month &&
                date.day == selectedDate!.day;

            return ListTile(
              title: Text(formatDateFull(date)),
              selected: isSelected,
              tileColor: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
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
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
      ],
    );
  }
}
