import 'package:get/get.dart';
import 'dart:io';

import 'package:Memento/widgets/circle_icon_picker.dart';
import 'package:Memento/widgets/image_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/widgets/color_picker_section.dart';
import 'package:Memento/plugins/tracker/models/goal.dart';
import 'package:Memento/plugins/tracker/controllers/tracker_controller.dart';
import 'package:Memento/utils/image_utils.dart';

class GoalEditPage extends StatefulWidget {
  final TrackerController controller;
  final Goal? goal;

  const GoalEditPage({super.key, required this.controller, this.goal});

  @override
  State<GoalEditPage> createState() => _GoalEditPageState();
}

class _GoalEditPageState extends State<GoalEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _groupController = TextEditingController();

  late String _name;
  late String _icon;
  Color? _iconColor;
  Color? _progressColor;
  String _group = '默认';
  String? _imagePath;
  late String _unitType;
  late double _targetValue;
  late String _dateType;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late TimeOfDay? _reminderTime;

  // 分组列表
  List<String> _groups = [];

  @override
  void initState() {
    super.initState();
    // 初始化分组列表
    _groups = widget.controller.getAllGroups();
    if (!_groups.contains('默认')) {
      _groups.add('默认');
    }

    final validDateTypes = ['daily', 'weekly', 'monthly', 'custom'];
    if (widget.goal != null) {
      _name = widget.goal!.name;
      _icon = widget.goal!.icon;
      _group = widget.goal!.group;
      // 确保当前分组在列表中
      if (!_groups.contains(_group)) {
        _groups.add(_group);
      }
      _imagePath = widget.goal!.imagePath;
      _iconColor =
          widget.goal!.iconColor != null
              ? Color(widget.goal!.iconColor!)
              : null;
      _progressColor =
          widget.goal!.progressColor != null
              ? Color(widget.goal!.progressColor!)
              : null;
      _unitType = widget.goal!.unitType;
      _targetValue = widget.goal!.targetValue;
      _dateType =
          validDateTypes.contains(widget.goal!.dateSettings.type)
              ? widget.goal!.dateSettings.type
              : 'daily'; // 默认值
      _startDate = widget.goal!.dateSettings.startDate;
      _endDate = widget.goal!.dateSettings.endDate;
      _reminderTime =
          widget.goal!.reminderTime != null
              ? TimeOfDay.fromDateTime(
                DateTime.parse('1970-01-01 ${widget.goal!.reminderTime!}'),
              )
              : null;
    } else {
      _name = '';
      _icon = '0';
      _iconColor = null;
      _progressColor = null;
      _unitType = '';
      _targetValue = 0;
      _dateType = 'daily'; // 确保初始值与下拉选项匹配
      _startDate = null;
      _endDate = null;
      _reminderTime = null;
    }
  }

  @override
  void dispose() {
    _groupController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _iconColor ??= Theme.of(context).colorScheme.primary;
    _progressColor ??= Theme.of(context).colorScheme.primary;
  }

  // 添加新分组
  void _addNewGroup() async {
    final newGroupController = TextEditingController();
    final newGroup = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('tracker_createGroup'.tr),
            content: TextField(
              controller: newGroupController,
              decoration: InputDecoration(
                labelText: 'tracker_createGroup'.tr,
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('app_cancel'.tr),
              ),
              TextButton(
                onPressed: () {
                  final value = newGroupController.text.trim();
                  if (value.isNotEmpty) {
                    Navigator.pop(context, value);
                  }
                },
                child: Text('app_ok'.tr),
              ),
            ],
          ),
    );

    if (newGroup != null && newGroup.isNotEmpty) {
      setState(() {
        if (!_groups.contains(newGroup)) {
          _groups.add(newGroup);
        }
        _group = newGroup;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goal != null ? '编辑目标' : '添加新目标'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveGoal),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: CircleIconPicker(
                    currentIcon: IconData(
                      int.tryParse(_icon) ?? 0xe145, // 默认使用 add 图标
                      fontFamily: 'MaterialIcons',
                    ),
                    backgroundColor:
                        _iconColor ??
                        Theme.of(context).colorScheme.primaryContainer,
                    onIconSelected: (icon) {
                      setState(() => _icon = icon.codePoint.toString());
                    },
                    onColorSelected: (color) {
                      setState(() => _iconColor = color);
                    },
                  ),
                ),

                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final result = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder:
                            (context) => ImagePickerDialog(
                              initialUrl: _imagePath,
                              saveDirectory: 'tracker/goal_images',
                              enableCrop: true,
                              cropAspectRatio: 9 / 16,
                            ),
                      );
                      if (result != null && result['url'] != null) {
                        setState(() {
                          _imagePath = result['url'] as String;
                        });
                      }
                    },
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child:
                            _imagePath != null && _imagePath!.isNotEmpty
                                ? FutureBuilder<String>(
                                  future: ImageUtils.getAbsolutePath(
                                    _imagePath,
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData &&
                                        snapshot.data!.isNotEmpty) {
                                      return Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.5),
                                            width: 2,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child: Image.file(
                                            File(snapshot.data!),
                                            width: 64,
                                            height: 64,
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.broken_image,
                                                    ),
                                          ),
                                        ),
                                      );
                                    }
                                    return const Icon(Icons.broken_image);
                                  },
                                )
                                : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 24,
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        '图片',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                const SizedBox(height: 8),
                ColorPickerSection(
                  selectedColor:
                      _progressColor ?? Theme.of(context).colorScheme.primary,
                  onColorChanged: (color) {
                    setState(() => _progressColor = color);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 分组选择器
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'tracker_selectGroup'.tr,
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _group,
                        isDense: true,
                        isExpanded: true,
                        items: [
                          ..._groups.map(
                            (group) => DropdownMenuItem(
                              value: group,
                              child: Text(group),
                            ),
                          ),
                          DropdownMenuItem(
                            value: '新建分组',
                            child: Row(
                              children: [
                                const Icon(Icons.add, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'tracker_createGroup'.tr,
                                ),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == '新建分组') {
                            _addNewGroup();
                          } else if (value != null) {
                            setState(() => _group = value);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _name,
              decoration: InputDecoration(
                labelText: 'tracker_goalName'.tr,
              ),
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
              decoration: InputDecoration(
                labelText: 'tracker_unitType'.tr,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入单位';
                }
                return null;
              },
              onSaved: (value) => _unitType = value!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _targetValue.toString(),
              decoration: InputDecoration(
                labelText: 'tracker_targetValue'.tr,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入目标值';
                }
                final numValue = double.tryParse(value);
                if (numValue == null) {
                  return '请输入有效的数字';
                }
                if (numValue <= 0) {
                  return '目标值不能小于等于0';
                }
                return null;
              },
              onSaved: (value) => _targetValue = double.parse(value!),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                _reminderTime == null
                    ? '设置每日提醒时间'
                    : '提醒时间: ${_reminderTime!.format(context)}',
              ),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _reminderTime ?? TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() => _reminderTime = time);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _dateType,
              decoration: InputDecoration(
                labelText: 'tracker_dateSettings'.tr,
              ),
              items:
                  ['none', 'daily', 'weekly', 'monthly', 'custom']
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(_getDateTypeName(type)),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _dateType = value);
                }
              },
            ),
            if (_dateType == 'custom') ...[
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  _startDate == null
                      ? '选择开始日期'
                      : '开始日期: ${_startDate!.toLocal().toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, isStartDate: true),
              ),
              ListTile(
                title: Text(
                  _endDate == null
                      ? '选择结束日期'
                      : '结束日期: ${_endDate!.toLocal().toString().split(' ')[0]}',
                ),
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
      case 'none':
        return '无';
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

  Future<void> _selectDate(
    BuildContext context, {
    required bool isStartDate,
  }) async {
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

  Future<void> _saveGoal() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // 如果 _imagePath 是绝对路径，转换为相对路径
      String? finalImagePath = _imagePath;
      if (_imagePath != null && _imagePath!.isNotEmpty) {
        if (File(_imagePath!).existsSync()) {
          finalImagePath = await ImageUtils.toRelativePath(_imagePath!);
        }
      }

      final newGoal = Goal(
        id: widget.goal?.id ?? const Uuid().v4(),
        name: _name,
        icon: _icon,
        group: _group,
        imagePath: finalImagePath,
        iconColor: _iconColor?.value,
        progressColor: _progressColor?.value,
        unitType: _unitType,
        targetValue: _targetValue,
        currentValue: widget.goal?.currentValue ?? 0,
        dateSettings: DateSettings(
          type: _dateType,
          startDate: _startDate,
          endDate: _endDate,
        ),
        reminderTime: _reminderTime?.format(context),
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
