import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';

import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/plugins/habits/habits_plugin.dart';
import 'package:Memento/plugins/habits/models/habit.dart';
import 'package:Memento/plugins/habits/models/skill.dart';
import 'package:Memento/plugins/habits/utils/habits_utils.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/widgets/form_fields/form_builder_wrapper.dart';
import 'package:Memento/widgets/picker/circle_icon_picker.dart';
import 'package:Memento/widgets/picker/image_picker_dialog.dart';

class HabitForm extends StatefulWidget {
  final Habit? initialHabit;
  final Function(Habit) onSave;

  const HabitForm({super.key, this.initialHabit, required this.onSave});

  @override
  State<HabitForm> createState() => _HabitFormState();
}

class _HabitFormState extends State<HabitForm> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  List<Skill> _skills = [];

  @override
  void initState() {
    super.initState();
    _loadSkills();
    // 设置路由上下文
    _updateRouteContext();
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.initialHabit;

    return FormBuilderWrapper(
      formKey: _formKey,
      config: FormConfig(
        fields: [
          // 图片选择器
          FormFieldConfig(
            name: 'image',
            type: FormFieldType.imagePicker,
            initialValue: habit?.image,
            extra: {
              'saveDirectory': 'habits/habit_images',
              'enableCrop': true,
              'cropAspectRatio': 1.0,
            },
          ),
          // 圆形图标选择器
          FormFieldConfig(
            name: 'icon',
            type: FormFieldType.circleIconPicker,
            initialValue: habit?.icon != null
                ? {
                    'icon': IconData(int.parse(habit!.icon!), fontFamily: 'MaterialIcons'),
                    'color': Colors.blue,
                  }
                : {
                    'icon': Icons.check_rounded,
                    'color': Colors.blue,
                  },
            extra: {
              'initialBackgroundColor': Colors.blue,
            },
          ),
          // 标题
          FormFieldConfig(
            name: 'title',
            type: FormFieldType.text,
            labelText: 'habits_title'.tr,
            initialValue: habit?.title ?? '',
            required: true,
            validationMessage: 'habits_pleaseEnterTitle'.tr,
          ),
          // 备注
          FormFieldConfig(
            name: 'notes',
            type: FormFieldType.textArea,
            labelText: 'habits_notes'.tr,
            initialValue: habit?.notes ?? '',
            extra: {
              'minLines': 3,
              'maxLines': 5,
            },
          ),
          // 分组
          FormFieldConfig(
            name: 'group',
            type: FormFieldType.text,
            labelText: 'habits_group'.tr,
            initialValue: habit?.group ?? '',
          ),
          // 时长
          FormFieldConfig(
            name: 'durationMinutes',
            type: FormFieldType.number,
            labelText: '${'habits_duration'.tr} (${'habits_minutes'.tr})',
            initialValue: habit?.durationMinutes ?? 30,
          ),
          // 技能选择
          FormFieldConfig(
            name: 'skillId',
            type: FormFieldType.select,
            labelText: 'habits_skill'.tr,
            initialValue: _skills.any((s) => s.id == habit?.skillId) ? habit?.skillId : null,
            required: true,
            validationMessage: 'habits_selectSkill'.tr,
            items: _buildSkillItems(),
          ),
        ],
        submitButtonText: 'habits_save'.tr,
        showSubmitButton: true,
        showResetButton: false,
        fieldSpacing: 16,
        onSubmit: _handleSubmit,
        onValidationFailed: (errors) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('请检查输入：${errors.values.join(", ")}')),
          );
        },
      ),
      contentBuilder: (context, fields) {
        // 自定义布局：图片和图标选择器并排显示
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图片和图标选择器并排显示
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: _buildImagePicker(habit?.image)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildIconPicker(habit)),
                ],
              ),
              const SizedBox(height: 24),
              // 其他字段
              ...fields.skip(2), // 跳过图片和图标选择器字段
            ],
          ),
        );
      },
    );
  }

  /// 构建图片选择器
  Widget _buildImagePicker(String? initialImage) {
    return _ImagePickerWidget(
      initialImage: initialImage,
      onImageChanged: (image) {
        _formKey.currentState?.patchValue({'image': image});
      },
    );
  }

  /// 构建图标选择器
  Widget _buildIconPicker(Habit? habit) {
    IconData? icon = habit?.icon != null
        ? IconData(int.parse(habit!.icon!), fontFamily: 'MaterialIcons')
        : Icons.check_rounded;
    Color color = Colors.blue;

    return _CircleIconPickerWidget(
      initialIcon: icon,
      initialColor: color,
      onIconChanged: (iconData) {
        _formKey.currentState?.patchValue({'icon': iconData});
      },
    );
  }

  void _handleSubmit(Map<String, dynamic> values) {
    final iconData = values['icon'] as Map<String, dynamic>?;
    final habit = Habit(
      id: widget.initialHabit?.id ?? HabitsUtils.generateId(),
      title: values['title'] as String? ?? '',
      notes: (values['notes'] as String?)?.isEmpty ?? true
          ? null
          : values['notes'] as String?,
      group: (values['group'] as String?)?.isEmpty ?? true
          ? null
          : values['group'] as String?,
      icon: (iconData?['icon'] as IconData?)?.codePoint.toString(),
      image: values['image'] as String?,
      durationMinutes: int.tryParse(values['durationMinutes']?.toString() ?? '30') ?? 30,
      skillId: values['skillId'] as String?,
      tags: const [],
    );
    widget.onSave(habit);
  }

  /// 构建技能选择项
  List<DropdownMenuItem> _buildSkillItems() {
    return [
      DropdownMenuItem<String>(
        value: null,
        child: Text('habits_selectSkill'.tr),
      ),
      ..._skills.map((skill) {
        return DropdownMenuItem<String>(
          value: skill.id,
          child: Text(skill.title),
        );
      }),
    ];
  }

  Future<void> _loadSkills() async {
    try {
      final habitsPlugin = PluginManager.instance.getPlugin('habits');
      if (habitsPlugin != null && habitsPlugin is HabitsPlugin) {
        final controller = habitsPlugin.getSkillController();
        final skills = await controller.getSkills();
        setState(() {
          _skills = skills;
        });
      } else {
        debugPrint('Habits plugin not found or invalid');
        setState(() {
          _skills = [];
        });
      }
    } catch (e) {
      debugPrint('Error loading skills: $e');
      setState(() {
        _skills = [];
      });
    }
  }

  /// 更新路由上下文,使"询问当前上下文"功能能获取到当前页面状态
  void _updateRouteContext() {
    final isEdit = widget.initialHabit != null;
    final habitId = widget.initialHabit?.id ?? '';
    final habitTitle = widget.initialHabit?.title ?? '';

    RouteHistoryManager.updateCurrentContext(
      pageId: '/habit_form',
      title: isEdit ? '编辑习惯 - $habitTitle' : '新建习惯',
      params: {
        'mode': isEdit ? 'edit' : 'create',
        if (isEdit) 'habitId': habitId,
        if (isEdit) 'habitTitle': habitTitle,
      },
    );
  }
}

