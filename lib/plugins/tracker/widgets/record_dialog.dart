import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/plugins/tracker/models/goal.dart';
import 'package:Memento/plugins/tracker/models/record.dart';
import 'package:Memento/plugins/tracker/controllers/tracker_controller.dart';

class RecordDialog extends StatefulWidget {
  final Goal goal;
  final TrackerController controller;

  const RecordDialog({super.key, required this.goal, required this.controller});

  @override
  State<RecordDialog> createState() => _RecordDialogState();
}

class _RecordDialogState extends State<RecordDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _recordedAt;
  late double _value;
  late String? _note;

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
      title: Text('tracker_recordTitle'.tr.replaceFirst('{goalName}', widget.goal.name)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text('tracker_recordTitle'.tr),
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
                      controller: TextEditingController(
                        text: _value.toString(),
                      ),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'tracker_incrementValueWithUnit'
                            .tr
                            .replaceFirst('\${unit}', widget.goal.unitType),
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
                    child: Text(
                      'tracker_calculateDifference'.tr,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText:
                      '${'tracker_note'.tr} (${'tracker_noteHint'.tr})',
                  border: const OutlineInputBorder(),
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
          child: Text('tracker_cancel'.tr),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text('tracker_confirm'.tr),
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
          title: Text('tracker_calculateDifference'.tr),
          content: TextFormField(
            controller: textController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'tracker_inputTargetValue'.tr,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('tracker_cancel'.tr),
            ),
            TextButton(
              onPressed: () {
                final value = double.tryParse(textController.text);
                if (value != null) {
                  Navigator.pop(context, value);
                }
              },
              child: Text('tracker_confirm'.tr),
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
        id: const Uuid().v4(),
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
