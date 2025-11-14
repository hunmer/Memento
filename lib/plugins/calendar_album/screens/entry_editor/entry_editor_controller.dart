import 'package:Memento/plugins/chat/l10n/chat_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/calendar_controller.dart';
import '../../models/calendar_entry.dart';

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
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ChatLocalizations.of(context).titleCannotBeEmpty),
        ),
      );
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
