import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/plugins/habits/models/skill.dart';
import 'package:Memento/plugins/habits/utils/habits_utils.dart';
import 'package:Memento/widgets/form_fields/index.dart';

/// 技能表单 - 使用 FormBuilderWrapper 重构
class SkillForm extends StatefulWidget {
  final Skill? initialSkill;
  final Function(Skill) onSave;

  const SkillForm({super.key, this.initialSkill, required this.onSave});

  @override
  State<SkillForm> createState() => _SkillFormState();
}

class _SkillFormState extends State<SkillForm> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    // 设置路由上下文
    _updateRouteContext();
  }

  @override
  Widget build(BuildContext context) {
    final skill = widget.initialSkill;

    // 解析图标
    IconData? initialIcon;
    if (skill?.icon != null) {
      try {
        initialIcon = IconData(int.parse(skill!.icon!), fontFamily: 'MaterialIcons');
      } catch (_) {
        initialIcon = Icons.check_rounded;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FormBuilderWrapper(
        formKey: _formKey,
        config: FormConfig(
          fields: [
            // 图标和图片选择器（并排显示）
            FormFieldConfig(
              name: 'iconAvatarRow',
              type: FormFieldType.iconAvatarRow,
              initialValue: {
                'icon': initialIcon ?? Icons.check_rounded,
                'iconColor': Colors.blue,
                'avatarUrl': skill?.image,
              },
              extra: {
                'avatarSaveDirectory': 'habits/skill_images',
              },
            ),

            // 技能名称
            FormFieldConfig(
              name: 'title',
              type: FormFieldType.text,
              labelText: 'habits_skillName'.tr,
              hintText: '请输入技能名称',
              initialValue: skill?.title ?? '',
              required: true,
              validationMessage: '技能名称不能为空',
            ),

            // 技能描述
            FormFieldConfig(
              name: 'notes',
              type: FormFieldType.textArea,
              labelText: 'habits_skillDescription'.tr,
              hintText: '请输入技能描述（可选）',
              initialValue: skill?.notes ?? '',
            ),

            // 分组
            FormFieldConfig(
              name: 'group',
              type: FormFieldType.text,
              labelText: 'habits_skillGroup'.tr,
              hintText: '请输入分组名称（可选）',
              initialValue: skill?.group ?? '',
            ),

            // 最大时长限制
            FormFieldConfig(
              name: 'maxDurationMinutes',
              type: FormFieldType.number,
              labelText: '${'habits_maxDuration'.tr} (${'habits_minutes'.tr})',
              hintText: 'habits_noLimitHint'.tr,
              initialValue: skill?.maxDurationMinutes ?? 0,
            ),
          ],
          submitButtonText: 'habits_save'.tr,
          fieldSpacing: 16,
          showResetButton: false,
          onSubmit: _handleSave,
        ),
      ),
    );
  }

  /// 处理表单提交
  void _handleSave(Map<String, dynamic> values) {
    final iconAvatarRow = values['iconAvatarRow'] as Map<String, dynamic>;
    final iconData = iconAvatarRow['icon'] as IconData;
    final imageUrl = iconAvatarRow['avatarUrl'] as String?;

    final skill = Skill(
      id: widget.initialSkill?.id ?? HabitsUtils.generateId(),
      title: values['title'] as String,
      notes: (values['notes'] as String?)?.isEmpty ?? true
          ? null
          : values['notes'] as String?,
      group: (values['group'] as String?)?.isEmpty ?? true
          ? null
          : values['group'] as String?,
      icon: iconData.codePoint.toString(),
      image: imageUrl?.isEmpty ?? true ? null : imageUrl,
      maxDurationMinutes: int.tryParse(values['maxDurationMinutes']?.toString() ?? '0') ?? 0,
    );

    widget.onSave(skill);
  }

  /// 更新路由上下文,使"询问当前上下文"功能能获取到当前页面状态
  void _updateRouteContext() {
    final isEdit = widget.initialSkill != null;
    final skillId = widget.initialSkill?.id ?? '';
    final skillTitle = widget.initialSkill?.title ?? '';

    RouteHistoryManager.updateCurrentContext(
      pageId: '/skill_form',
      title: isEdit ? '编辑技能 - $skillTitle' : '新建技能',
      params: {
        'mode': isEdit ? 'edit' : 'create',
        if (isEdit) 'skillId': skillId,
        if (isEdit) 'skillTitle': skillTitle,
      },
    );
  }
}
