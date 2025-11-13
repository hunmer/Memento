import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/timer/l10n/timer_localizations.dart';
import 'package:Memento/plugins/timer/views/add_timer_item_dialog.dart';
import 'package:Memento/widgets/group_selector_dialog.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/timer_task.dart' show TimerTask;
import '../models/timer_item.dart';
import '../../../widgets/circle_icon_picker.dart';

class AddTimerTaskDialog extends StatefulWidget {
  final List<String> groups;
  final TimerTask? initialTask;

  const AddTimerTaskDialog({super.key, required this.groups, this.initialTask});

  @override
  _AddTimerTaskDialogState createState() => _AddTimerTaskDialogState();
}

class _AddTimerTaskDialogState extends State<AddTimerTaskDialog> {
  bool _enableNotification = false;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final List<TimerItem> _timerItems;
  late final String _id;
  late Color _selectedColor;
  late IconData _selectedIcon;
  late String? _selectedGroup;
  late int _repeatCount;
  @override
  void initState() {
    super.initState();
    final initialTask = widget.initialTask;
    if (initialTask != null) {
      _id = initialTask.id;
      _nameController = TextEditingController(text: initialTask.name);
      _timerItems = List.from(initialTask.timerItems);
      _selectedColor = initialTask.color;
      _selectedIcon = initialTask.icon;
      _selectedGroup = initialTask.group;
      _repeatCount = initialTask.repeatCount;
    } else {
      _id = Uuid().v4();
      _nameController = TextEditingController();
      _timerItems = [];
      _selectedColor = Colors.blue;
      _selectedIcon = Icons.timer;
      _selectedGroup = null;
      _repeatCount = 1;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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
                widget.initialTask != null ? '编辑计时器任务' : '新建计时器任务',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // 图标选择器
              Center(
                child: CircleIconPicker(
                  currentIcon: _selectedIcon,
                  backgroundColor: _selectedColor,
                  onIconSelected: (IconData icon) {
                    setState(() {
                      _selectedIcon = icon;
                    });
                  },
                  onColorSelected: (Color color) {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              // 任务名称输入
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: TimerLocalizations.of(context).taskName,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入${TimerLocalizations.of(context).taskName}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 重复次数设置
              TextFormField(
                initialValue: '$_repeatCount',
                decoration: InputDecoration(
                  labelText: TimerLocalizations.of(context).repeatCount,
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
                    final count = int.tryParse(value) ?? 1;
                    setState(() {
                      _repeatCount = count.clamp(1, 100);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // 分组选择
              InputDecorator(
                decoration: InputDecoration(
                  labelText: TimerLocalizations.of(context).selectGroup,
                  border: OutlineInputBorder(),
                ),
                child: InkWell(
                  onTap: () async {
                    final selectedGroup = await showDialog<String>(
                      context: context,
                      builder:
                          (context) => GroupSelectorDialog(
                            groups: widget.groups,
                            initialSelectedGroup: _selectedGroup,
                            onGroupRenamed: (oldName, newName) {
                              setState(() {
                                if (_selectedGroup == oldName) {
                                  _selectedGroup = newName;
                                }
                              });
                              // TODO: 这里需要添加更新所有相关任务分组的逻辑
                            },
                            onGroupDeleted: (groupName) {
                              setState(() {
                                if (_selectedGroup == groupName) {
                                  _selectedGroup = null;
                                }
                              });
                              // TODO: 这里需要添加删除分组后更新所有相关任务分组的逻辑
                            },
                          ),
                    );
                    if (selectedGroup != null) {
                      setState(() {
                        _selectedGroup = selectedGroup;
                      });
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedGroup ?? '未选择分组',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 计时器列表
              ..._timerItems.map((timer) => _buildTimerItemTile(timer)),
              const SizedBox(height: 16),

              // 添加计时器按钮
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: Text(TimerLocalizations.of(context).addTimer),
                onPressed: _showAddTimerDialog,
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                title: Text(TimerLocalizations.of(context).enableNotification),
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
                    onPressed: _timerItems.isEmpty ? null : _submit,
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

  Widget _buildTimerItemTile(TimerItem timer) {
    IconData icon;
    String typeText;

    switch (timer.type) {
      case TimerType.countUp:
        icon = Icons.timer;
        typeText = TimerLocalizations.of(context).countUpTimer;
        break;
      case TimerType.countDown:
        icon = Icons.hourglass_empty;
        typeText = TimerLocalizations.of(context).countDownTimer;
        break;
      case TimerType.pomodoro:
        icon = Icons.local_cafe;
        typeText = TimerLocalizations.of(context).pomodoroTimer;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(timer.name.isEmpty ? typeText : timer.name),
        subtitle: Text('$typeText - ${_formatDuration(timer.duration)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editTimerItem(timer),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => setState(() => _timerItems.remove(timer)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTimerDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTimerItemDialog(),
    ).then((editedTimer) {
      if (editedTimer != null) {
        setState(() => _timerItems.add(editedTimer));
      }
    });
  }

  void _editTimerItem(TimerItem timer) {
    final index = _timerItems.indexOf(timer);
    showDialog(
      context: context,
      builder: (context) => AddTimerItemDialog(initialItem: timer),
    ).then((editedTimer) {
      if (editedTimer != null) {
        setState(() {
          _timerItems[index] = editedTimer;
        });
      }
    });
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final task = TimerTask.create(
        id: _id,
        name: _nameController.text,
        color: _selectedColor,
        icon: _selectedIcon,
        timerItems: _timerItems,
        group: _selectedGroup,
        repeatCount: _repeatCount,
        enableNotification: _enableNotification,
      );
      Navigator.of(context).pop(task);
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
