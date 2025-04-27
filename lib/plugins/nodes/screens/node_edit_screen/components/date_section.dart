import 'package:flutter/material.dart';
import '../../../l10n/nodes_localizations.dart';

class DateSection extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?) onStartDateChanged;
  final Function(DateTime?) onEndDateChanged;

  const DateSection({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = NodesLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(
              startDate != null
                  ? startDate!.toString().split(' ')[0]
                  : l10n.startDate,
            ),
            onPressed: () => _selectDate(context, true),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(
              endDate != null
                  ? endDate!.toString().split(' ')[0]
                  : l10n.endDate,
            ),
            onPressed: () => _selectDate(context, false),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isStart ? startDate ?? DateTime.now() : endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      if (isStart) {
        onStartDateChanged(picked);
      } else {
        onEndDateChanged(picked);
      }
    }
  }
}
