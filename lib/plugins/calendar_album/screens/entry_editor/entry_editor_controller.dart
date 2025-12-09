import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:Memento/plugins/calendar_album/controllers/calendar_controller.dart';
import 'package:Memento/plugins/calendar_album/models/calendar_entry.dart';
import 'package:Memento/core/services/toast_service.dart';

class EntryEditorController {
  final CalendarEntry? entry;
  final bool isEditing;
  final DateTime? initialDate;

  late TextEditingController titleController;
  late TextEditingController contentController;
  late TextEditingController locationController;
  String? mood;
  String? weather;
  List<String> selectedTags = [];
  List<String> imageUrls = [];
  List<String> thumbUrls = [];
  bool isPreview = false;

  EntryEditorController({
    this.entry,
    required this.isEditing,
    this.initialDate,
  }) {
    titleController = TextEditingController(text: entry?.title ?? '');
    contentController = TextEditingController(text: entry?.content ?? '');
    locationController = TextEditingController(text: entry?.location ?? '');
    mood = entry?.mood;
    weather = entry?.weather;
    imageUrls = entry?.imageUrls.toList() ?? [];
    thumbUrls = entry?.thumbUrls.toList() ?? [];
  }

  void dispose() {
    titleController.dispose();
    contentController.dispose();
    locationController.dispose();
  }

  CalendarEntry? saveEntry(BuildContext context) {
    final calendarController = Provider.of<CalendarController>(
      context,
      listen: false,
    );
    // 如果标题为空且没有图片,则提示错误
    if (titleController.text.isEmpty && imageUrls.isEmpty) {
      toastService.showToast(ChatLocalizations.of(context).titleCannotBeEmpty);
      return null;
    }

    if (isEditing && entry != null) {
      final updatedEntry = entry!.copyWith(
        title: titleController.text,
        content: contentController.text,
        tags: selectedTags.toList(),
        location:
            locationController.text.isEmpty ? null : locationController.text,
        mood: mood,
        weather: weather,
        imageUrls: imageUrls,
        thumbUrls: thumbUrls,
      );
      calendarController.updateEntry(updatedEntry);
      return updatedEntry;
    } else {
      final newEntry = CalendarEntry.create(
        title: titleController.text,
        content: contentController.text,
        tags: selectedTags.toList(),
        location:
            locationController.text.isEmpty ? null : locationController.text,
        mood: mood,
        weather: weather,
        imageUrls: imageUrls,
        thumbUrls: thumbUrls,
        createdAt: initialDate ?? DateTime.now(),
      );
      calendarController.addEntry(newEntry);
      return newEntry;
    }
  }
}
