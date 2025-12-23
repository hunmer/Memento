import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';

class PromptEditor extends StatefulWidget {
  final List<Prompt> prompts;
  final Function(List<Prompt>) onPromptsChanged;
  final bool separateSystemPrompt; // 是否分离 System Prompt 编辑
  final TextEditingController? systemPromptController; // System Prompt 控制器
  final VoidCallback? onAddMessage; // 添加消息回调

  const PromptEditor({
    super.key,
    required this.prompts,
    required this.onPromptsChanged,
    this.separateSystemPrompt = false,
    this.systemPromptController,
    this.onAddMessage,
  });

  @override
  State<PromptEditor> createState() => _PromptEditorState();
}

class _PromptEditorState extends State<PromptEditor> {
  late List<Prompt> _prompts;

  @override
  void initState() {
    super.initState();
    _prompts = List.from(widget.prompts);
  }

  void _addPrompt() {
    setState(() {
      _prompts.add(Prompt(type: 'user', content: ''));
      widget.onPromptsChanged(_prompts);
      // 通知外部添加了新消息
      widget.onAddMessage?.call();
    });
  }

  void _removePrompt(int index) {
    setState(() {
      _prompts.removeAt(index);
      widget.onPromptsChanged(_prompts);
    });
  }

  void _updatePromptType(int index, String type) {
    setState(() {
      _prompts[index] = Prompt(type: type, content: _prompts[index].content);
      widget.onPromptsChanged(_prompts);
    });
  }

  void _updatePromptContent(int index, String content) {
    setState(() {
      _prompts[index] = Prompt(type: _prompts[index].type, content: content);
      widget.onPromptsChanged(_prompts);
    });
  }

  /// 获取过滤后的消息列表（排除 system 类型）
  List<Prompt> get _filteredMessages {
    return _prompts.where((p) => p.type != 'system').toList();
  }

  @override
  Widget build(BuildContext context) {
    // 如果是分离模式，使用新的布局
    if (widget.separateSystemPrompt) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // System Prompt 单独显示
          Text(
            'System Prompt',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.systemPromptController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            minLines: 4,
            maxLines: 4,
            onChanged: (value) {
              // 找到或创建 system prompt
              final systemIndex = _prompts.indexWhere((p) => p.type == 'system');
              if (systemIndex >= 0) {
                _updatePromptContent(systemIndex, value);
              } else if (value.isNotEmpty) {
                setState(() {
                  _prompts.insert(0, Prompt(type: 'system', content: value));
                  widget.onPromptsChanged(_prompts);
                });
              }
            },
          ),
          const SizedBox(height: 16),
          // 预设消息
          Row(
            children: [
              Text(
                '预设消息',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: widget.onAddMessage ?? _addPrompt,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('添加', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredMessages.length,
              itemBuilder: (context, index) {
                final originalIndex = _prompts.indexOf(_filteredMessages[index]);
                final prompt = _filteredMessages[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: prompt.type,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'user',
                                    child: Text('User'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'assistant',
                                    child: Text('Assistant'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    _updatePromptType(originalIndex, value);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () => _removePrompt(originalIndex),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: 80,
                            maxHeight: 160,
                          ),
                          child: TextFormField(
                            initialValue: prompt.content,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                            maxLines: null,
                            onChanged: (value) =>
                                _updatePromptContent(originalIndex, value),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    // 传统模式：所有提示混合显示
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._prompts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final prompt = entry.value;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: prompt.type,
                                  decoration: InputDecoration(
                                    labelText: 'openai_promptTypeLabel'.tr,
                                    border: const OutlineInputBorder(),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'system',
                                      child: Text('openai_systemRole'.tr),
                                    ),
                                    DropdownMenuItem(
                                      value: 'user',
                                      child: Text('openai_userRole'.tr),
                                    ),
                                    DropdownMenuItem(
                                      value: 'assistant',
                                      child: Text('openai_assistantRole'.tr),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      _updatePromptType(index, value);
                                    }
                                  },
                                ),
                              ),
                              if (_prompts.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _removePrompt(index),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: 120,
                              maxHeight: 200,
                            ),
                            child: TextFormField(
                              initialValue: prompt.content,
                              decoration: InputDecoration(
                                labelText: 'openai_contentLabel'.tr,
                                border: const OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                              maxLines: null,
                              onChanged: (value) => _updatePromptContent(index, value),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addPrompt,
          icon: const Icon(Icons.add),
          label: Text('openai_addPrompt'.tr),
        ),
      ],
    );
  }
}
