import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
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
    final promptsRaw = values['prompts'];
    final prompts =
        (promptsRaw is List<Prompt>
                ? promptsRaw
                : promptsRaw is List<Map<String, dynamic>>
                ? promptsRaw.map((e) => Prompt.fromJson(e)).toList()
            : <Prompt>[]);
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
    if (context.mounted) {
      Navigator.of(context).pop(newPreset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = preset != null;
    final formKey = GlobalKey<FormBuilderState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          preset != null ? 'openai_editPreset'.tr : 'openai_addPreset'.tr,
        ),
        actions: [
          TextButton(
            onPressed: () {
              final state = formKey.currentState;
              if (state != null && state.saveAndValidate()) {
                _handleSubmit(context, state.value);
              }
            },
            child: Text(isEditing ? 'openai_update'.tr : 'openai_save'.tr),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FormBuilderWrapper(
          formKey: formKey,
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
                extra: {'minLines': 2, 'maxLines': 4},
              ),

              // Prompt 编辑器
              FormFieldConfig(
                name: 'prompts',
                type: FormFieldType.promptEditor,
                initialValue: _getInitialPrompts(),
              ),

              // 标签字段
              FormFieldConfig(
                name: 'tags',
                type: FormFieldType.tags,
                initialValue: preset?.tags ?? [],
                initialTags: preset?.tags ?? [],
                extra: {'addButtonText': 'openai_addTag'.tr},
              ),
            ],
            onSubmit: (values) => _handleSubmit(context, values),
          ),
          buttonBuilder: null,
        ),
      ),
    );
  }
}

/// 显示预设编辑页面
///
/// 返回保存后的预设对象
Future<PromptPreset?> showPresetEditPage({
  required BuildContext context,
  PromptPreset? preset,
  required Future<void> Function(PromptPreset preset, List<Prompt> prompts) onSave,
}) async {
  return await Navigator.of(context).push<PromptPreset>(
    MaterialPageRoute(
      builder:
          (context) => PresetEditForm(
            preset: preset,
            onSave: onSave,
            onCancel: () => Navigator.of(context).pop(),
          ),
    ),
  );
}
