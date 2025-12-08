import 'package:flutter/material.dart';
import 'package:Memento/plugins/notes/models/note.dart';
import 'package:Memento/plugins/notes/utils/text_highlight.dart';

class SearchNoteItem extends StatelessWidget {
  final Note note;
  final String folderName;
  final String query;

  const SearchNoteItem({
    super.key,
    required this.note,
    required this.folderName,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextHighlight.highlightText(
                note.title,
                query,
                baseStyle: Theme.of(context).textTheme.titleMedium,
                highlightStyle: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (note.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: note.tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 8),
            RichText(
              text: TextHighlight.highlightText(
                note.content,
                query,
                baseStyle: Theme.of(context).textTheme.bodyMedium,
                highlightStyle: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: Chip(
                avatar: const Icon(Icons.folder, size: 16),
                label: Text(folderName),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}