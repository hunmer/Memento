import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Memento/plugins/goods/l10n/goods_localizations.dart';

class AddUsageRecordDialog extends StatefulWidget {
  const AddUsageRecordDialog({super.key});

  @override
  State<AddUsageRecordDialog> createState() => _AddUsageRecordDialogState();
}

class _AddUsageRecordDialogState extends State<AddUsageRecordDialog> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _noteController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(GoodsLocalizations.of(context).addUsageRecord),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('日期时间'),
              subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: '使用时长 (分钟)',
                hintText: '例如: 30',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: '使用地点',
                hintText: '例如: 办公室',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: GoodsLocalizations.of(context).optionalNote,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(GoodsLocalizations.of(context).cancel),
        ),
        TextButton(
          onPressed: () {
            final duration = int.tryParse(_durationController.text);
            Navigator.pop(context, {
              'date': _selectedDate,
              'duration': duration,
              'location': _locationController.text.isEmpty ? null : _locationController.text,
              'note': _noteController.text.isEmpty ? null : _noteController.text,
            });
          },
          child: Text(GoodsLocalizations.of(context).confirm),
        ),
      ],
    );
  }
}
