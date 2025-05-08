
import 'package:Memento/widgets/icon_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/tracker/models/goal.dart';
import 'package:Memento/plugins/tracker/controllers/tracker_controller.dart';

class GoalEditPage extends StatefulWidget {
  final TrackerController controller;
  final Goal? goal;

  const GoalEditPage({
    Key? key,
    required this.controller,
    this.goal,
  }) : super(key: key);

  @override
  _GoalEditPageState createState() => _GoalEditPageState();
}

class _GoalEditPageState extends State<GoalEditPage> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _icon;
  late String _unitType;
  late double _targetValue;
  late String _dateType;
  late DateTime? _startDate;
  late DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _name = widget.goal!.name;
      _icon = widget.goal!.icon;
      _unitType = widget.goal!.unitType;
      _targetValue = widget.goal!.targetValue;
      _dateType = widget.goal!.dateSettings.type;
      _startDate = widget.goal!.dateSettings.startDate;
      _endDate = widget.goal!.dateSettings.endDate;
    } else {
      _name = '';
      _icon = '0';
      _unitType = '';
      _targetValue = 0;
      _dateType = 'daily';
      _startDate = null;
      _endDate = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goal != null ? '编辑目标' : '添加新目标'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveGoal,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(labelText: '目标名称'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入目标名称';
                }
                return null;
              },
              onSaved: (value) => _name = value!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _unitType,
              decoration: const InputDecoration(labelText: '单位(如: 次、ml、分钟等)'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入单位';
                }
                return null;
              },
              onSaved: (value) => _unitType = value!,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('选择图标'),
              leading: Icon(IconData(int.parse(_icon), fontFamily: 'MaterialIcons')),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () async {
                final selectedIcon = await showDialog<IconData>(
                  context: context,
                  builder: (context) => IconPickerDialog(
                    currentIcon: IconData(int.parse(_icon), fontFamily: 'MaterialIcons'),
                  ),
                );
                if (selectedIcon != null) {
                  setState(() => _icon = selectedIcon.codePoint.toString());
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _targetValue.toString(),
              decoration: const InputDecoration(labelText: '目标值'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入目标值';
                }
                if (double.tryParse(value) == null) {
                  return '请输入有效的数字';
                }
                return null;
              },
              onSaved: (value) => _targetValue = double.parse(value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _dateType,
              decoration: const InputDecoration(labelText: '时间类型'),
              items: ['daily', 'weekly', 'monthly', 'custom']
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(_getDateTypeName(type)),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _dateType = value!),
            ),
            if (_dateType == 'custom') ...[
              const SizedBox(height: 16),
              ListTile(
                title: Text(_startDate == null
                    ? '选择开始日期'
                    : '开始日期: ${_startDate!.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, isStartDate: true),
              ),
              ListTile(
                title: Text(_endDate == null
                    ? '选择结束日期'
                    : '结束日期: ${_endDate!.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, isStartDate: false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDateTypeName(String type) {
    switch (type) {
      case 'daily':
        return '每日';
      case 'weekly':
        return '每周';
      case 'monthly':
        return '每月';
      case 'custom':
        return '自定义';
      default:
        return type;
    }
  }

  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final newGoal = Goal(
        id: widget.goal?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _name,
        icon: _icon,
        unitType: _unitType,
        targetValue: _targetValue,
        currentValue: widget.goal?.currentValue ?? 0,
        dateSettings: DateSettings(
          type: _dateType,
          startDate: _startDate,
          endDate: _endDate,
        ),
        reminderTime: null,
        isLoopReset: false,
        createdAt: widget.goal?.createdAt ?? DateTime.now(),
      );

      if (widget.goal != null) {
        widget.controller.updateGoal(newGoal.id, newGoal);
      } else {
        widget.controller.addGoal(newGoal);
      }

      Navigator.pop(context);
    }
  }
}
