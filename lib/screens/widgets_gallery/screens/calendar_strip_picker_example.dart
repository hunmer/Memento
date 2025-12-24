import 'package:flutter/material.dart';
import 'package:Memento/widgets/picker/calendar_strip_date_picker.dart';

/// 日历条日期选择器示例
class CalendarStripPickerExample extends StatefulWidget {
  const CalendarStripPickerExample({super.key});

  @override
  State<CalendarStripPickerExample> createState() => _CalendarStripPickerExampleState();
}

class _CalendarStripPickerExampleState extends State<CalendarStripPickerExample> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日历条日期选择器'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CalendarStripDatePicker',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text('这是一个水平滚动的日历条组件，支持日期选择。'),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: CalendarStripDatePicker(
              selectedDate: selectedDate,
              onDateChanged: (date) {
                setState(() {
                  selectedDate = date;
                });
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '已选择日期',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  _getWeekdayName(selectedDate.weekday),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    const names = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[weekday];
  }
}
