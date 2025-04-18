import 'package:flutter/material.dart';
import '../models/checkin_item.dart';

class CheckinRecordDialog extends StatefulWidget {
  final CheckinItem checkinItem;

  const CheckinRecordDialog({
    super.key,
    required this.checkinItem,
  });

  @override
  State<CheckinRecordDialog> createState() => _CheckinRecordDialogState();
}

class _CheckinRecordDialogState extends State<CheckinRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _noteController;
  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    final now = DateTime.now();
    _startTime = now;
    _endTime = now;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStartTime ? _startTime : _endTime),
    );

    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        final selectedDateTime = DateTime(
          now.year,
          now.month,
          now.day,
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
      title: const Text('添加打卡记录'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 起始时间选择
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('起始时间'),
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
                title: const Text('终止时间'),
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
                decoration: const InputDecoration(
                  labelText: '备注',
                  hintText: '请输入备注（可选）',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // 打卡时间显示
              Text(
                '打卡时间：${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
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
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final now = DateTime.now();
              final record = CheckinRecord(
                startTime: _startTime,
                endTime: _endTime,
                checkinTime: now,
                note: _noteController.text.trim().isNotEmpty 
                    ? _noteController.text.trim() 
                    : null,
              );
              Navigator.of(context).pop(record);
            }
          },
          child: const Text('打卡'),
        ),
      ],
    );
  }
}