import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import '../../controllers/tag_controller.dart';
import '../../l10n/calendar_album_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'entry_editor_controller.dart';
import 'entry_editor_image_handler.dart';
import 'entry_editor_tag_handler.dart';

class EntryEditorUI extends StatelessWidget {
  final EntryEditorController controller;
  final bool isEditing;

  const EntryEditorUI({
    super.key,
    required this.controller,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = CalendarAlbumLocalizations.of(context);
    final tagController = Provider.of<TagController>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.get('edit') : l10n.get('newEntry')),
        actions: [
          IconButton(
            icon: Icon(controller.isPreview ? Icons.edit : Icons.preview),
            onPressed: () => controller.isPreview = !controller.isPreview,
            tooltip:
                controller.isPreview ? l10n.get('edit') : l10n.get('preview'),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              final result = controller.saveEntry(context);
              if (result != null) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: _buildBody(context, l10n, tagController),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CalendarAlbumLocalizations l10n,
    TagController tagController,
  ) {
    if (controller.isPreview) {
      return Markdown(
        data: controller.contentController.text,
        selectable: true,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleField(l10n),
          const SizedBox(height: 16),
          _buildContentField(l10n),
          const SizedBox(height: 16),
          _buildWordCount(l10n),
          const SizedBox(height: 16),
          _buildLocationField(l10n),
          const SizedBox(height: 16),
          _buildMoodAndWeatherRow(l10n),
          const SizedBox(height: 16),
          EntryEditorTagHandler(
            controller: controller,
            tagController: tagController,
            l10n: l10n,
          ),
          const SizedBox(height: 16),
          EntryEditorImageHandler(
            imageUrls: controller.imageUrls,
            onImageAdded: (url) => controller.imageUrls.add(url),
            onImageRemoved: (url) => controller.imageUrls.remove(url),
          ),
        ],
      ),
    );
  }

  // 其他UI组件方法...
  Widget _buildTitleField(CalendarAlbumLocalizations l10n) {
    return TextField(
      controller: controller.titleController,
      decoration: InputDecoration(
        labelText: l10n.get('title'),
        border: const OutlineInputBorder(),
      ),
      maxLines: 1,
    );
  }

  Widget _buildContentField(CalendarAlbumLocalizations l10n) {
    return TextField(
      controller: controller.contentController,
      decoration: InputDecoration(
        labelText: l10n.get('content'),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            final currentContext = context;
            _showMarkdownHelp(currentContext as BuildContext, l10n);
          },
        ),
      ),
      maxLines: 10,
    );
  }

  void _showMarkdownHelp(
    BuildContext context,
    CalendarAlbumLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Markdown Help'),
            content: const SingleChildScrollView(
              child: Text(
                '# Heading 1\n## Heading 2\n**Bold**\n*Italic*\n- List item\n1. Numbered item\n[Link](url)\n![Image](url)',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.get('close')),
              ),
            ],
          ),
    );
  }

  Widget _buildWordCount(CalendarAlbumLocalizations l10n) {
    return Text(
      '${l10n.get('wordCount')}: ${controller.contentController.text.trim().split(RegExp(r'\\s+')).where((word) => word.isNotEmpty).length}',
      style: const TextStyle(color: Colors.grey),
    );
  }

  Widget _buildLocationField(CalendarAlbumLocalizations l10n) {
    return TextField(
      controller: controller.locationController,
      decoration: InputDecoration(
        labelText: l10n.get('location'),
        border: const OutlineInputBorder(),
        prefixIcon: IconButton(
          icon: const Icon(Icons.location_on),
          onPressed: () {
            final currentContext = context;
            _handleLocationSelection(currentContext as BuildContext);
          },
        ),
      ),
      maxLines: 1,
    );
  }

  Future<void> _handleLocationSelection(BuildContext context) async {
    // 位置选择逻辑...
  }

  Widget _buildMoodAndWeatherRow(CalendarAlbumLocalizations l10n) {
    return Row(
      children: [
        _buildMoodDropdown(l10n),
        const SizedBox(width: 16),
        _buildWeatherDropdown(l10n),
      ],
    );
  }

  Widget _buildMoodDropdown(CalendarAlbumLocalizations l10n) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: l10n.get('mood'),
          border: const OutlineInputBorder(),
        ),
        value: controller.mood,
        items:
            [
                  'Happy',
                  'Sad',
                  'Excited',
                  'Tired',
                  'Calm',
                  'Anxious',
                  'Angry',
                  'Content',
                ]
                .map(
                  (value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ),
                )
                .toList(),
        onChanged: (value) => controller.mood = value,
      ),
    );
  }

  Widget _buildWeatherDropdown(CalendarAlbumLocalizations l10n) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: l10n.get('weather'),
          border: const OutlineInputBorder(),
        ),
        value: controller.weather,
        items:
            [
                  'Sunny',
                  'Cloudy',
                  'Rainy',
                  'Snowy',
                  'Windy',
                  'Foggy',
                  'Stormy',
                  'Clear',
                ]
                .map(
                  (value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ),
                )
                .toList(),
        onChanged: (value) => controller.weather = value,
      ),
    );
  }
}
