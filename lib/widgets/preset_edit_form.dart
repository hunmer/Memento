import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../plugins/openai/models/prompt_preset.dart';
import '../plugins/openai/models/ai_agent.dart';
import 'form_fields/index.dart';

/// 预设编辑表单组件
///
/// 提供统一的预设创建和编辑表单，使用 FormBuilderWrapper 实现声明式表单
class PresetEditForm extends StatelessWidget {
  /// 要编辑的预设（null 表示新增模式）
  final PromptPreset? preset;

  /// 保存回调 - 传递 PromptPreset 和 prompts 列表
  final Future<void> Function(PromptPreset preset, List<Prompt> prompts) onSave;

  /// 取消回调
  final VoidCallback? onCancel;

  const PresetEditForm({
    super.key,
    this.preset,
    required this.onSave,
    this.onCancel,
  });

  /// 获取初始 Prompts 列表
  List<Prompt> _getInitialPrompts() {
    if (preset != null) {
      // 优先加载结构化的 prompts 列表
      if (preset!.prompts != null && preset!.prompts!.isNotEmpty) {
        return List.from(preset!.prompts!);
      }
      // 回退：如果有 content，从 content 创建
      if (preset!.content.isNotEmpty) {
        return [Prompt(type: 'system', content: preset!.content)];
      }
    }
    return [];
  }

  /// 处理表单提交
  Future<void> _handleSubmit(BuildContext context, Map<String, dynamic> values) async {
    final name = values['name'] as String;
    final description = values['description'] as String?;
    final prompts = values['prompts'] as List<Prompt>;
    final tags = values['tags'] as List<String>? ?? [];

    // 验证至少有一个 prompt
    if (prompts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('openai_pleaseEnterSystemPrompt'.tr)),
      );
      return;
    }

    final now = DateTime.now();

    // 将 prompts 转换为 content 字符串（用于兼容旧数据）
    final systemPrompt = prompts.firstWhere(
      (p) => p.type == 'system',
      orElse: () => Prompt(type: 'system', content: ''),
    );
    final content = systemPrompt.content.isNotEmpty
        ? systemPrompt.content
        : prompts.map((p) => '${p.type}: ${p.content}').join('\n\n');

    final newPreset = PromptPreset(
      id: preset?.id ?? now.millisecondsSinceEpoch.toString(),
      name: name.trim(),
      description: description?.trim() ?? '',
      content: content,
      tags: tags,
      createdAt: preset?.createdAt ?? now,
      updatedAt: now,
      prompts: prompts.isNotEmpty ? List.from(prompts) : null,
    );

    await onSave(newPreset, prompts);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = preset != null;
    final initialPrompts = _getInitialPrompts();

    return FormBuilderWrapper(
      config: FormConfig(
        showSubmitButton: false,
        showResetButton: false,
        fieldSpacing: 16,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        fields: [
          // 名称字段
          FormFieldConfig(
            name: 'name',
            type: FormFieldType.text,
            labelText: 'openai_presetTitle'.tr,
            hintText: 'openai_pleaseEnterTitle'.tr,
            initialValue: preset?.name ?? '',
            required: true,
            validationMessage: 'openai_pleaseEnterTitle'.tr,
          ),

          // 描述字段
          FormFieldConfig(
            name: 'description',
            type: FormFieldType.textArea,
            labelText: 'openai_presetDescription'.tr,
            hintText: 'openai_enterDescription'.tr,
            initialValue: preset?.description ?? '',
            extra: {
              'minLines': 2,
              'maxLines': 4,
            },
          ),

          // Prompt 编辑器
          FormFieldConfig(
            name: 'prompts',
            type: FormFieldType.promptEditor,
            initialValue: initialPrompts,
            extra: {
              'labelText': 'openai_promptContent'.tr,
            },
          ),

          // 标签字段
          FormFieldConfig(
            name: 'tags',
            type: FormFieldType.tags,
            initialValue: preset?.tags ?? [],
            initialTags: preset?.tags ?? [],
            extra: {
              'addButtonText': 'openai_addTag'.tr,
            },
          ),
        ],
        onSubmit: (values) => _handleSubmit(context, values),
      ),
      buttonBuilder: (context, onSubmit, onReset) {
        return Row(
          children: [
            if (onCancel != null) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: Text('openai_cancel'.tr),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => onSubmit(),
                child: Text(isEditing ? 'openai_update'.tr : 'openai_save'.tr),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 显示预设编辑对话框
///
/// 返回保存后的预设对象
Future<PromptPreset?> showPresetEditDialog({
  required BuildContext context,
  PromptPreset? preset,
  required Future<void> Function(PromptPreset preset, List<Prompt> prompts) onSave,
}) async {
  return await showDialog<PromptPreset>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        preset != null ? 'openai_editPreset'.tr : 'openai_addPreset'.tr,
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        child: PresetEditForm(
          preset: preset,
          onSave: (newPreset, prompts) async {
            await onSave(newPreset, prompts);
            if (context.mounted) {
              Navigator.of(context).pop(newPreset);
            }
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
      actions: const [],
    ),
  );
}
