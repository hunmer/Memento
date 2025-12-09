import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:Memento/widgets/location_picker.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'calendar_album_edit'.tr : 'calendar_album_newEntry'.tr),
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
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
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
          _buildTitleField(),
          const SizedBox(height: 16),
          _buildContentField(),
          const SizedBox(height: 16),
          _buildWordCount(),
          const SizedBox(height: 16),
          EntryEditorTagHandler(controller: controller),
          const SizedBox(height: 16),
          _buildLocationField(),
          const SizedBox(height: 16),
          _buildMoodAndWeatherRow(),
        ],
      ),
    );
  }

  // 其他UI组件方法...
  Widget _buildTitleField() {
    return TextField(
      controller: controller.titleController,
      decoration: InputDecoration(
        labelText: 'calendar_album_title'.tr,
        border: const OutlineInputBorder(),
      ),
      maxLines: 1,
    );
  }

  Widget _buildContentField() {
    return TextField(
      controller: controller.contentController,
      decoration: InputDecoration(
        labelText: 'calendar_album_content'.tr,
        border: const OutlineInputBorder(),
      ),
      maxLines: 10,
    );
  }

  Widget _buildWordCount() {
    return Text(
      '${'calendar_album_wordCount'.tr}: ${controller.contentController.text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length}',
      style: const TextStyle(color: Colors.grey),
    );
  }

  Widget _buildLocationField() {
    return TextField(
      controller: controller.locationController,
      decoration: InputDecoration(
        labelText: 'calendar_album_location'.tr,
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

  Widget _buildMoodAndWeatherRow() {
    return Row(
      children: [
        _buildMoodDropdown(),
        const SizedBox(width: 16),
        _buildWeatherDropdown(),
      ],
    );
  }

  Widget _buildMoodDropdown() {
    return Expanded(
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'calendar_album_mood'.tr,
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

  Widget _buildWeatherDropdown() {
    return Expanded(
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'calendar_album_weather'.tr,
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
