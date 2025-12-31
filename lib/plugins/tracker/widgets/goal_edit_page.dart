import 'package:get/get.dart';
import 'dart:io' show File;

import 'package:Memento/widgets/picker/circle_icon_picker.dart';
import 'package:Memento/widgets/picker/image_picker_dialog.dart';
import 'package:Memento/widgets/form_fields/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/widgets/picker/color_picker_section.dart';
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
  final _formKey = GlobalKey<FormBuilderState>();
  final _formChangeNotifier = ValueNotifier(0);

  late String _initialIcon;
  late Color _initialIconColor;
  late Color _initialProgressColor;
  late String _initialImagePath;
  late String _initialGroup;
  late String _initialName;
  late String _initialUnitType;
  late double _initialTargetValue;
  late String _initialDateType;
  late TimeOfDay? _initialReminderTime;

  // 分组列表
  List<String> _groups = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // 初始化分组列表
    _groups = widget.controller.getAllGroups();
    if (!_groups.contains('默认')) {
      _groups.add('默认');
    }

    if (widget.goal != null) {
      _initialIcon = widget.goal!.icon;
      _initialGroup = widget.goal!.group;
      // 确保当前分组在列表中
      if (!_groups.contains(_initialGroup)) {
        _groups.add(_initialGroup);
      }
      _initialImagePath = widget.goal!.imagePath ?? '';
      _initialIconColor = widget.goal!.iconColor != null
          ? Color(widget.goal!.iconColor!)
          : Colors.blue;
      _initialProgressColor = widget.goal!.progressColor != null
          ? Color(widget.goal!.progressColor!)
          : Colors.blue;
      _initialUnitType = widget.goal!.unitType;
      _initialTargetValue = widget.goal!.targetValue;
      _initialName = widget.goal!.name;
      _initialDateType = ['daily', 'weekly', 'monthly', 'custom']
          .contains(widget.goal!.dateSettings.type)
          ? widget.goal!.dateSettings.type
          : 'daily';
      _initialReminderTime = widget.goal!.reminderTime != null
          ? TimeOfDay.fromDateTime(
            DateTime.parse('1970-01-01 ${widget.goal!.reminderTime!}'),
          )
          : null;
    } else {
      _initialIcon = '0';
      _initialGroup = '默认';
      _initialImagePath = '';
      _initialIconColor = Colors.blue;
      _initialProgressColor = Colors.blue;
      _initialUnitType = '';
      _initialTargetValue = 0;
      _initialName = '';
      _initialDateType = 'daily';
      _initialReminderTime = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final primaryColor = Theme.of(context).colorScheme.primary;
    _initialIconColor = _initialIconColor == Colors.blue ? primaryColor : _initialIconColor;
    _initialProgressColor = _initialProgressColor == Colors.blue ? primaryColor : _initialProgressColor;
  }

  @override
  void dispose() {
    _formChangeNotifier.dispose();
    super.dispose();
  }

  // 获取当前表单值
  Map<String, dynamic> get _currentValues {
    return _formKey.currentState?.value ?? {};
  }

  // 添加新分组
  Future<void> _addNewGroup() async {
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
        _initialGroup = newGroup;
        // 更新表单中的分组值
        _updateFormValue('group', newGroup);
      });
    }
  }

  // 构建顶部自定义区域（图标+图片并排）
  Widget _buildTopSection(Map<String, dynamic> currentValues) {
    final iconData = currentValues['iconData'] as Map<String, dynamic>?;
    final icon = iconData?['icon'] as IconData?;
    final iconColor = iconData?['color'] as Color? ?? _initialIconColor;
    final imagePath = currentValues['imagePath'] as String? ?? _initialImagePath;
    final progressColor = currentValues['progressColor'] as Color? ?? _initialProgressColor;

    return Column(
      children: [
        // 图标和图片并排
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: CircleIconPicker(
                currentIcon: icon ?? IconData(
                  int.tryParse(_initialIcon) ?? 0xe145,
                  fontFamily: 'MaterialIcons',
                ),
                backgroundColor: iconColor,
                onIconSelected: (selectedIcon) {
                  _updateFormValues({
                    'iconData': {'icon': selectedIcon, 'color': iconColor}
                  });
                },
                onColorSelected: (color) {
                  _updateFormValues({
                    'iconData': {'icon': icon, 'color': color}
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => ImagePickerDialog(
                      initialUrl: imagePath.isNotEmpty ? imagePath : null,
                      saveDirectory: 'tracker/goal_images',
                      enableCrop: true,
                      cropAspectRatio: 9 / 16,
                    ),
                  );
                  if (result != null && result['url'] != null) {
                    _updateFormValue('imagePath', result['url'] as String);
                  }
                },
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: imagePath.isNotEmpty
                        ? FutureBuilder<String>(
                          future: ImageUtils.getAbsolutePath(imagePath),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                              return ClipOval(
                                child: Image.file(
                                  File(snapshot.data!),
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image),
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
                              Icon(Icons.add_photo_alternate_outlined, size: 24),
                              SizedBox(height: 2),
                              Text('图片', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 进度颜色选择器
        ColorPickerSection(
          selectedColor: progressColor,
          onColorChanged: (color) {
            _updateFormValue('progressColor', color);
          },
        ),
      ],
    );
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
      body: FormBuilderWrapper(
        formKey: _formKey,
        config: FormConfig(
          showSubmitButton: false,
          showResetButton: false,
          fieldSpacing: 16,
          fields: [
            // 分组选择器
            FormFieldConfig(
              name: 'group',
              type: FormFieldType.select,
              initialValue: _initialGroup,
              items: [
                ..._groups.map(
                  (group) => DropdownMenuItem(
                    value: group,
                    child: Text(group),
                  ),
                ),
                DropdownMenuItem(
                  value: '__create_new__',
                  child: Row(
                    children: [
                      const Icon(Icons.add, size: 16),
                      const SizedBox(width: 8),
                      Text('tracker_createGroup'.tr),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == '__create_new__') {
                  _addNewGroup();
                }
              },
            ),

            // 目标名称
            FormFieldConfig(
              name: 'name',
              type: FormFieldType.text,
              labelText: 'tracker_goalName'.tr,
              initialValue: _initialName,
              required: true,
              validationMessage: '请输入目标名称',
            ),

            // 单位
            FormFieldConfig(
              name: 'unitType',
              type: FormFieldType.text,
              labelText: 'tracker_unitType'.tr,
              initialValue: _initialUnitType,
              required: true,
              validationMessage: '请输入单位',
            ),

            // 目标值
            FormFieldConfig(
              name: 'targetValue',
              type: FormFieldType.text,
              labelText: 'tracker_targetValue'.tr,
              initialValue: _initialTargetValue > 0 ? _initialTargetValue.toString() : '',
              required: true,
              validationMessage: '请输入目标值',
            ),

            // 提醒日期选择器
            FormFieldConfig(
              name: 'reminderDate',
              type: FormFieldType.reminderDate,
              initialValue: _initialReminderTime != null
                  ? ReminderDateData(
                      type: ReminderDateType.daily,
                      selectedDays: [1, 2, 3, 4, 5, 6, 7],
                      time: _initialReminderTime,
                    )
                  : const ReminderDateData(type: ReminderDateType.none),
            ),
          ],
          onSubmit: (values) => _handleSubmit(values),
        ),
        // 使用 contentBuilder 添加顶部自定义区域和自定义布局
        contentBuilder: (context, allFields) {
          return ValueListenableBuilder(
            valueListenable: _formChangeNotifier,
            builder: (context, _,__) {
              final formValues = _currentValues;

              // 字段顺序：0: group, 1: name, 2: unitType, 3: targetValue, 4: reminderDate
              final groupField = allFields[0];
              final nameField = allFields[1];
              final unitTypeField = allFields[2];
              final targetValueField = allFields[3];
              final reminderDateField = allFields[4];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopSection(formValues),
                    const SizedBox(height: 24),

                    // 第一行：名称和分组平分宽度
                    Row(
                      children: [
                        Expanded(child: nameField),
                        const SizedBox(width: 12),
                        Expanded(child: groupField),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 第二行：目标值和单位平分宽度
                    Row(
                      children: [
                        Expanded(child: targetValueField),
                        const SizedBox(width: 12),
                        Expanded(child: unitTypeField),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 提醒日期选择器
                    reminderDateField,
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }


  void _handleSubmit(Map<String, dynamic> values) {
    // 处理逻辑由 _saveGoal 直接调用
  }

  Future<void> _saveGoal() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;

      // 获取图标数据
      final iconData = values['iconData'] as Map<String, dynamic>?;
      final icon = iconData?['icon'] as IconData?;
      final iconColor = iconData?['color'] as Color?;

      // 获取图片路径并转换为相对路径
      String? finalImagePath = values['imagePath'] as String?;
      if (finalImagePath != null && finalImagePath.isNotEmpty) {
        if (File(finalImagePath).existsSync()) {
          finalImagePath = await ImageUtils.toRelativePath(finalImagePath);
        }
      }

      final name = values['name'] as String? ?? _initialName;
      final unitType = values['unitType'] as String? ?? _initialUnitType;
      final targetValue = double.tryParse(values['targetValue']?.toString() ?? '') ?? _initialTargetValue;
      final group = values['group'] as String? ?? _initialGroup;
      final progressColor = values['progressColor'] as Color?;

      // 获取提醒时间（从 reminderDate 字段解析）
      String? reminderTime;
      final reminderDateMap = values['reminderDate'] as Map<String, dynamic>?;
      if (reminderDateMap != null) {
        final typeIndex = reminderDateMap['type'] as int?;
        // 仅在非 none 模式（type != 0）时获取时间
        if (typeIndex != null && typeIndex != 0) {
          final timeStr = reminderDateMap['time'] as String?;
          if (timeStr != null && timeStr.isNotEmpty) {
            reminderTime = timeStr;
          }
        }
      }

      final newGoal = Goal(
        id: widget.goal?.id ?? const Uuid().v4(),
        name: name,
        icon: icon?.codePoint.toString() ?? _initialIcon,
        group: group,
        imagePath: finalImagePath?.isNotEmpty == true ? finalImagePath : null,
        iconColor: iconColor?.value,
        progressColor: progressColor?.value,
        unitType: unitType,
        targetValue: targetValue,
        currentValue: widget.goal?.currentValue ?? 0,
        dateSettings: DateSettings(
          type: _initialDateType,
          startDate: null,
          endDate: null,
        ),
        reminderTime: reminderTime,
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

  // 更新表单值并通知
  void _updateFormValue(String key, dynamic value) {
    _formKey.currentState?.patchValue({key: value});
    _formChangeNotifier.value++;
  }

  // 更新多个表单值并通知
  void _updateFormValues(Map<String, dynamic> values) {
    _formKey.currentState?.patchValue(values);
    _formChangeNotifier.value++;
  }
}