/// 图片选择器 Widget
class _ImagePickerWidget extends StatelessWidget {
  final String? initialImage;
  final ValueChanged<String?> onImageChanged;

  const _ImagePickerWidget({
    required this.initialImage,
    required this.onImageChanged,
  });

  /// 加载图片路径
  Future<String> _loadImagePath(String imagePath) async {
    return imagePath.startsWith('http')
        ? imagePath
        : await ImageUtils.getAbsolutePath(imagePath);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => ImagePickerDialog(
            initialUrl: initialImage,
            saveDirectory: 'habits/habit_images',
            enableCrop: true,
            cropAspectRatio: 1.0,
          ),
        );
        if (result != null && result['url'] != null) {
          onImageChanged(result['url'] as String?);
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
          child: Builder(
            builder: (context) {
              final image = initialImage;
              if (image != null && image.isNotEmpty) {
                return FutureBuilder<String>(
                  future: _loadImagePath(image),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Center(
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: ClipOval(
                            child: image.startsWith('http')
                                ? Image.network(
                                    snapshot.data!,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.broken_image),
                                  )
                                : Image.file(
                                    File(snapshot.data!),
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.broken_image),
                                  ),
                          ),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return const Icon(Icons.broken_image);
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                );
              } else {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined, size: 24),
                      const SizedBox(height: 2),
                      Text('选择图片', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

/// 圆形图标选择器 Widget
class _CircleIconPickerWidget extends StatefulWidget {
  final IconData? initialIcon;
  final Color initialColor;
  final ValueChanged<Map<String, dynamic>> onIconChanged;

  const _CircleIconPickerWidget({
    required this.initialIcon,
    required this.initialColor,
    required this.onIconChanged,
  });

  @override
  State<_CircleIconPickerWidget> createState() => _CircleIconPickerWidgetState();
}

class _CircleIconPickerWidgetState extends State<_CircleIconPickerWidget> {
  late IconData _icon;
  late Color _color;

  @override
  void initState() {
    super.initState();
    _icon = widget.initialIcon ?? Icons.check_rounded;
    _color = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return CircleIconPicker(
      currentIcon: _icon,
      backgroundColor: _color,
      onIconSelected: (icon) {
        setState(() => _icon = icon);
        widget.onIconChanged({'icon': icon, 'color': _color});
      },
      onColorSelected: (color) {
        setState(() => _color = color);
        widget.onIconChanged({'icon': _icon, 'color': color});
      },
    );
  }
}
