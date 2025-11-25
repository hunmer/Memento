import 'package:flutter/material.dart';
import '../l10n/openai_localizations.dart';
import '../models/prompt_preset.dart';
import '../services/prompt_preset_service.dart';

class PromptPresetScreen extends StatefulWidget {
  const PromptPresetScreen({super.key});

  @override
  State<PromptPresetScreen> createState() => _PromptPresetScreenState();
}

class _PromptPresetScreenState extends State<PromptPresetScreen> {
  final PromptPresetService _service = PromptPresetService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    setState(() => _isLoading = true);
    await _service.loadPresets();
    setState(() => _isLoading = false);
  }

  Future<void> _showEditDialog({PromptPreset? preset}) async {
    final result = await showDialog<PromptPreset>(
      context: context,
      builder: (context) => _PresetEditDialog(preset: preset),
    );

    if (result != null) {
      if (preset == null) {
        await _service.addPreset(result);
      } else {
        await _service.updatePreset(result);
      }
      setState(() {});
    }
  }

  Future<void> _deletePreset(PromptPreset preset) async {
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
      await _service.deletePreset(preset.id);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = OpenAILocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.promptPresetManagement),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _service.presets.isEmpty
              ? Center(
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
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _service.presets.length,
                  itemBuilder: (context, index) {
                    final preset = _service.presets[index];
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
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditDialog(preset: preset);
                            } else if (value == 'delete') {
                              _deletePreset(preset);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit, size: 20),
                                  const SizedBox(width: 8),
                                  Text(l10n.editPreset),
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
                                    l10n.deletePreset,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _showEditDialog(preset: preset),
                      ),
                    );
                  },
                ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => _showEditDialog(),
      //   child: const Icon(Icons.add),
      // ),
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
