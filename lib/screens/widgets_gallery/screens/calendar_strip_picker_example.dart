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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('日历条日期选择器'),
      ),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('小尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 80,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: CalendarStripDatePicker(
                          selectedDate: selectedDate,
                          onDateChanged: (date) {
                            setState(() {
                              selectedDate = date;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 250,
                    height: 100,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: CalendarStripDatePicker(
                          selectedDate: selectedDate,
                          onDateChanged: (date) {
                            setState(() {
                              selectedDate = date;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 350,
                    height: 120,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: CalendarStripDatePicker(
                          selectedDate: selectedDate,
                          onDateChanged: (date) {
                            setState(() {
                              selectedDate = date;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    '已选择: ${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      ),
    );
  }
}
