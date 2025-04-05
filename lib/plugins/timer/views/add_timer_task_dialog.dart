import 'package:flutter/material.dart';
import '../models/timer_task.dart';
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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final List<TimerItem> _timerItems;
  late Color _selectedColor;
  late IconData _selectedIcon;
  late String? _selectedGroup;

  @override
  void initState() {
    super.initState();
    final initialTask = widget.initialTask;
    if (initialTask != null) {
      _nameController = TextEditingController(text: initialTask.name);
      _timerItems = List.from(initialTask.timerItems);
      _selectedColor = initialTask.color;
      _selectedIcon = initialTask.icon;
      _selectedGroup = initialTask.group;
    } else {
      _nameController = TextEditingController();
      _timerItems = [];
      _selectedColor = Colors.blue;
      _selectedIcon = Icons.timer;
      _selectedGroup = null;
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
                decoration: const InputDecoration(
                  labelText: '任务名称',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入任务名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 分组选择
              DropdownButtonFormField<String>(
                value: _selectedGroup,
                decoration: const InputDecoration(
                  labelText: '选择分组',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('默认')),
                  ...widget.groups.map(
                    (group) =>
                        DropdownMenuItem(value: group, child: Text(group)),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGroup = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 计时器列表
              ..._timerItems.map((timer) => _buildTimerItemTile(timer)),

              // 添加计时器按钮
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('添加计时器'),
                onPressed: _showAddTimerDialog,
              ),
              const SizedBox(height: 16),

              // 确认和取消按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _timerItems.isEmpty ? null : _submit,
                    child: const Text('确认'),
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
        typeText = '正计时';
        break;
      case TimerType.countDown:
        icon = Icons.hourglass_empty;
        typeText = '倒计时';
        break;
      case TimerType.pomodoro:
        icon = Icons.local_cafe;
        typeText = '番茄钟';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(timer.name),
        subtitle: Text('$typeText - ${_formatDuration(timer.duration)}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => setState(() => _timerItems.remove(timer)),
        ),
      ),
    );
  }

  void _showAddTimerDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddTimerItemDialog(),
    ).then((timer) {
      if (timer != null) {
        setState(() => _timerItems.add(timer));
      }
    });
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final task = TimerTask.create(
        name: _nameController.text,
        color: _selectedColor,
        icon: _selectedIcon,
        timerItems: _timerItems,
        group: _selectedGroup,
      );
      Navigator.of(context).pop(task);
    }
  }

  // 删除 _showIconSelectionDialog 方法，因为我们现在使用 CircleIconPicker

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

class _AddTimerItemDialog extends StatefulWidget {
  @override
  _AddTimerItemDialogState createState() => _AddTimerItemDialogState();
}

class _AddTimerItemDialogState extends State<_AddTimerItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  TimerType _selectedType = TimerType.countUp;

  int _hours = 0;
  int _minutes = 25;
  int _seconds = 0;

  // 番茄钟特有设置
  int _workMinutes = 25;
  int _breakMinutes = 5;
  int _cycles = 4;

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

              // 计时器类型选择
              DropdownButtonFormField<TimerType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: '计时器类型',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: TimerType.countUp,
                    child: Text('正计时'),
                  ),
                  DropdownMenuItem(
                    value: TimerType.countDown,
                    child: Text('倒计时'),
                  ),
                  DropdownMenuItem(
                    value: TimerType.pomodoro,
                    child: Text('番茄钟'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedType = value!);
                },
              ),
              const SizedBox(height: 16),

              // 根据不同类型显示不同的设置选项
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

              // 确认和取消按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _submit, child: const Text('确认')),
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

      switch (_selectedType) {
        case TimerType.countUp:
          timer = TimerItem.countUp(
            name: _nameController.text,
            targetDuration: Duration(
              hours: _hours,
              minutes: _minutes,
              seconds: _seconds,
            ),
          );
          break;

        case TimerType.countDown:
          timer = TimerItem.countDown(
            name: _nameController.text,
            duration: Duration(
              hours: _hours,
              minutes: _minutes,
              seconds: _seconds,
            ),
          );
          break;

        case TimerType.pomodoro:
          timer = TimerItem.pomodoro(
            name: _nameController.text,
            workDuration: Duration(minutes: _workMinutes),
            breakDuration: Duration(minutes: _breakMinutes),
            cycles: _cycles,
          );
          break;
      }

      Navigator.of(context).pop(timer);
    }
  }
}
