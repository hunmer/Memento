import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:Memento/widgets/location_picker.dart';
import 'package:Memento/plugins/calendar_album/l10n/calendar_album_localizations.dart';
import 'entry_editor_controller.dart';
import 'entry_editor_image_handler.dart';
import 'entry_editor_tag_handler.dart';

class EntryEditorUI extends StatefulWidget {
  final EntryEditorController controller;
  final bool isEditing;
  final BuildContext parentContext;

  const EntryEditorUI({
    super.key,
    required this.controller,
    required this.isEditing,
    required this.parentContext,
  });

  @override
  State<EntryEditorUI> createState() => _EntryEditorUIState();
}

class _EntryEditorUIState extends State<EntryEditorUI> {
  late EntryEditorController controller;
  late bool isEditing;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    isEditing = widget.isEditing;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CalendarAlbumLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.edit : l10n.newEntry),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final result = controller.saveEntry(context);
              if (result != null && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: _buildBody(context, l10n),
    );
  }

  Widget _buildBody(BuildContext context, CalendarAlbumLocalizations l10n) {
    if (controller.isPreview) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(controller.contentController.text),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EntryEditorImageHandler(
            imageUrls: controller.imageUrls,
            thumbUrls: controller.thumbUrls,
            onImageAdded: (url, thumbUrl) {
              controller.imageUrls.add(url);
              controller.thumbUrls.add(thumbUrl ?? '');
            },
            onImageRemoved: (index) {
              controller.imageUrls.removeAt(index);
              if (index < controller.thumbUrls.length) {
                controller.thumbUrls.removeAt(index);
              }
            },
          ),
          const SizedBox(height: 16),
          _buildTitleField(l10n),
          const SizedBox(height: 16),
          _buildContentField(l10n),
          const SizedBox(height: 16),
          _buildWordCount(l10n),
          const SizedBox(height: 16),
          EntryEditorTagHandler(controller: controller, l10n: l10n),
          const SizedBox(height: 16),
          _buildLocationField(l10n),
          const SizedBox(height: 16),
          _buildMoodAndWeatherRow(l10n),
        ],
      ),
    );
  }

  // 其他UI组件方法...
  Widget _buildTitleField(CalendarAlbumLocalizations l10n) {
    return TextField(
      controller: controller.titleController,
      decoration: InputDecoration(
        labelText: l10n.title,
        border: const OutlineInputBorder(),
      ),
      maxLines: 1,
    );
  }

  Widget _buildContentField(CalendarAlbumLocalizations l10n) {
    return TextField(
      controller: controller.contentController,
      decoration: InputDecoration(
        labelText: l10n.content,
        border: const OutlineInputBorder(),
      ),
      maxLines: 10,
    );
  }

  Widget _buildWordCount(CalendarAlbumLocalizations l10n) {
    return Text(
      '${l10n.wordCount}: ${controller.contentController.text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length}',
      style: const TextStyle(color: Colors.grey),
    );
  }

  Widget _buildLocationField(CalendarAlbumLocalizations l10n) {
    return TextField(
      controller: controller.locationController,
      decoration: InputDecoration(
        labelText: l10n.location,
        border: const OutlineInputBorder(),
        prefixIcon: IconButton(
          icon: const Icon(Icons.location_on),
          onPressed: () {
            if (mounted) {
              _handleLocationSelection(widget.parentContext);
            }
          },
        ),
      ),
      maxLines: 1,
    );
  }

  Future<void> _handleLocationSelection(BuildContext dialogContext) async {
    final isMobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    await showDialog(
      context: dialogContext,
      builder:
          (BuildContext context) => LocationPicker(
            onLocationSelected: (location) {
              if (mounted) {
                setState(() {
                  controller.locationController.text = location;
                });
              }
            },
            isMobile: isMobile,
          ),
    );
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
          labelText: l10n.mood,
          border: const OutlineInputBorder(),
        ),
        initialValue: controller.mood,
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
          labelText: l10n.weather,
          border: const OutlineInputBorder(),
        ),
        initialValue: controller.weather,
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
