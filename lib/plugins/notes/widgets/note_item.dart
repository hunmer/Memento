import 'package:flutter/material.dart';
import '../models/note.dart';

class NoteItem extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const NoteItem({super.key, required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(note.title),
      subtitle:
          note.tags.isNotEmpty
              ? Wrap(
                spacing: 4,
                children:
                    note.tags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
              )
              : Text(
                note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
      onTap: onTap,
    );
  }
}
