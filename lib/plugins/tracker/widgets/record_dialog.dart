
import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../models/record.dart';
import '../controllers/tracker_controller.dart';

class RecordDialog extends StatefulWidget {
  final Goal goal;
  final TrackerController controller;

  const RecordDialog({
    super.key,
    required this.goal,
    required this.controller,
  });

  @override
  State<RecordDialog> createState() => _RecordDialogState();
}

class _RecordDialogState extends State<RecordDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _recordedAt;
  late double _value;
  late String? _note;
  bool _autoCalculateDiff = false;

  @override
  void initState() {
    super.initState();
    _recordedAt = DateTime.now();
    _value = 1;
    _note = null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('记录 ${widget.goal.name}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('记录时间'),
                subtitle: Text(_formatDateTime(_recordedAt)),
                trailing: const Icon(Icons.edit),
                onTap: () => _pickDateTime(),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: TextEditingController(text: _value.toString()),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '增加值 (${widget.goal.unitType})',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入增加值';
                        }
                        final numValue = double.tryParse(value);
                        if (numValue == null || numValue <= 0) {
                          return '请输入有效的正数';
                        }
                        return null;
                      },
                      onSaved: (value) => _value = double.parse(value!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _calculateDifference,
                    child: const Text('计算差值'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '备注 (可选)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                onSaved: (value) => _note = value,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('确认'),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month}-${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_recordedAt),
    );
    if (time == null) return;

    setState(() {
      _recordedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _calculateDifference() async {
    final textController = TextEditingController();
    final targetValue = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('计算差值'),
          content: TextFormField(
            controller: textController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '输入目标值',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final value = double.tryParse(textController.text);
                if (value != null) {
                  Navigator.pop(context, value);
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );

    if (targetValue != null) {
      setState(() {
        _value = targetValue - widget.goal.currentValue;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final record = Record(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        goalId: widget.goal.id,
        value: _value,
        note: _note,
        recordedAt: _recordedAt,
      );

      widget.controller.addRecord(record, widget.goal);
      Navigator.pop(context);
    }
  }
}
