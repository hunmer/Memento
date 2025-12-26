import 'package:flutter/material.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:Memento/plugins/openai/widgets/prompt_editor.dart';
import 'form_field_wrapper.dart';

/// PromptEditor 字段包装器
///
/// 将 PromptEditor 组件包装为可在 FormBuilderWrapper 中使用的字段
class PromptEditorField extends StatefulWidget {
  /// 字段名称
  final String name;

  /// 初始提示词列表
  final List<Prompt> initialValue;

  /// 是否启用
  final bool enabled;

  /// 值变化回调
  final ValueChanged<List<Prompt>>? onChanged;

  /// 字段标签（可选，为 null 时不显示标题）
  final String? labelText;

  const PromptEditorField({
    super.key,
    required this.name,
    required this.initialValue,
    this.enabled = true,
    this.onChanged,
    this.labelText,
  });

  @override
  State<PromptEditorField> createState() => _PromptEditorFieldState();
}

class _PromptEditorFieldState extends State<PromptEditorField> {
  late List<Prompt> _prompts;
  late TextEditingController _systemPromptController;

  @override
  void initState() {
    super.initState();
    _prompts = List.from(widget.initialValue);
    _systemPromptController = TextEditingController();

    // 分离 system prompt 和其他消息
    for (final prompt in _prompts) {
      if (prompt.type == 'system') {
        _systemPromptController.text = prompt.content;
        break;
      }
    }
  }

  @override
  void dispose() {
    _systemPromptController.dispose();
    super.dispose();
  }

  void _onPromptsChanged(List<Prompt> prompts) {
    setState(() {
      _prompts = prompts;
    });
    widget.onChanged?.call(prompts);
  }

  /// 获取当前值
  List<Prompt> getValue() {
    return _prompts;
  }

  /// 重置为初始值
  void reset() {
    setState(() {
      _prompts = List.from(widget.initialValue);
      _systemPromptController.clear();
      for (final prompt in widget.initialValue) {
        if (prompt.type == 'system') {
          _systemPromptController.text = prompt.content;
          break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题（仅在提供 labelText 时显示）
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
        ],
        // PromptEditor
        SizedBox(
          height: 400,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: PromptEditor(
              prompts: _prompts,
              onPromptsChanged: widget.enabled ? _onPromptsChanged : (_) {},
              separateSystemPrompt: true,
              systemPromptController: _systemPromptController,
            ),
          ),
        ),
      ],
    );
  }
}

/// WrappedFormField 版本的 PromptEditor 字段
class WrappedPromptEditorField extends StatefulWidget {
  /// 字段名称
  final String name;

  /// 初始值
  final List<Prompt> initialValue;

  /// 是否启用
  final bool enabled;

  /// 值变化回调
  final ValueChanged<List<Prompt>>? onChanged;

  /// 字段标签（可选，为 null 时不显示标题）
  final String? labelText;

  const WrappedPromptEditorField({
    super.key,
    required this.name,
    required this.initialValue,
    this.enabled = true,
    this.onChanged,
    this.labelText,
  });

  @override
  State<WrappedPromptEditorField> createState() => _WrappedPromptEditorFieldState();
}

class _WrappedPromptEditorFieldState extends State<WrappedPromptEditorField> {
  final GlobalKey<_PromptEditorFieldState> _fieldKey = GlobalKey<_PromptEditorFieldState>();

  @override
  Widget build(BuildContext context) {
    return WrappedFormField(
      name: widget.name,
      initialValue: widget.initialValue,
      enabled: widget.enabled,
      onChanged: (v) => widget.onChanged?.call(v as List<Prompt>),
      builder: (context, value, setValue) {
        return PromptEditorField(
          key: _fieldKey,
          name: widget.name,
          initialValue: (value as List<dynamic>? ?? []).cast<Prompt>(),
          enabled: widget.enabled,
          onChanged: (v) => setValue(v),
          labelText: widget.labelText,
        );
      },
      onReset: () => _fieldKey.currentState?.reset(),
    );
  }
}
