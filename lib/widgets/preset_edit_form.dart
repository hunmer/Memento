import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../plugins/openai/models/prompt_preset.dart';
import '../plugins/openai/models/ai_agent.dart';
import '../plugins/openai/widgets/prompt_editor.dart';
import 'form_fields/index.dart';

/// 预设编辑表单组件
///
/// 提供统一的预设创建和编辑表单，使用标准化的表单字段组件
class PresetEditForm extends StatefulWidget {
  /// 要编辑的预设（null 表示新增模式）
  final PromptPreset? preset;

  /// 保存回调 - 现在同时传递 PromptPreset 和 prompts 列表
  final Future<void> Function(PromptPreset preset, List<Prompt> prompts) onSave;

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
  final _systemPromptController = TextEditingController();
  final _tagController = TextEditingController();
  final List<String> _tags = [];
  final List<Prompt> _prompts = [];

  @override
  void initState() {
    super.initState();
    if (widget.preset != null) {
      _nameController.text = widget.preset!.name;
      _descriptionController.text = widget.preset!.description;
      _tags.addAll(widget.preset!.tags);

      // 优先加载结构化的 prompts 列表
      if (widget.preset!.prompts != null && widget.preset!.prompts!.isNotEmpty) {
        _prompts.addAll(widget.preset!.prompts!);

        // 如果有 system prompt，设置到控制器
        final systemPrompt = _prompts.firstWhere(
          (p) => p.type == 'system',
          orElse: () => Prompt(type: 'system', content: ''),
        );
        if (systemPrompt.content.isNotEmpty) {
          _systemPromptController.text = systemPrompt.content;
        }
      }
      // 回退：如果没有 prompts，从 content 创建
      else if (widget.preset!.content.isNotEmpty) {
        _systemPromptController.text = widget.preset!.content;
        _prompts.add(Prompt(type: 'system', content: widget.preset!.content));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _systemPromptController.dispose();
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

  void _onPromptsChanged(List<Prompt> prompts) {
    setState(() {
      _prompts.clear();
      _prompts.addAll(prompts);
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

    // 验证至少有一个 prompt
    if (_prompts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('openai_pleaseEnterSystemPrompt'.tr)),
      );
      return;
    }

    final now = DateTime.now();

    // 将 prompts 转换为 content 字符串
    // 这里可以自定义转换逻辑，当前简单处理：将所有 prompts 合并
    final content = _systemPromptController.text.isNotEmpty
        ? _systemPromptController.text
        : _prompts.map((p) => '${p.type}: ${p.content}').join('\n\n');

    final preset = PromptPreset(
      id: widget.preset?.id ?? now.millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      content: content,
      tags: _tags,
      createdAt: widget.preset?.createdAt ?? now,
      updatedAt: now,
      prompts: _prompts.isNotEmpty ? List.from(_prompts) : null,
    );

    // 同时传递 PromptPreset 和 List<Prompt>
    await widget.onSave(preset, _prompts);
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

          // Prompt 编辑器 - 使用分离模式
          Container(
            height: 400,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'openai_promptContent'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: PromptEditor(
                      prompts: _prompts,
                      onPromptsChanged: _onPromptsChanged,
                      separateSystemPrompt: true,
                      systemPromptController: _systemPromptController,
                    ),
                  ),
                ],
              ),
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
          onSave: (preset, prompts) async {
            await onSave(preset, prompts);
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
