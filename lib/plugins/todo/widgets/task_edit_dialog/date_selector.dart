import 'package:flutter/material.dart';

class DateSelector extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? dueDate;
  final Function(bool isStartDate) onSelectDate;

  const DateSelector({
    super.key,
    this.startDate,
    this.dueDate,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => onSelectDate(true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    startDate != null
                        ? '${startDate!.year}-${startDate!.month}-${startDate!.day}'
                        : '开始日期',
                    style: textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => onSelectDate(false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.event_busy),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    dueDate != null
                        ? '${dueDate!.year}-${dueDate!.month}-${dueDate!.day}'
                        : '截止日期',
                    style: textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}