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

  /// 初始提示词列表 (List dynamic 内部转换为 Prompt)
  final List<dynamic>? initialValue;

  /// 是否启用
  final bool enabled;

  /// 值变化回调
  final ValueChanged<List<dynamic>>? onChanged;

  /// 字段标签（可选，为 null 时不显示标题）
  final String? labelText;

  const PromptEditorField({
    super.key,
    required this.name,
    this.initialValue,
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

  /// 将 List dynamic 转换为 List Prompt
  List<Prompt> _parsePrompts(List<dynamic>? values) {
    return (values ?? []).map((e) {
      if (e is Prompt) return e;
      if (e is Map<String, dynamic>) return Prompt.fromJson(e);
      return Prompt(type: 'user', content: e.toString());
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _prompts = _parsePrompts(widget.initialValue);
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
    // 转换为 List<dynamic> 返回
    widget.onChanged?.call(prompts.map((p) => p.toJson()).toList());
  }

  /// 获取当前值
  List<dynamic> getValue() {
    return _prompts.map((p) => p.toJson()).toList();
  }

  /// 重置为初始值
  void reset() {
    setState(() {
      _prompts = _parsePrompts(widget.initialValue);
      _systemPromptController.clear();
      for (final prompt in _prompts) {
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
      mainAxisSize: MainAxisSize.min,
      children: [
        // 标题（仅在提供 labelText 时显示）
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
        ],
        // PromptEditor（自适应高度，最大500）
        Container(
          constraints: const BoxConstraints(
            maxHeight: 500,
          ),
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
      ],
    );
  }
}

/// WrappedFormField 版本的 PromptEditor 字段
class WrappedPromptEditorField extends StatefulWidget {
  /// 字段名称
  final String name;

  /// 初始值
  final List<dynamic>? initialValue;

  /// 是否启用
  final bool enabled;

  /// 值变化回调
  final ValueChanged<List<dynamic>>? onChanged;

  /// 字段标签（可选，为 null 时不显示标题）
  final String? labelText;

  const WrappedPromptEditorField({
    super.key,
    required this.name,
    this.initialValue,
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
      onChanged: widget.onChanged as dynamic,
      builder: (context, value, setValue) {
        return PromptEditorField(
          key: _fieldKey,
          name: widget.name,
          initialValue: value,
          enabled: widget.enabled,
          onChanged: setValue,
          labelText: widget.labelText,
        );
      },
      onReset: () => _fieldKey.currentState?.reset(),
    );
  }
}
