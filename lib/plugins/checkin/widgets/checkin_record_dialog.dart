import 'package:Memento/plugins/checkin/controllers/checkin_list_controller.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/checkin/models/checkin_item.dart';

class CheckinRecordDialog extends StatefulWidget {
  final CheckinItem item;
  final CheckinListController controller;
  final VoidCallback onCheckinCompleted;
  final DateTime? selectedDate;

  const CheckinRecordDialog({
    super.key,
    required this.item,
    required this.controller,
    required this.onCheckinCompleted,
    this.selectedDate,
  });

  @override
  State<CheckinRecordDialog> createState() => _CheckinRecordDialogState();
}

class _CheckinRecordDialogState extends State<CheckinRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    final now = DateTime.now();
    _selectedDate = widget.selectedDate ?? now;
    // 无论是否提供selectedDate，都使用当前时间作为默认时间
    _startTime = now;
    _endTime = now;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        // 保持时分不变，只改变年月日
        _startTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _startTime.hour,
          _startTime.minute,
        );
        _endTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _endTime.hour,
          _endTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStartTime ? _startTime : _endTime),
    );

    if (picked != null) {
      setState(() {
        final selectedDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
        if (isStartTime) {
          _startTime = selectedDateTime;
          // 如果开始时间晚于结束时间，更新结束时间
          if (_startTime.isAfter(_endTime)) {
            _endTime = _startTime;
          }
        } else {
          _endTime = selectedDateTime;
          // 如果结束时间早于开始时间，更新开始时间
          if (_endTime.isBefore(_startTime)) {
            _startTime = _endTime;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.selectedDate != null
            ? 'checkin_addSpecificDateCheckin'.tr
            : 'checkin_addCheckinRecord'.tr,
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 日期选择
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppLocalizations.of(context)!.save),
                trailing: TextButton(
                  onPressed: () => _selectDate(context),
                  child: Text(
                    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              // 起始时间选择
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppLocalizations.of(context)!.startTime),
                trailing: TextButton(
                  onPressed: () => _selectTime(context, true),
                  child: Text(
                    '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              // 终止时间选择
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppLocalizations.of(context)!.endTime),
                trailing: TextButton(
                  onPressed: () => _selectTime(context, false),
                  child: Text(
                    '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 备注输入框
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'checkin_noteLabel'.tr,
                  hintText: 'checkin_noteHint'.tr,
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // 打卡时间显示
              Text(
                widget.selectedDate != null
                    ? '${'checkin_checkinDateLabel'.tr}: ${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}'
                    : '${'checkin_checkinTimeLabel'.tr}: ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final now = DateTime.now();
              final record = CheckinRecord(
                startTime: _startTime,
                endTime: _endTime,
                checkinTime: widget.selectedDate != null ? _selectedDate : now,
                note:
                    _noteController.text.trim().isNotEmpty
                        ? _noteController.text.trim()
                        : null,
              );
              widget.item.addCheckinRecord(record);
              widget.onCheckinCompleted();
              widget.controller.notifyEvent('completed', widget.item);
              Navigator.of(context).pop();
            }
          },
          child: Text('checkin_checkinButton'.tr),
        ),
      ],
    );
  }
}
