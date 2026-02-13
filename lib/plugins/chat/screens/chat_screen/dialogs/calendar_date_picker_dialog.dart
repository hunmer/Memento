import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

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
  late CalendarController _calendarController;
  DateTime? _selectedDay;
  late Set<DateTime> _availableDatesSet;
  late Map<DateTime, int> _dateCountMap;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.selectedDate;
    _calendarController = CalendarController();
    _calendarController.selectedDate = widget.selectedDate;
    _calendarController.displayDate =
        widget.selectedDate ?? widget.availableDates.first;

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

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  bool _isDateAvailable(DateTime day) {
    return _availableDatesSet.contains(DateTime(day.year, day.month, day.day));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _monthCellBuilder(BuildContext context, MonthCellDetails details) {
    final date = details.date;
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final isAvailable = _isDateAvailable(date);
    final isSelected = _selectedDay != null && _isSameDay(date, _selectedDay!);
    final isToday = _isSameDay(date, DateTime.now());
    final count = _dateCountMap[normalizedDate];

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            isSelected
                ? Colors.blue
                : (isToday ? Colors.blue.withValues(alpha: 0.3) : null),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '${date.day}',
              style: TextStyle(
                color:
                    !isAvailable
                        ? Colors.grey[400]
                        : (isSelected
                            ? Colors.white
                            : (date.weekday == DateTime.saturday ||
                                    date.weekday == DateTime.sunday
                                ? Colors.red[300]
                                : Colors.black)),
                fontWeight:
                    (date.weekday == DateTime.saturday ||
                                date.weekday == DateTime.sunday) &&
                            isAvailable
                        ? FontWeight.bold
                        : FontWeight.normal,
              ),
            ),
          ),
          if (count != null && count > 0)
            Positioned(
              right: 1,
              top: 1,
              child: Container(
                padding: const EdgeInsets.all(2.0),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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
                  'app_selectDate'.tr,
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
                  child: Text('app_showAll'.tr),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 350,
            child: SfCalendar(
              controller: _calendarController,
              view: CalendarView.month,
              initialDisplayDate:
                  widget.selectedDate ?? widget.availableDates.first,
              minDate: widget.availableDates.last,
              maxDate: widget.availableDates.first,
              headerStyle: const CalendarHeaderStyle(
                textAlign: TextAlign.center,
                textStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              monthViewSettings: const MonthViewSettings(
                showTrailingAndLeadingDates: false,
                dayFormat: 'EEE',
              ),
              cellBorderColor: Colors.transparent,
              selectionDecoration: const BoxDecoration(),
              monthCellBuilder: _monthCellBuilder,
              onTap: (CalendarTapDetails details) {
                if (details.date != null && _isDateAvailable(details.date!)) {
                  setState(() {
                    _selectedDay = details.date;
                    _calendarController.selectedDate = details.date;
                  });
                  widget.onDateSelected(details.date);
                  Navigator.of(context).pop();
                }
              },
            ),
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
                  child: Text('app_cancel'.tr),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
