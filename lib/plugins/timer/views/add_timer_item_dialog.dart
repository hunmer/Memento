import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/timer/l10n/timer_localizations.dart';
import 'package:Memento/plugins/timer/models/timer_item.dart';
import 'package:flutter/material.dart';

class AddTimerItemDialog extends StatefulWidget {
  final TimerItem? initialItem;

  const AddTimerItemDialog({super.key, this.initialItem});

  @override
  _AddTimerItemDialogState createState() => _AddTimerItemDialogState();
}

class _AddTimerItemDialogState extends State<AddTimerItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late TimerType _selectedType;
  late int _hours;
  late int _minutes;
  late int _seconds;
  late int _workMinutes;
  late int _breakMinutes;
  late int _cycles;
  late int _repeatCount;
  late bool _enableNotification = false;

  @override
  void initState() {
    super.initState();
    final initialItem = widget.initialItem;
    if (initialItem != null) {
      _nameController = TextEditingController(text: initialItem.name);
      _descriptionController = TextEditingController(
        text: initialItem.description,
      );
      _selectedType = initialItem.type;
      _repeatCount = initialItem.repeatCount;
      _enableNotification = initialItem.enableNotification;
      switch (initialItem.type) {
        case TimerType.countUp:
        case TimerType.countDown:
          _hours = initialItem.duration.inHours;
          _minutes = initialItem.duration.inMinutes.remainder(60);
          _seconds = initialItem.duration.inSeconds.remainder(60);
          break;
        case TimerType.pomodoro:
          _workMinutes = initialItem.workDuration?.inMinutes ?? 25;
          _breakMinutes = initialItem.breakDuration?.inMinutes ?? 5;
          _cycles = initialItem.cycles ?? 4;
          break;
      }
    } else {
      _selectedType = TimerType.countUp;
      _nameController = TextEditingController(
        text: _getTimerTypeName(_selectedType),
      );
      _descriptionController = TextEditingController();
      _hours = 0;
      _minutes = 25;
      _seconds = 0;
      _workMinutes = 25;
      _breakMinutes = 5;
      _cycles = 4;
      _repeatCount = 1;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '添加计时器',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // 计时器名称
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '计时器名称',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入计时器名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 计时器名称
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '计时器描述',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // 计时器类型选择
              DropdownButtonFormField<TimerType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: '计时器类型',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: TimerType.countUp,
                    child: Text(TimerLocalizations.of(context)!.countUpTimer),
                  ),
                  DropdownMenuItem(
                    value: TimerType.countDown,
                    child: Text(TimerLocalizations.of(context)!.countDownTimer),
                  ),
                  DropdownMenuItem(
                    value: TimerType.pomodoro,
                    child: Text(TimerLocalizations.of(context)!.pomodoroTimer),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedType = value!);
                },
              ),
              const SizedBox(height: 16),

              // 根据不同类型显示不同的设置选项
              // 重复次数设置
              TextFormField(
                initialValue: _repeatCount.toString(),
                decoration: const InputDecoration(
                  labelText: '重复次数',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入重复次数';
                  }
                  final count = int.tryParse(value);
                  if (count == null || count < 1) {
                    return '重复次数必须大于0';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    _repeatCount = int.tryParse(value) ?? 1;
                  }
                },
              ),
              const SizedBox(height: 16),

              if (_selectedType != TimerType.pomodoro) ...[
                // 时间设置
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _hours.toString(),
                        decoration: const InputDecoration(
                          labelText: '小时',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _hours = int.tryParse(value) ?? 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: _minutes.toString(),
                        decoration: const InputDecoration(
                          labelText: '分钟',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged:
                            (value) => _minutes = int.tryParse(value) ?? 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: _seconds.toString(),
                        decoration: const InputDecoration(
                          labelText: '秒',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged:
                            (value) => _seconds = int.tryParse(value) ?? 0,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // 番茄钟设置
                TextFormField(
                  initialValue: _workMinutes.toString(),
                  decoration: const InputDecoration(
                    labelText: '工作时长（分钟）',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged:
                      (value) => _workMinutes = int.tryParse(value) ?? 25,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _breakMinutes.toString(),
                  decoration: const InputDecoration(
                    labelText: '休息时长（分钟）',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged:
                      (value) => _breakMinutes = int.tryParse(value) ?? 5,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _cycles.toString(),
                  decoration: const InputDecoration(
                    labelText: '循环次数',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _cycles = int.tryParse(value) ?? 4,
                ),
              ],
              const SizedBox(height: 16),

              SwitchListTile(
                title: Text(TimerLocalizations.of(context)!.enableNotification),
                value: _enableNotification,
                onChanged: (value) {
                  setState(() {
                    _enableNotification = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 确认和取消按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submit,
                    child: Text(AppLocalizations.of(context)!.ok),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      TimerItem timer;
      final name =
          _nameController.text.isEmpty
              ? _getTimerTypeName(_selectedType)
              : _nameController.text;

      switch (_selectedType) {
        case TimerType.countUp:
          timer = TimerItem.countUp(
            name: name,
            targetDuration: Duration(
              hours: _hours,
              minutes: _minutes,
              seconds: _seconds,
            ),
          );
          break;

        case TimerType.countDown:
          timer = TimerItem.countDown(
            name: name,
            duration: Duration(
              hours: _hours,
              minutes: _minutes,
              seconds: _seconds,
            ),
          );
          break;

        case TimerType.pomodoro:
          timer = TimerItem.pomodoro(
            name: name,
            workDuration: Duration(minutes: _workMinutes),
            breakDuration: Duration(minutes: _breakMinutes),
            cycles: _cycles,
          );
          break;
      }
      timer.description = _descriptionController.text;
      timer.repeatCount = _repeatCount;
      timer.enableNotification = _enableNotification;
      Navigator.of(context).pop(timer);
    }
  }

  String _getTimerTypeName(TimerType type) {
    switch (type) {
      case TimerType.countUp:
        return TimerLocalizations.of(context)!.countUpTimer;
      case TimerType.countDown:
        return TimerLocalizations.of(context)!.countDownTimer;
      case TimerType.pomodoro:
        return TimerLocalizations.of(context)!.pomodoroTimer;
    }
  }
}
