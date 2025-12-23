import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../plugins/openai/models/prompt_preset.dart';
import 'form_fields/index.dart';

/// 预设编辑表单组件
///
/// 提供统一的预设创建和编辑表单，使用标准化的表单字段组件
class PresetEditForm extends StatefulWidget {
  /// 要编辑的预设（null 表示新增模式）
  final PromptPreset? preset;

  /// 保存回调
  final Future<void> Function(PromptPreset preset) onSave;

  /// 取消回调
  final VoidCallback? onCancel;

  const PresetEditForm({
    super.key,
    this.preset,
    required this.onSave,
    this.onCancel,
  });

  @override
  State<PresetEditForm> createState() => _PresetEditFormState();
}

class _PresetEditFormState extends State<PresetEditForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    if (widget.preset != null) {
      _nameController.text = widget.preset!.name;
      _descriptionController.text = widget.preset!.description;
      _contentController.text = widget.preset!.content;
      _tags.addAll(widget.preset!.tags);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _showAddTagDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('openai_addTag'.tr),
        content: TextField(
          controller: _tagController,
          decoration: InputDecoration(
            labelText: 'openai_tagName'.tr,
            hintText: 'openai_enterTagName'.tr,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            _addTag();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _tagController.clear();
              Navigator.of(context).pop();
            },
            child: Text('openai_cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              _addTag();
              Navigator.of(context).pop();
            },
            child: Text('openai_add'.tr),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final preset = PromptPreset(
      id: widget.preset?.id ?? now.millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      content: _contentController.text,
      tags: _tags,
      createdAt: widget.preset?.createdAt ?? now,
      updatedAt: now,
    );

    await widget.onSave(preset);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.preset != null;
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // 标题字段
          TextInputField(
            controller: _nameController,
            labelText: 'openai_presetTitle'.tr,
            hintText: 'openai_pleaseEnterTitle'.tr,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'openai_pleaseEnterTitle'.tr;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 描述字段
          TextInputField(
            controller: _descriptionController,
            labelText: 'openai_presetDescription'.tr,
            hintText: 'openai_enterDescription'.tr,
          ),
          const SizedBox(height: 16),

          // 内容字段
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 120,
              maxHeight: 180,
            ),
            child: TextAreaField(
              controller: _contentController,
              labelText: 'openai_promptContent'.tr,
              hintText: 'openai_enterSystemPrompt'.tr,
              minLines: 5,
              maxLines: 8,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'openai_pleaseEnterSystemPrompt'.tr;
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),

          // 标签字段
          Text(
            'openai_presetTags'.tr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TagsField(
            tags: _tags,
            onAddTag: _showAddTagDialog,
            onRemoveTag: _removeTag,
            addButtonText: 'openai_addTag'.tr,
          ),

          // 操作按钮
          const SizedBox(height: 24),
          Row(
            children: [
              if (widget.onCancel != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    child: Text('openai_cancel'.tr),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  child: Text(isEditing ? 'openai_update'.tr : 'openai_save'.tr),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }
}

/// 显示预设编辑对话框
///
/// 返回保存后的预设对象
Future<PromptPreset?> showPresetEditDialog({
  required BuildContext context,
  PromptPreset? preset,
  required Future<void> Function(PromptPreset preset) onSave,
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
          onSave: (preset) async {
            await onSave(preset);
            if (context.mounted) {
              Navigator.of(context).pop(preset);
            }
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
      actions: const [],
    ),
  );
}
