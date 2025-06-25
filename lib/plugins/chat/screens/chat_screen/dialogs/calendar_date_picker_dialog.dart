import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarDatePickerDialog extends StatefulWidget {
  final List<DateTime> availableDates;
  final DateTime? selectedDate;
  final Function(DateTime?) onDateSelected;
  final Map<DateTime, int>? dateCountMap;

  const CalendarDatePickerDialog({
    super.key,
    required this.availableDates,
    required this.selectedDate,
    required this.onDateSelected,
    this.dateCountMap,
  });

  @override
  State<CalendarDatePickerDialog> createState() =>
      _CalendarDatePickerDialogState();
}

class _CalendarDatePickerDialogState extends State<CalendarDatePickerDialog> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  late Set<DateTime> _availableDatesSet;
  late Map<DateTime, int> _dateCountMap;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.selectedDate;
    _focusedDay = widget.selectedDate ?? widget.availableDates.first;

    // 将可用日期转换为Set以便快速查找
    _availableDatesSet =
        widget.availableDates
            .map((date) => DateTime(date.year, date.month, date.day))
            .toSet();

    // 初始化日期计数映射
    _dateCountMap = {};
    if (widget.dateCountMap != null) {
      widget.dateCountMap!.forEach((key, value) {
        // 规范化日期，只保留年月日
        final normalizedDate = DateTime(key.year, key.month, key.day);
        _dateCountMap[normalizedDate] = value;
      });
    }
  }

  bool _isDateAvailable(DateTime day) {
    return _availableDatesSet.contains(DateTime(day.year, day.month, day.day));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.selectDate,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onDateSelected(null);
                    Navigator.of(context).pop();
                  },
                  child: Text(AppLocalizations.of(context)!.showAll),
                ),
              ],
            ),
          ),
          TableCalendar(
            firstDay: widget.availableDates.last,
            lastDay: widget.availableDates.first,
            focusedDay: _focusedDay,
            selectedDayPredicate:
                (day) => _selectedDay != null && isSameDay(_selectedDay!, day),
            enabledDayPredicate: _isDateAvailable,
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              disabledTextStyle: TextStyle(
                color: Colors.grey[400],
                decoration: TextDecoration.none,
              ),
              weekendTextStyle: TextStyle(color: Colors.red[300]),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final normalizedDate = DateTime(
                  date.year,
                  date.month,
                  date.day,
                );
                if (_dateCountMap.containsKey(normalizedDate) &&
                    _dateCountMap[normalizedDate]! > 0) {
                  return Positioned(
                    right: 1,
                    top: 1,
                    child: Container(
                      padding: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${_dateCountMap[normalizedDate]}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
              weekendStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              widget.onDateSelected(selectedDay);
              Navigator.of(context).pop();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
