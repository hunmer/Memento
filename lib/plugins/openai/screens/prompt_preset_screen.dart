import 'package:flutter/material.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import '../l10n/openai_localizations.dart';
import '../models/prompt_preset.dart';
import '../services/prompt_preset_service.dart';

class PromptPresetScreen extends StatelessWidget {
  const PromptPresetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = PromptPresetService();

    // 确保预设已加载
    if (service.presets.isEmpty) {
      service.loadPresets();
    }

    return SuperCupertinoNavigationWrapper(
      title: Text(OpenAILocalizations.of(context).promptPresetManagement),
      largeTitle: OpenAILocalizations.of(context).promptPresetManagement,
      enableLargeTitle: false,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () async {
            final result = await showDialog<PromptPreset>(
              context: context,
              builder: (context) => const _PresetEditDialog(),
            );

            if (result != null) {
              await service.addPreset(result);
            }
          },
        ),
      ],
      body: AnimatedBuilder(
        animation: service,
        builder: (context, _) {
          if (service.presets.isEmpty) {
            final l10n = OpenAILocalizations.of(context);
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.text_snippet_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noPresetsYet,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.createFirstPreset,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await showDialog<PromptPreset>(
                        context: context,
                        builder: (context) => const _PresetEditDialog(),
                      );

                      if (result != null) {
                        await service.addPreset(result);
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addPreset),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: service.presets.length,
            itemBuilder: (context, index) {
              final preset = service.presets[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    preset.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (preset.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            preset.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (preset.tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: preset.tags
                                .map(
                                  (tag) => Chip(
                                    label: Text(
                                      tag,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final result = await showDialog<PromptPreset>(
                          context: context,
                          builder: (context) => _PresetEditDialog(preset: preset),
                        );

                        if (result != null) {
                          await service.updatePreset(result);
                        }
                      } else if (value == 'delete') {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(OpenAILocalizations.of(context).deletePreset),
                            content: Text(OpenAILocalizations.of(context).confirmDeletePreset),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: Text(OpenAILocalizations.of(context).cancel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: Text(
                                  OpenAILocalizations.of(context).delete,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          await service.deletePreset(preset.id);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 20),
                            const SizedBox(width: 8),
                            Text(OpenAILocalizations.of(context).editPreset),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, size: 20, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              OpenAILocalizations.of(context).deletePreset,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    final result = await showDialog<PromptPreset>(
                      context: context,
                      builder: (context) => _PresetEditDialog(preset: preset),
                    );

                    if (result != null) {
                      await service.updatePreset(result);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PresetEditDialog extends StatefulWidget {
  final PromptPreset? preset;

  const _PresetEditDialog({this.preset});

  @override
  State<_PresetEditDialog> createState() => _PresetEditDialogState();
}

class _PresetEditDialogState extends State<_PresetEditDialog> {
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

  void _save() {
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

    Navigator.of(context).pop(preset);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = OpenAILocalizations.of(context);
    final isEditing = widget.preset != null;

    return AlertDialog(
      title: Text(isEditing ? l10n.editPreset : l10n.addPreset),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.presetTitle,
                    hintText: l10n.pleaseEnterTitle,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.pleaseEnterTitle;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: l10n.presetDescription,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    labelText: l10n.promptContent,
                    hintText: l10n.enterSystemPrompt,
                  ),
                  maxLines: 8,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.pleaseEnterSystemPrompt;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tagController,
                        decoration: InputDecoration(
                          labelText: l10n.presetTags,
                          hintText: l10n.enterTagName,
                        ),
                        onFieldSubmitted: (_) => _addTag(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addTag,
                    ),
                  ],
                ),
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _tags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            onDeleted: () => _removeTag(tag),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }
}
