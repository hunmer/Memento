import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/timer/l10n/timer_localizations.dart';
import 'package:Memento/plugins/timer/models/timer_item.dart';
import 'package:Memento/core/services/timer/models/timer_state.dart';
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
      _nameController = TextEditingController();
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在这里设置默认名称，确保 context 可用
    if (_nameController.text.isEmpty && widget.initialItem == null) {
      _nameController.text = _getTimerTypeName(_selectedType);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF181D2C) : Colors.white;
    final primaryColor = const Color(0xFF607AFB);

    return Dialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.initialItem != null ? '编辑子计时器' : '添加子计时器',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 计时器名称
              _buildLabel(context, TimerLocalizations.of(context).timerName),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: _buildInputDecoration(context, isDark: isDark),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入${TimerLocalizations.of(context).timerName}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 描述
              _buildLabel(
                context,
                TimerLocalizations.of(context).timerDescription,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: _buildInputDecoration(context, isDark: isDark),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // 计时器类型选择
              _buildLabel(context, TimerLocalizations.of(context).timerType),
              const SizedBox(height: 8),
              DropdownButtonFormField<TimerType>(
                value: _selectedType,
                dropdownColor: isDark ? const Color(0xFF181D2C) : Colors.white,
                decoration: _buildInputDecoration(context, isDark: isDark),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                items: [
                  DropdownMenuItem(
                    value: TimerType.countUp,
                    child: Text(TimerLocalizations.of(context).countUpTimer),
                  ),
                  DropdownMenuItem(
                    value: TimerType.countDown,
                    child: Text(TimerLocalizations.of(context).countDownTimer),
                  ),
                  DropdownMenuItem(
                    value: TimerType.pomodoro,
                    child: Text(TimerLocalizations.of(context).pomodoroTimer),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedType = value!);
                },
              ),
              const SizedBox(height: 16),

              // 重复次数设置
              _buildLabel(context, TimerLocalizations.of(context).repeatCount),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _repeatCount.toString(),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: _buildInputDecoration(context, isDark: isDark),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(
                            context,
                            TimerLocalizations.of(context).hours,
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            initialValue: _hours.toString(),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            decoration: _buildInputDecoration(
                              context,
                              isDark: isDark,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged:
                                (value) => _hours = int.tryParse(value) ?? 0,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(
                            context,
                            TimerLocalizations.of(context).minutes,
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            initialValue: _minutes.toString(),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            decoration: _buildInputDecoration(
                              context,
                              isDark: isDark,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged:
                                (value) => _minutes = int.tryParse(value) ?? 0,
                          ),
                        ]
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(
                            context,
                            TimerLocalizations.of(context).seconds,
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            initialValue: _seconds.toString(),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            decoration: _buildInputDecoration(
                              context,
                              isDark: isDark,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged:
                                (value) => _seconds = int.tryParse(value) ?? 0,
                          ),
                        ]
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // 番茄钟设置
                _buildLabel(
                  context,
                  TimerLocalizations.of(context).workDuration,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _workMinutes.toString(),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: _buildInputDecoration(context, isDark: isDark),
                  keyboardType: TextInputType.number,
                  onChanged:
                      (value) => _workMinutes = int.tryParse(value) ?? 25,
                ),
                const SizedBox(height: 16),
                _buildLabel(
                  context,
                  TimerLocalizations.of(context).breakDuration,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _breakMinutes.toString(),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: _buildInputDecoration(context, isDark: isDark),
                  keyboardType: TextInputType.number,
                  onChanged:
                      (value) => _breakMinutes = int.tryParse(value) ?? 5,
                ),
                const SizedBox(height: 16),
                _buildLabel(context, TimerLocalizations.of(context).cycleCount),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _cycles.toString(),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: _buildInputDecoration(context, isDark: isDark),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _cycles = int.tryParse(value) ?? 4,
                ),
              ],
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    TimerLocalizations.of(context).enableNotification,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  Switch.adaptive(
                    value: _enableNotification,
                    activeColor: primaryColor,
                    onChanged: (value) {
                      setState(() {
                        _enableNotification = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 确认和取消按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          isDark ? Colors.white70 : Colors.grey[600],
                    ),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
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

  Widget _buildLabel(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.grey[500] : Colors.grey[600],
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    BuildContext context, {
    bool isDark = false,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF607AFB), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        return TimerLocalizations.of(context).countUpTimer;
      case TimerType.countDown:
        return TimerLocalizations.of(context).countDownTimer;
      case TimerType.pomodoro:
        return TimerLocalizations.of(context).pomodoroTimer;
    }
  }
}
