import 'package:flutter/material.dart';
import 'dart:io';
import '../models/calendar_entry.dart';
import '../l10n/calendar_album_localizations.dart';
import '../../../utils/image_utils.dart';

class EntryList extends StatelessWidget {
  Widget _buildDefaultCover() {
    return Container(
      height: 80,
      width: 80,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  Widget _buildImage(String url) {
    if (url.isEmpty) {
      return _buildDefaultCover();
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return SizedBox(
        height: 80,
        width: 80,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading network image: $error');
              return _buildDefaultCover();
            },
          ),
        ),
      );
    }

    return FutureBuilder<String>(
      future: ImageUtils.getAbsolutePath(url),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final file = File(snapshot.data!);
          if (file.existsSync()) {
            return SizedBox(
              height: 80,
              width: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  file,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Error loading local image: $error');
                    return _buildDefaultCover();
                  },
                ),
              ),
            );
          }
        }
        return _buildDefaultCover();
      },
    );
  }

  final List<CalendarEntry> entries;
  final Function(CalendarEntry) onTap;
  final Function(CalendarEntry) onEdit;
  final Function(CalendarEntry) onDelete;

  const EntryList({
    super.key,
    required this.entries,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = CalendarAlbumLocalizations.of(context);

    if (entries.isEmpty) {
      return Center(child: Text(l10n.get('noEntries')));
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
                            child: _buildImage(entry.imageUrls[index]),
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
