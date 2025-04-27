import 'package:flutter/material.dart';
import '../../l10n/day_localizations.dart';

class NotesTab extends StatelessWidget {
  final List<String> notes;
  final Function() onAddNote;
  final Function(int, String) onNoteChanged;
  final Function(int) onNoteRemoved;

  const NotesTab({
    super.key,
    required this.notes,
    required this.onAddNote,
    required this.onNoteChanged,
    required this.onNoteRemoved,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = DayLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: ListView(children: [..._buildNotesList(context)])),
        TextButton.icon(
          onPressed: onAddNote,
          icon: const Icon(Icons.add),
          label: Text(localizations.addNote),
        ),
      ],
    );
  }

  List<Widget> _buildNotesList(BuildContext context) {
    return notes.asMap().entries.map((entry) {
      final index = entry.key;
      final note = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: DayLocalizations.of(context).enterNote,
                ),
                controller: TextEditingController(text: note),
                onChanged: (value) => onNoteChanged(index, value),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => onNoteRemoved(index),
            ),
          ],
        ),
      );
    }).toList();
  }
}
