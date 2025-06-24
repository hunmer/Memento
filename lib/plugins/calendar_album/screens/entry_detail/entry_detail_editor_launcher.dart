import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/calendar_controller.dart';
import '../../controllers/tag_controller.dart';
import '../../models/calendar_entry.dart';
import '../entry_editor_screen.dart';

class EntryDetailEditorLauncher extends StatelessWidget {
  final CalendarController calendarController;
  final TagController tagController;
  final DateTime? initialDate;
  final CalendarEntry? entry;
  final bool isEditing;

  const EntryDetailEditorLauncher({
    super.key,
    required this.calendarController,
    required this.tagController,
    this.initialDate,
    this.entry,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CalendarController>.value(
          value: calendarController,
        ),
        ChangeNotifierProvider<TagController>.value(value: tagController),
      ],
      child: EntryEditorScreen(
        initialDate: initialDate,
        entry: entry,
        isEditing: isEditing,
      ),
    );
  }
}
