import 'package:flutter/material.dart';
import '../models/calendar_entry.dart';
import '../l10n/calendar_album_localizations.dart';

class EntryList extends StatelessWidget {
  final List<CalendarEntry> entries;
  final Function(CalendarEntry) onTap;
  final Function(CalendarEntry) onEdit;
  final Function(CalendarEntry) onDelete;

  const EntryList({
    Key? key,
    required this.entries,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = CalendarAlbumLocalizations.of(context);

    if (entries.isEmpty) {
      return Center(
        child: Text(l10n.get('noEntries')),
      );
    }

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: InkWell(
            onTap: () => onTap(entry),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => onEdit(entry),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => onDelete(entry),
                      ),
                    ],
                  ),
                  if (entry.content.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      entry.content.length > 100
                          ? '${entry.content.substring(0, 100)}...'
                          : entry.content,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                  if (entry.tags.isNotEmpty ||
                      entry.location != null ||
                      entry.mood != null ||
                      entry.weather != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (entry.location != null)
                          Chip(
                            avatar: const Icon(Icons.location_on, size: 16),
                            label: Text(entry.location!),
                          ),
                        if (entry.mood != null)
                          Chip(
                            avatar: const Icon(Icons.mood, size: 16),
                            label: Text(entry.mood!),
                          ),
                        if (entry.weather != null)
                          Chip(
                            avatar: const Icon(Icons.cloud, size: 16),
                            label: Text(entry.weather!),
                          ),
                        ...entry.tags.map(
                          (tag) => Chip(
                            avatar: const Icon(Icons.label, size: 16),
                            label: Text(tag),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (entry.imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: entry.imageUrls.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Image.network(
                              entry.imageUrls[index],
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}