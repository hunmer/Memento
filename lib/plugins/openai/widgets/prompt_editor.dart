import 'package:flutter/material.dart';
import '../models/ai_agent.dart';
import '../l10n/openai_localizations.dart';

class PromptEditor extends StatefulWidget {
  final List<Prompt> prompts;
  final Function(List<Prompt>) onPromptsChanged;

  const PromptEditor({
    super.key,
    required this.prompts,
    required this.onPromptsChanged,
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

  @override
  Widget build(BuildContext context) {
    final l10n = OpenAILocalizations.of(context);
    return Column(
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
                          value: prompt.type,
                          decoration: InputDecoration(
                            labelText: l10n.promptTypeLabel,
                            border: const OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'system',
                              child: Text(l10n.systemRole),
                            ),
                            DropdownMenuItem(
                              value: 'user',
                              child: Text(l10n.userRole),
                            ),
                            DropdownMenuItem(
                              value: 'assistant',
                              child: Text(l10n.assistantRole),
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
                  TextFormField(
                    initialValue: prompt.content,
                    decoration: InputDecoration(
                      labelText: l10n.contentLabel,
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) => _updatePromptContent(index, value),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addPrompt,
          icon: const Icon(Icons.add),
          label: Text(l10n.addPrompt),
        ),
      ],
    );
  }
}
