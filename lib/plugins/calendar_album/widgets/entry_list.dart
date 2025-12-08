import 'package:flutter/material.dart';
import 'dart:io';
import 'package:Memento/plugins/calendar_album/models/calendar_entry.dart';
import 'package:Memento/plugins/calendar_album/l10n/calendar_album_localizations.dart';
import 'package:Memento/utils/image_utils.dart';

class EntryList extends StatelessWidget {
  Widget _buildDefaultCover() {
    return Container(
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
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading network image: $error');
            return _buildDefaultCover();
          },
        ),
      );
    }

    return FutureBuilder<String>(
      future: ImageUtils.getAbsolutePath(url),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final file = File(snapshot.data!);
          if (file.existsSync()) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error loading local image: $error');
                  return _buildDefaultCover();
                },
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
  final VoidCallback? onCreateNew;

  const EntryList({
    super.key,
    required this.entries,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = CalendarAlbumLocalizations.of(context);

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.noEntries,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (onCreateNew != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onCreateNew,
                icon: const Icon(Icons.add),
                label: const Text('新建日记'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: InkWell(
            onTap: () => onTap(entry),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
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
                          if (entry.mood != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.purple[100]!,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.mood,
                                      size: 12,
                                      color: Colors.purple,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      entry.mood!,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.purple[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (entry.weather != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.cyan[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.cyan[100]!,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.cloud,
                                      size: 12,
                                      color: Colors.cyan,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      entry.weather!,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.cyan[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (entry.imageUrls.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1.2,
                              ),
                          itemCount: entry.imageUrls.length,
                          itemBuilder: (context, index) {
                            return _buildImage(entry.imageUrls[index]);
                          },
                        ),
                      ],
                      if (entry.content.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            entry.content,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                      if (entry.tags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...entry.tags.map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green[100]!,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.label,
                                      size: 12,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      tag,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  if (entry.location != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[100]!, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            entry.location!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
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
