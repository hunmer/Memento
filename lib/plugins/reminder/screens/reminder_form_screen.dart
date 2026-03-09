import 'package:flutter/material.dart';
import 'package:Memento/widgets/form_fields/form_builder_wrapper.dart';
import 'package:Memento/widgets/form_fields/types.dart';
import 'package:Memento/widgets/form_fields/config.dart';
import 'package:Memento/widgets/form_fields/reminder_date_selector_field.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import '../models/reminder.dart';
import '../services/reminder_service.dart';

/// 提醒表单界面
class ReminderFormScreen extends StatefulWidget {
  final Reminder? existingReminder;

  const ReminderFormScreen({super.key, this.existingReminder});

  @override
  State<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<ReminderFormScreen> {
  final ReminderService _service = ReminderService();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingReminder != null;

    return SuperCupertinoNavigationWrapper(
      title: Text(isEditing ? '编辑提醒' : '新建提醒'),
      largeTitle: isEditing ? '编辑提醒' : '新建提醒',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FormBuilderWrapper(
          config: FormConfig(
            fields: [
              // 标题
              FormFieldConfig(
                name: 'title',
                type: FormFieldType.text,
                labelText: '提醒标题',
                required: true,
                initialValue: widget.existingReminder?.title,
                validationMessage: '请输入提醒标题',
              ),

              // 内容
              FormFieldConfig(
                name: 'content',
                type: FormFieldType.textArea,
                labelText: '提醒内容',
                required: true,
                initialValue: widget.existingReminder?.content,
                validationMessage: '请输入提醒内容',
                extra: {'maxLines': 3},
              ),

              // 图片（可选）
              FormFieldConfig(
                name: 'image',
                type: FormFieldType.imagePicker,
                labelText: '提醒图片（可选）',
                required: false,
                initialValue:
                    widget.existingReminder?.imageUrl != null
                        ? {'url': widget.existingReminder!.imageUrl}
                        : null,
                extra: {'saveDirectory': 'reminder_images'},
              ),

              // 提醒时间配置
              FormFieldConfig(
                name: 'schedule',
                type: FormFieldType.reminderDate,
                labelText: '提醒时间',
                required: true,
                initialValue:
                    widget.existingReminder != null
                        ? ReminderDateData(
                          type: _frequencyToType(
                            widget.existingReminder!.frequency,
                          ),
                          selectedDays: widget.existingReminder!.selectedDays,
                          time: widget.existingReminder!.time,
                        )
                        : const ReminderDateData(
                          type: ReminderDateType.daily,
                          selectedDays: [1, 2, 3, 4, 5, 6, 7],
                          time: TimeOfDay(hour: 9, minute: 0),
                        ),
              ),

              // 推送方式
              FormFieldConfig(
                name: 'pushMethod',
                type: FormFieldType.select,
                labelText: '推送方式',
                required: true,
                initialValue:
                    widget.existingReminder?.pushMethod.index.toString() ?? '0',
                items: const [
                  DropdownMenuItem(value: '0', child: Text('本地通知')),
                  DropdownMenuItem(value: '1', child: Text('FCM 推送（暂未实现）')),
                  DropdownMenuItem(value: '2', child: Text('两者都使用')),
                ],
              ),

              // 优先级
              FormFieldConfig(
                name: 'priority',
                type: FormFieldType.select,
                labelText: '优先级',
                required: false,
                initialValue:
                    widget.existingReminder?.priority.toString() ?? '0',
                items: const [
                  DropdownMenuItem(value: '0', child: Text('普通')),
                  DropdownMenuItem(value: '1', child: Text('重要')),
                  DropdownMenuItem(value: '2', child: Text('紧急')),
                  DropdownMenuItem(value: '3', child: Text('非常紧急')),
                ],
              ),
            ],
            onSubmit: _handleSubmit,
            submitButtonText: isEditing ? '保存' : '创建',
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit(Map<String, dynamic> values) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final title = values['title'] as String;
      final content = values['content'] as String;

      // 将 Map 转换为 ReminderDateData
      final scheduleMap = values['schedule'];
      final schedule = scheduleMap is ReminderDateData
          ? scheduleMap
          : ReminderDateData.fromMap(scheduleMap as Map<String, dynamic>);

      final imageData = values['image'] as Map<String, dynamic>?;
      final pushMethodIndex = int.parse(values['pushMethod'] as String? ?? '0');
      final priority = int.parse(values['priority'] as String? ?? '0');

      final imageUrl = imageData?['url'] as String?;

      if (widget.existingReminder != null) {
        // 编辑模式
        final updated = widget.existingReminder!.copyWith(
          title: title,
          content: content,
          imageUrl: imageUrl,
          frequency: _typeToFrequency(schedule.type),
          selectedDays: schedule.selectedDays,
          time: schedule.time ?? TimeOfDay.now(),
          pushMethod: ReminderPushMethod.values[pushMethodIndex],
          priority: priority,
        );
        await _service.updateReminder(updated);
      } else {
        // 创建模式
        await _service.addReminder(
          title: title,
          content: content,
          imageUrl: imageUrl,
          frequency: _typeToFrequency(schedule.type),
          selectedDays: schedule.selectedDays,
          time: schedule.time ?? TimeOfDay.now(),
          pushMethod: ReminderPushMethod.values[pushMethodIndex],
          priority: priority,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('[ReminderFormScreen] 保存失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  ReminderDateType _frequencyToType(ReminderFrequency frequency) {
    switch (frequency) {
      case ReminderFrequency.none:
        return ReminderDateType.none;
      case ReminderFrequency.daily:
        return ReminderDateType.daily;
      case ReminderFrequency.weekly:
        return ReminderDateType.weekly;
      case ReminderFrequency.monthly:
        return ReminderDateType.monthly;
    }
  }

  ReminderFrequency _typeToFrequency(ReminderDateType type) {
    switch (type) {
      case ReminderDateType.none:
        return ReminderFrequency.none;
      case ReminderDateType.daily:
        return ReminderFrequency.daily;
      case ReminderDateType.weekly:
        return ReminderFrequency.weekly;
      case ReminderDateType.monthly:
        return ReminderFrequency.monthly;
    }
  }
}
